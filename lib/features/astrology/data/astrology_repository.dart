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
import 'natal_chart_mapper.dart';
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
            '고정 mock 대신 birth 기반 로컬 차트를 사용합니다.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return _persistAndReturnFallbackChart(
        birth,
        source: 'local-derived',
        reason: 'policy-fixture',
      );
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
    final currentUid = _currentUid;
    if (currentUid != null) {
      final firestoreChart = await _chartRepo.get(currentUid, birth.chartVersion);
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
      final chart = NatalChartMapper.fromJson(json);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L4 API 응답 파싱 완료 '
            'sun=${chart.sunSign} moon=${chart.moonSign} asc=${chart.ascendantSign} '
            'planets=${chart.planets.length}개');
      }
      await _cache.putJson(cacheKey, chart.toJson(), source: 'live');
      if (currentUid != null) {
        await _chartRepo.save(
          uid: currentUid,
          chartVersion: birth.chartVersion,
          chart: chart,
          birth: birth,
          source: 'prokerala',
        );
      }
      return chart;
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[AstrologyRepository] L4 API 실패 → birth 기반 로컬 차트 fallback: $e\n$st');
      }
      return _persistAndReturnFallbackChart(
        birth,
        source: 'local-derived',
        reason: 'api-failure',
      );
    }
  }

  Future<NatalChart> _persistAndReturnFallbackChart(
    BirthInfo birth, {
    required String source,
    required String reason,
  }) async {
    final cacheKey = CacheKeys.natal(birth.chartVersion);
    final chart = buildFallbackNatalChart(birth);
    await _cache.putJson(cacheKey, chart.toJson(), source: source);
    final currentUid = _currentUid;
    if (currentUid != null) {
      await _chartRepo.save(
        uid: currentUid,
        chartVersion: birth.chartVersion,
        chart: chart,
        birth: birth,
        source: source,
      );
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[AstrologyRepository] fallback chart 생성 '
          'source=$source reason=$reason '
          'sun=${chart.sunSign} moon=${chart.moonSign} asc=${chart.ascendantSign} '
          'birth=${birth.chartVersion}');
    }
    return chart;
  }

}
