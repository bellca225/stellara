import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/cache/disk_cache.dart';
import '../../../core/utils/astro_text.dart';
import '../../astrology/domain/birth_info.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../content/data/ai_question_repository.dart';
import '../domain/horoscope.dart';
import '../fixtures/horoscope_fixture.dart';
import 'daily_fortune_repository.dart';

class HoroscopeRepository {
  HoroscopeRepository(
    this._cache,
    this._firestoreCache,
    this._aiRepository, {
    String? uid,
    String? chartVersion,
    String? utcOffset,
  }) : _currentUid = uid,
       _activeChartVersion = chartVersion,
       _utcOffset = utcOffset;

  final DiskCache _cache;
  final DailyFortuneRepository _firestoreCache;
  final AiQuestionRepository _aiRepository;
  final String? _currentUid;
  final String? _activeChartVersion;
  final String? _utcOffset;

  Future<Horoscope> getDaily({
    required String signSlug,
    required BirthInfo birthInfo,
    required NatalChart chart,
    required String nickname,
    DateTime? date,
  }) async {
    final keyDate = _resolveTargetDate(date, birthInfo.utcOffset);
    final cacheKey = _cacheKey(signSlug, keyDate);

    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      try {
        return Horoscope.fromJson(cached);
      } catch (e) {
        if (kDebugMode) {
          print('[HoroscopeRepository] L2 디코드 실패 → L3 fallback: $e');
        }
      }
    }

    final currentUid = _currentUid;
    if (currentUid != null) {
      final firestoreHoroscope = await _firestoreCache.get(
        uid: currentUid,
        signSlug: signSlug,
        date: keyDate,
        chartVersion: _activeChartVersion ?? birthInfo.chartVersion,
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
      final payload = await _aiRepository.generateDailyHoroscope(
        nickname: nickname,
        chart: chart,
        targetDate: keyDate,
        timezone: birthInfo.utcOffset,
        placeName: birthInfo.placeName,
      );
      final horoscope = Horoscope(
        signSlug: signSlug,
        signName: _displaySignName(signSlug),
        date: keyDate,
        summary: payload.overall,
        luckyColor: payload.luckyColor,
        luckyNumbers: _normalizeLuckyNumbers(
          payload.luckyNumbers,
          chart,
          keyDate,
        ),
        mood: payload.emotion,
        luckyPlace: payload.luckyPlace,
        advice: payload.advice,
        caution: payload.caution,
        shareText: payload.shareText,
        promptVersion: payload.promptVersion,
        chartVersion: _activeChartVersion ?? birthInfo.chartVersion,
        utcOffset: birthInfo.utcOffset,
      );
      await _cache.putJson(cacheKey, horoscope.toJson(), source: 'remote-ai');
      if (currentUid != null) {
        await _firestoreCache.save(
          uid: currentUid,
          horoscope: horoscope,
          source: 'remote-ai',
          chartVersion: _activeChartVersion ?? birthInfo.chartVersion,
          utcOffset: birthInfo.utcOffset,
          birthSnapshot: _birthSnapshot(birthInfo),
          analysisSnapshot: _analysisSnapshot(chart, birthInfo.chartVersion),
        );
      }
      return horoscope;
    } catch (e, st) {
      if (kDebugMode) {
        print('[HoroscopeRepository] AI daily 실패 → local fallback: $e\n$st');
      }
      final fallback = _buildLocalFallback(
        signSlug: signSlug,
        chart: chart,
        date: keyDate,
        nickname: nickname,
        birthInfo: birthInfo,
      );
      await _cache.putJson(
        cacheKey,
        fallback.toJson(),
        source: 'local-derived',
      );
      if (currentUid != null) {
        await _firestoreCache.save(
          uid: currentUid,
          horoscope: fallback,
          source: 'local-derived',
          chartVersion: _activeChartVersion ?? birthInfo.chartVersion,
          utcOffset: birthInfo.utcOffset,
          birthSnapshot: _birthSnapshot(birthInfo),
          analysisSnapshot: _analysisSnapshot(chart, birthInfo.chartVersion),
        );
      }
      return fallback;
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

  DateTime _resolveTargetDate(DateTime? explicitDate, String birthUtcOffset) {
    if (explicitDate != null) {
      return DateTime(explicitDate.year, explicitDate.month, explicitDate.day);
    }
    final offset = _parseUtcOffset(_utcOffset ?? birthUtcOffset);
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

  List<int> _normalizeLuckyNumbers(
    List<int> values,
    NatalChart chart,
    DateTime date,
  ) {
    final cleaned = values
        .where((value) => value > 0)
        .map((value) => ((value - 1) % 99) + 1)
        .toSet()
        .toList();
    if (cleaned.length >= 3) {
      return cleaned.take(3).toList();
    }

    final seed =
        chart.sunSign.hashCode ^
        chart.moonSign.hashCode ^
        chart.ascendantSign.hashCode ^
        date.year ^
        date.month ^
        date.day;
    final rng = Random(seed);
    while (cleaned.length < 3) {
      final candidate = rng.nextInt(49) + 1;
      if (!cleaned.contains(candidate)) {
        cleaned.add(candidate);
      }
    }
    cleaned.sort();
    return cleaned;
  }

  String _displaySignName(String signSlug) {
    if (signSlug.trim().isEmpty) return '-';
    final normalized = signSlug.trim().toLowerCase();
    final ko = zodiacNameKo(normalized);
    return ko == normalized
        ? '${normalized[0].toUpperCase()}${normalized.substring(1)}'
        : ko;
  }

  Map<String, dynamic> _birthSnapshot(BirthInfo birthInfo) => {
        'date': birthInfo.dateTime.toIso8601String().split('T').first,
        'time':
            '${birthInfo.dateTime.hour.toString().padLeft(2, '0')}:${birthInfo.dateTime.minute.toString().padLeft(2, '0')}',
        'placeName': birthInfo.placeName,
        'latitude': birthInfo.latitude,
        'longitude': birthInfo.longitude,
        'utcOffset': birthInfo.utcOffset,
      };

  Map<String, dynamic> _analysisSnapshot(
    NatalChart chart,
    String chartVersion,
  ) {
    String? signOf(String planetName) {
      for (final planet in chart.planets) {
        if (planet.name.toLowerCase() == planetName.toLowerCase()) {
          return planet.sign;
        }
      }
      return null;
    }

    return {
      'chartVersion': chartVersion,
      'sunSign': chart.sunSign,
      'moonSign': chart.moonSign,
      'ascendantSign': chart.ascendantSign,
      'mercurySign': signOf('Mercury'),
      'venusSign': signOf('Venus'),
      'marsSign': signOf('Mars'),
    };
  }

  Horoscope _buildLocalFallback({
    required String signSlug,
    required NatalChart chart,
    required DateTime date,
    required String nickname,
    required BirthInfo birthInfo,
  }) {
    final demo = demoHoroscope(signSlug, date);
    final sun = zodiacNameKo(chart.sunSign.toLowerCase());
    final moon = zodiacNameKo(chart.moonSign.toLowerCase());
    final asc = zodiacNameKo(chart.ascendantSign.toLowerCase());
    final mercury = _planetSign(chart, 'Mercury');
    final luckyNumbers = _normalizeLuckyNumbers(demo.luckyNumbers, chart, date);

    return Horoscope(
      signSlug: signSlug,
      signName: _displaySignName(signSlug),
      date: date,
      summary:
          '$nickname님은 오늘 $sun의 중심을 잃지 않으면서도, $moon 감정을 급하게 밀어붙이지 않는 편이 좋아요. '
          '${mercury == null ? '$asc 분위기를 믿고 익숙한 리듬으로 가면 흐름이 안정됩니다.' : '${zodiacNameKo(mercury.toLowerCase())}식 대화 감각이 특히 잘 먹히는 날이에요.'}',
      luckyColor: _localLuckyColor(chart),
      luckyNumbers: luckyNumbers,
      mood: '$moon 쪽 감정이 은근히 도드라지는 날',
      luckyPlace: _localLuckyPlace(chart),
      advice: '결론을 서두르기보다, 반응을 한 번 더 보고 움직이세요.',
      caution: '감정이 올라올 때 바로 단정하면 작은 오해가 커질 수 있어요.',
      shareText: '$sun 리듬을 살리면 생각보다 운이 부드럽게 붙는 하루예요.',
      promptVersion: 'local-derived',
      chartVersion: _activeChartVersion ?? birthInfo.chartVersion,
      utcOffset: birthInfo.utcOffset,
    );
  }

  String _localLuckyColor(NatalChart chart) {
    switch (chart.sunSign.trim().toLowerCase()) {
      case 'aries':
      case 'leo':
      case 'sagittarius':
        return '주황색';
      case 'taurus':
      case 'virgo':
      case 'capricorn':
        return '초록색';
      case 'gemini':
      case 'libra':
      case 'aquarius':
        return '파란색';
      case 'cancer':
      case 'scorpio':
      case 'pisces':
        return '보라색';
      default:
        return '남색';
    }
  }

  String _localLuckyPlace(NatalChart chart) {
    switch (chart.moonSign.trim().toLowerCase()) {
      case 'gemini':
      case 'libra':
      case 'aquarius':
        return '카페, 서점';
      case 'aries':
      case 'leo':
      case 'sagittarius':
        return '야외 산책로, 전시 공간';
      case 'taurus':
      case 'virgo':
      case 'capricorn':
        return '조용한 작업 공간, 도서관';
      case 'cancer':
      case 'scorpio':
      case 'pisces':
        return '물가 근처, 집 근처 단골 공간';
      default:
        return '익숙한 장소';
    }
  }

  String? _planetSign(NatalChart chart, String planetName) {
    for (final planet in chart.planets) {
      if (planet.name.toLowerCase() == planetName.toLowerCase()) {
        return planet.sign;
      }
    }
    return null;
  }
}
