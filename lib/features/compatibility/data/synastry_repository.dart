// lib/features/compatibility/data/synastry_repository.dart
//
// 궁합 결과 생성 흐름
//   1. L2 DiskCache 조회
//   2. L3 Firestore synastryCaches 조회
//   3. 나/친구 natal chart 확보 (charts → disk natal → API/fallback)
//   4. CompatibilityEngine 으로 로컬 계산
//   5. 결과를 DiskCache + Firestore 캐시에 저장
//
// 핵심 원칙
// - 결과 화면은 더 이상 고정 fixture 에 의존하지 않는다.
// - pairKey(uid 기반) + chartPairVersion(chartVersion 기반)으로 캐시를 안정화한다.
// - natal chart 가 이미 저장돼 있으면 그것을 우선 사용해 사용자 데이터와 일관성을 맞춘다.

import 'package:flutter/foundation.dart';

import '../../../core/cache/disk_cache.dart';
import '../../../core/env/env.dart';
import '../../astrology/data/chart_repository.dart';
import '../../astrology/data/natal_chart_mapper.dart';
import '../../astrology/data/prokerala_api.dart';
import '../../astrology/domain/birth_info.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../astrology/fixtures/natal_chart_fixture.dart';
import '../domain/synastry_result.dart';
import 'compatibility_engine.dart';
import 'synastry_cache_repository.dart';

class SynastryRepository {
  SynastryRepository(
    this._api,
    this._cache,
    this._firestoreCache,
    this._chartRepo,
    this._engine,
  );
  final ProkeralaApi _api;
  final DiskCache _cache;
  final SynastryCacheRepository _firestoreCache;
  final ChartRepository _chartRepo;
  final CompatibilityEngine _engine;

  Future<SynastryResult> compare({
    required BirthInfo me,
    required BirthInfo partner,
    String? myUid,
    String? partnerUid,
  }) async {
    final pairKey = _buildPairKey(
      myUid: myUid,
      partnerUid: partnerUid,
      meVersion: me.chartVersion,
      partnerVersion: partner.chartVersion,
    );
    final chartPairVersion = SynastryCacheRepository.buildChartPairVersion(
      me.chartVersion,
      partner.chartVersion,
    );
    final cacheKey = CacheKeys.synastry(pairKey, chartPairVersion);

    // L2: 디스크. pairKey + chartPairVersion 조합이 키.
    final cached = _cache.getJson(cacheKey);
    if (cached != null) {
      try {
        final result = SynastryResult.fromJson(cached);
        if (_isUsableCache(
          result,
          pairKey: pairKey,
          chartPairVersion: chartPairVersion,
        )) {
          return result;
        }
        await _cache.remove(cacheKey);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[SynastryRepository] L2 디코드 실패 → 실호출 fallback: $e');
        }
        await _cache.remove(cacheKey);
      }
    }

    // L3: Firestore 캐시 조회.
    if (myUid != null && partnerUid != null) {
      final firestoreResult = await _firestoreCache.get(
        uid1: myUid,
        uid2: partnerUid,
        meVersion: me.chartVersion,
        partnerVersion: partner.chartVersion,
        expectedEngineVersion: CompatibilityEngine.engineVersion,
      );
      if (firestoreResult != null) {
        await _cache.putJson(
          cacheKey,
          firestoreResult.toJson(),
          source: 'firestore',
        );
        return firestoreResult;
      }
    }

    final myChart = await _loadNatalChart(
      me,
      uid: myUid,
      persistIfOwner: myUid != null,
    );
    final partnerChart = await _loadNatalChart(
      partner,
      uid: partnerUid,
      persistIfOwner: false,
    );

    final result = _engine.evaluate(
      pairKey: pairKey,
      chartPairVersion: chartPairVersion,
      me: myChart,
      partner: partnerChart,
      source: 'local-engine',
    );
    await _cache.putJson(cacheKey, result.toJson(), source: result.source);

    if (myUid != null && partnerUid != null) {
      await _firestoreCache.save(
        uid1: myUid,
        uid2: partnerUid,
        meVersion: me.chartVersion,
        partnerVersion: partner.chartVersion,
        meBirth: me,
        partnerBirth: partner,
        meChart: myChart,
        partnerChart: partnerChart,
        result: result,
      );
    }
    return result;
  }

  bool _isUsableCache(
    SynastryResult result, {
    required String pairKey,
    required String chartPairVersion,
  }) {
    if (result.engineVersion != CompatibilityEngine.engineVersion) {
      return false;
    }
    if (result.chartPairVersion != null &&
        result.chartPairVersion != chartPairVersion) {
      return false;
    }
    if (result.pairKey != null && result.pairKey != pairKey) {
      return false;
    }
    return true;
  }

  String _buildPairKey({
    required String meVersion,
    required String partnerVersion,
    String? myUid,
    String? partnerUid,
  }) {
    if (myUid != null && partnerUid != null) {
      return SynastryCacheRepository.buildPairKey(myUid, partnerUid);
    }
    final local = ([meVersion, partnerVersion]..sort()).join('__');
    return 'local__$local';
  }

  Future<NatalChart> _loadNatalChart(
    BirthInfo birth, {
    String? uid,
    required bool persistIfOwner,
  }) async {
    final natalCacheKey = CacheKeys.natal(birth.chartVersion);

    if (uid != null) {
      final firestoreChart = await _chartRepo.get(uid, birth.chartVersion);
      if (firestoreChart != null) {
        await _cache.putJson(
          natalCacheKey,
          firestoreChart.toJson(),
          source: 'firestore',
        );
        return firestoreChart;
      }
    }

    final disk = _cache.getJson(natalCacheKey);
    if (disk != null) {
      try {
        return NatalChart.fromJson(disk);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[SynastryRepository] natal L2 디코드 실패 → 재계산: $e');
        }
        await _cache.remove(natalCacheKey);
      }
    }

    if (Env.shouldUseFixtureForProkerala) {
      return _fallbackNatalChart(
        birth,
        uid: uid,
        persistIfOwner: persistIfOwner,
        reason: 'policy-fixture',
      );
    }

    try {
      final json = await _api.fetchNatalChart(birth);
      final chart = NatalChartMapper.fromJson(json);
      await _cache.putJson(natalCacheKey, chart.toJson(), source: 'live');
      if (uid != null && persistIfOwner) {
        await _chartRepo.save(
          uid: uid,
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
        print('[SynastryRepository] natal API 실패 → fallback: $e\n$st');
      }
      return _fallbackNatalChart(
        birth,
        uid: uid,
        persistIfOwner: persistIfOwner,
        reason: 'api-failure',
      );
    }
  }

  Future<NatalChart> _fallbackNatalChart(
    BirthInfo birth, {
    String? uid,
    required bool persistIfOwner,
    required String reason,
  }) async {
    final chart = buildFallbackNatalChart(birth);
    await _cache.putJson(
      CacheKeys.natal(birth.chartVersion),
      chart.toJson(),
      source: 'local-derived',
    );
    if (uid != null && persistIfOwner) {
      await _chartRepo.save(
        uid: uid,
        chartVersion: birth.chartVersion,
        chart: chart,
        birth: birth,
        source: 'local-derived',
      );
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SynastryRepository] natal fallback 생성 reason=$reason '
          'sun=${chart.sunSign} moon=${chart.moonSign} asc=${chart.ascendantSign}');
    }
    return chart;
  }
}
