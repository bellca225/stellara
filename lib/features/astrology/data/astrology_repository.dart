// lib/features/astrology/data/astrology_repository.dart
//
// 화면이 사용할 NatalChart 를 만드는 책임.
//
// 흐름:
//   화면(Provider) → AstrologyRepository.getNatalChart(BirthInfo)
//     ├─ PROKERALA_REMOTE_ENABLED=false 이면 fixture 반환 (무과금 보호)
//     ├─ debug + USE_FIXTURE_IN_DEBUG=true 이면 fixture 반환 (credit 절약)
//     ├─ 그렇지 않으면 ProkeralaApi.fetchNatalChart 호출
//     └─ 응답 JSON → NatalChart 매핑. 매핑 실패 시 fixture 로 graceful fallback
//
// 9주차 핵심 가치: "API 가 죽거나 응답 모양이 다르더라도 화면은 깨지지 않는다."

import 'package:flutter/foundation.dart';

import '../../../core/cache/disk_cache.dart';
import '../../../core/env/env.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';
import '../fixtures/natal_chart_fixture.dart';
import 'chart_repository.dart';
import 'prokerala_api.dart';

class AstrologyRepository {
  AstrologyRepository(this._api, this._cache, this._chartRepo, {String? uid})
      : _currentUid = uid;
  final ProkeralaApi _api;
  final DiskCache _cache;
  final ChartRepository _chartRepo;

  /// 현재 로그인 사용자 uid. Firestore L3 저장/조회에 사용. null 이면 L3 스킵.
  final String? _currentUid;

  Future<NatalChart> getNatalChart(BirthInfo birth) async {
    // L0 (fixture): 기본 브랜치 정책 또는 디버그 + fixture 옵션이면 네트워크를 타지 않는다.
    if (Env.shouldUseFixtureForProkerala) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L0 fixture 반환 '
            '(shouldUseFixtureForProkerala=true). '
            'birth 변경이 반영되지 않습니다. '
            '.env PROKERALA_REMOTE_ENABLED=true, USE_FIXTURE_IN_DEBUG=false 확인 필요.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return demoNatalChart();
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('[AstrologyRepository] getNatalChart 시작 '
          'birth=${birth.chartVersion} uid=$_currentUid');
    }

    // L2 (디스크) 조회. chartVersion 이 같으면 무조건 hit (영구 TTL).
    final cacheKey = CacheKeys.natal(birth.chartVersion);
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L2 disk 캐시 hit key=$cacheKey');
      }
      try {
        return NatalChart.fromJson(cached);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[AstrologyRepository] L2 디코드 실패 → L3 fallback: $e');
        }
      }
    }

    // L3 (Firestore) 조회. 앱 재설치 / 기기 변경 후에도 차트 유지.
    if (_currentUid != null) {
      final firestoreChart = await _chartRepo.get(_currentUid!, birth.chartVersion);
      if (firestoreChart != null) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[AstrologyRepository] L3 Firestore 캐시 hit uid=$_currentUid');
        }
        await _cache.putJson(cacheKey, firestoreChart.toJson(), source: 'firestore');
        return firestoreChart;
      }
    }

    // L4: Prokerala API 실호출
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AstrologyRepository] L4 API 호출 시작 birth=${birth.chartVersion}');
    }
    try {
      final json = await _api.fetchNatalChart(birth);
      final chart = _parseNatalChart(json);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L4 API 응답 파싱 완료 '
            'sun=${chart.sunSign} moon=${chart.moonSign} asc=${chart.ascendantSign} '
            'planets=${chart.planets.length}개');
      }
      await _cache.putJson(cacheKey, chart.toJson(), source: 'live');
      if (_currentUid != null) {
        await _chartRepo.save(
          uid: _currentUid!,
          chartVersion: birth.chartVersion,
          chart: chart,
          birth: birth,
        );
      }
      return chart;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L4 API 실패 → fixture fallback: $e\n$st');
      }
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
