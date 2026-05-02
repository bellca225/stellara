// lib/features/astrology/data/astrology_repository.dart
//
// 화면이 사용할 NatalChart 를 만드는 책임.
//
// 흐름:
//   화면(Provider) → AstrologyRepository.getNatalChart(BirthInfo)
//     ├─ debug + USE_FIXTURE_IN_DEBUG=true 이면 fixture 반환 (credit 절약)
//     ├─ 그렇지 않으면 ProkeralaApi.fetchNatalChart 호출
//     └─ 응답 JSON → NatalChart 매핑. 매핑 실패 시 fixture 로 graceful fallback
//
// 9주차 핵심 가치: "API 가 죽거나 응답 모양이 다르더라도 화면은 깨지지 않는다."

import 'package:flutter/foundation.dart';

import '../../../core/env/env.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';
import '../fixtures/natal_chart_fixture.dart';
import 'prokerala_api.dart';

class AstrologyRepository {
  AstrologyRepository(this._api);
  final ProkeralaApi _api;

  Future<NatalChart> getNatalChart(BirthInfo birth) async {
    // 디버그 + fixture 사용 옵션이면 네트워크 타지 않는다.
    if (kDebugMode && Env.useFixtureInDebug) {
      // 마치 네트워크 호출처럼 보이도록 약간의 지연을 준다(스켈레톤 UI 검증용).
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return demoNatalChart();
    }
    try {
      final json = await _api.fetchNatalChart(birth);
      return _parseNatalChart(json);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] natal chart 실패 → fixture fallback: $e\n$st');
      }
      // 화면 깨짐 방지: 실패해도 사용자에겐 데모 차트라도 보여준다.
      return demoNatalChart();
    }
  }

  // ── JSON → NatalChart 매핑 ────────────────────────────────────
  // Prokerala 응답 포맷이 확정되지 않아 방어적으로 작성한다.
  // 키가 없으면 기본값을 쓰고, 타입이 다르면 무시.
  NatalChart _parseNatalChart(Map<String, dynamic> json) {
    final data = (json['data'] as Map?) ?? json;
    final planetsRaw = (data['planet_position'] as List?) ??
        (data['planets'] as List?) ??
        const [];
    final housesRaw = (data['houses'] as List?) ??
        (data['house_cusps'] as List?) ??
        const [];
    final aspectsRaw = (data['aspects'] as List?) ?? const [];

    final planets = <Planet>[];
    for (final p in planetsRaw) {
      if (p is! Map) continue;
      final name = (p['name'] ?? p['planet'] ?? '').toString();
      final sign = (p['sign'] ?? p['zodiac'] ?? '-').toString();
      final degree = _toDouble(p['degree'] ?? p['longitude']);
      final house = _toInt(p['house']);
      if (name.isEmpty) continue;
      planets.add(Planet(name: name, sign: sign, degree: degree, house: house));
    }

    final houses = <HouseCusp>[];
    for (final h in housesRaw) {
      if (h is! Map) continue;
      houses.add(HouseCusp(
        house: _toInt(h['house'] ?? h['number']) ?? 0,
        degree: _toDouble(h['degree'] ?? h['cusp']),
        sign: (h['sign'] ?? '-').toString(),
      ));
    }

    final aspects = <Aspect>[];
    for (final a in aspectsRaw) {
      if (a is! Map) continue;
      aspects.add(Aspect(
        planetA: (a['planet_a'] ?? a['planet1'] ?? '').toString(),
        planetB: (a['planet_b'] ?? a['planet2'] ?? '').toString(),
        aspect: (a['aspect'] ?? a['type'] ?? '').toString(),
        orb: _toDouble(a['orb']),
      ));
    }

    String findSign(String planet) => planets
        .firstWhere(
          (p) => p.name.toLowerCase() == planet.toLowerCase(),
          orElse: () => const Planet(name: '-', sign: '-', degree: 0),
        )
        .sign;

    final ascendantSign = (data['ascendant'] is Map)
        ? (data['ascendant']['sign'] ?? '-').toString()
        : findSign('Ascendant');

    return NatalChart(
      planets: planets,
      houses: houses,
      aspects: aspects,
      ascendantSign:
          ascendantSign == '-' ? findSign('Ascendant') : ascendantSign,
      sunSign: findSign('Sun'),
      moonSign: findSign('Moon'),
    );
  }

  static double _toDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int? _toInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
