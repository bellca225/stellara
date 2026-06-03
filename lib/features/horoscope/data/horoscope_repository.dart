// lib/features/horoscope/data/horoscope_repository.dart

import 'package:flutter/foundation.dart';

import '../../../core/cache/disk_cache.dart';
import '../../../core/env/env.dart';
import '../../astrology/data/prokerala_api.dart';
import '../domain/horoscope.dart';
import 'daily_fortune_repository.dart';
import '../fixtures/horoscope_fixture.dart';

class HoroscopeRepository {
  HoroscopeRepository(
    this._api,
    this._cache,
    this._firestoreCache, {
    String? uid,
    String? chartVersion,
    String? utcOffset,
  }) : _currentUid = uid,
       _activeChartVersion = chartVersion,
       _utcOffset = utcOffset;
  final ProkeralaApi _api;
  final DiskCache _cache;
  final DailyFortuneRepository _firestoreCache;
  final String? _currentUid;
  final String? _activeChartVersion;
  final String? _utcOffset;

  Future<Horoscope> getDaily({required String signSlug, DateTime? date}) async {
    final keyDate = _resolveTargetDate(date);

    // L0: fixture (가장 강한 토큰 절약, 디스크 저장 안 함).
    if (Env.shouldUseFixtureForProkerala) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return demoHoroscope(signSlug, keyDate);
    }

    // L2: 디스크. 키가 sign+yyyyMMdd 라 다른 날짜면 자연 cache miss.
    final cacheKey = _cacheKey(signSlug, keyDate);
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      try {
        return Horoscope.fromJson(cached);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[HoroscopeRepository] L2 디코드 실패 → 실호출 fallback: $e');
        }
      }
    }

    // L3: Firestore. 같은 사용자/별자리/날짜 조합이면 디바이스 간에도 재사용.
    final currentUid = _currentUid;
    if (currentUid != null) {
      final firestoreHoroscope = await _firestoreCache.get(
        uid: currentUid,
        signSlug: signSlug,
        date: keyDate,
        chartVersion: _activeChartVersion,
      );
      if (firestoreHoroscope != null) {
        await _cache.putJson(
          cacheKey,
          firestoreHoroscope.toJson(),
          source: 'firestore',
        );
        return firestoreHoroscope;
      }
    }

    try {
      final json = await _api.fetchDailyHoroscope(
        signSlug: signSlug,
        date: keyDate,
      );
      final horoscope = _parse(json, signSlug, keyDate);
      await _cache.putJson(cacheKey, horoscope.toJson(), source: 'live');
      if (currentUid != null) {
        await _firestoreCache.save(
          uid: currentUid,
          horoscope: horoscope,
          source: 'live',
          chartVersion: _activeChartVersion,
          utcOffset: _utcOffset,
        );
      }
      return horoscope;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[HoroscopeRepository] daily 실패 → fixture: $e');
      }
      return demoHoroscope(signSlug, keyDate);
    }
  }

  String _cacheKey(String signSlug, DateTime date) {
    final uid = _currentUid;
    final chartVersion = _activeChartVersion;
    if (uid != null && chartVersion != null && chartVersion.isNotEmpty) {
      return CacheKeys.dailyForUser(uid, signSlug, chartVersion, date);
    }
    return CacheKeys.daily(signSlug, date);
  }

  DateTime _resolveTargetDate(DateTime? explicitDate) {
    if (explicitDate != null) {
      return DateTime(explicitDate.year, explicitDate.month, explicitDate.day);
    }
    final offset = _parseUtcOffset(_utcOffset);
    if (offset == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final zonedNow = DateTime.now().toUtc().add(offset);
    return DateTime(zonedNow.year, zonedNow.month, zonedNow.day);
  }

  Duration? _parseUtcOffset(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    final hours = int.tryParse(match.group(2) ?? '');
    final minutes = int.tryParse(match.group(3) ?? '');
    if (hours == null || minutes == null) return null;
    return Duration(hours: sign * hours, minutes: sign * minutes);
  }

  Horoscope _parse(Map<String, dynamic> json, String slug, DateTime? date) {
    final data = (json['data'] as Map?) ?? json;
    return Horoscope(
      signSlug: slug,
      signName: (data['sign'] ?? '${slug[0].toUpperCase()}${slug.substring(1)}')
          .toString(),
      date: date ?? DateTime.now(),
      summary:
          (data['horoscope'] ?? data['summary'] ?? data['prediction'] ?? '')
              .toString(),
      luckyColor: (data['lucky_color'] ?? '-').toString(),
      luckyNumber: (data['lucky_number'] is num)
          ? (data['lucky_number'] as num).toInt()
          : 0,
      mood: (data['mood'] ?? '-').toString(),
      luckyPlace: data['lucky_place']?.toString(),
    );
  }
}
