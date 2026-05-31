// lib/features/horoscope/data/horoscope_repository.dart

import 'package:flutter/foundation.dart';

import '../../../core/cache/disk_cache.dart';
import '../../../core/env/env.dart';
import '../../astrology/data/prokerala_api.dart';
import '../domain/horoscope.dart';
import '../fixtures/horoscope_fixture.dart';

class HoroscopeRepository {
  HoroscopeRepository(this._api, this._cache);
  final ProkeralaApi _api;
  final DiskCache _cache;

  Future<Horoscope> getDaily({required String signSlug, DateTime? date}) async {
    // L0: fixture (가장 강한 토큰 절약, 디스크 저장 안 함).
    if (Env.shouldUseFixtureForProkerala) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return demoHoroscope(signSlug, date);
    }

    // L2: 디스크. 키가 sign+yyyyMMdd 라 다른 날짜면 자연 cache miss.
    final keyDate = date ?? DateTime.now();
    final cacheKey = CacheKeys.daily(signSlug, keyDate);
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

    try {
      final json = await _api.fetchDailyHoroscope(signSlug: signSlug, date: date);
      final horoscope = _parse(json, signSlug, date);
      await _cache.putJson(cacheKey, horoscope.toJson(), source: 'live');
      return horoscope;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[HoroscopeRepository] daily 실패 → fixture: $e');
      }
      return demoHoroscope(signSlug, date);
    }
  }

  Horoscope _parse(Map<String, dynamic> json, String slug, DateTime? date) {
    final data = (json['data'] as Map?) ?? json;
    return Horoscope(
      signSlug: slug,
      signName: (data['sign'] ?? '${slug[0].toUpperCase()}${slug.substring(1)}')
          .toString(),
      date: date ?? DateTime.now(),
      summary: (data['horoscope'] ?? data['summary'] ?? data['prediction'] ?? '')
          .toString(),
      luckyColor: (data['lucky_color'] ?? '-').toString(),
      luckyNumber: (data['lucky_number'] is num)
          ? (data['lucky_number'] as num).toInt()
          : 0,
      mood: (data['mood'] ?? '-').toString(),
    );
  }
}
