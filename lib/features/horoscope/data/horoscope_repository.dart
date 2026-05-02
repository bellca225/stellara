// lib/features/horoscope/data/horoscope_repository.dart

import 'package:flutter/foundation.dart';

import '../../../core/env/env.dart';
import '../../astrology/data/prokerala_api.dart';
import '../domain/horoscope.dart';
import '../fixtures/horoscope_fixture.dart';

class HoroscopeRepository {
  HoroscopeRepository(this._api);
  final ProkeralaApi _api;

  Future<Horoscope> getDaily({required String signSlug, DateTime? date}) async {
    if (kDebugMode && Env.useFixtureInDebug) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return demoHoroscope(signSlug, date);
    }
    try {
      final json = await _api.fetchDailyHoroscope(signSlug: signSlug, date: date);
      return _parse(json, signSlug, date);
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
