// lib/features/compatibility/data/synastry_repository.dart
//
// 9주차 메모: Synastry 응답에서 "총점/감정/대화/연애" 4개 점수를 어떻게
// 산출할지는 디자인 결정사항이다. Prokerala 의 raw synastry 는 어스펙트만 주므로,
// 우리는 어스펙트 종류별 가중치를 곱해 4축 점수를 만든다.
// 이 가중치는 점성술 일반 통념(친화 어스펙트=Trine/Sextile/+, 갈등=Square/Opposition/-)
// 에 따른 임의 휴리스틱이다. 추후 11주차 이후에 더 정교화한다.

import 'package:flutter/foundation.dart';

import '../../../core/env/env.dart';
import '../../astrology/data/prokerala_api.dart';
import '../../astrology/domain/birth_info.dart';
import '../domain/synastry_result.dart';
import '../fixtures/synastry_fixture.dart';

class SynastryRepository {
  SynastryRepository(this._api);
  final ProkeralaApi _api;

  Future<SynastryResult> compare({
    required BirthInfo me,
    required BirthInfo partner,
  }) async {
    if (kDebugMode && Env.useFixtureInDebug) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return demoSynastry();
    }
    try {
      final json = await _api.fetchSynastry(me: me, partner: partner);
      return _scoreFromJson(json);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[SynastryRepository] 실패 → fixture: $e');
      }
      return demoSynastry();
    }
  }

  /// Prokerala 응답 → 4축 점수.
  ///
  /// 각 어스펙트마다 카테고리별 가중치를 더해 0~100 으로 정규화.
  SynastryResult _scoreFromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?) ?? json;
    final aspects = (data['aspects'] as List?) ?? const [];

    // 카테고리별 누적 점수.
    double emotion = 50, comm = 50, romance = 50;

    for (final a in aspects) {
      if (a is! Map) continue;
      final type = (a['aspect'] ?? '').toString().toLowerCase();
      final pa = (a['planet_a'] ?? a['planet1'] ?? '').toString().toLowerCase();
      final pb = (a['planet_b'] ?? a['planet2'] ?? '').toString().toLowerCase();

      // 어스펙트 종류별 영향 (대략적 휴리스틱)
      double sign;
      switch (type) {
        case 'trine':
        case 'sextile':
        case 'conjunction':
          sign = 1.0;
          break;
        case 'square':
        case 'opposition':
          sign = -1.0;
          break;
        default:
          sign = 0.3;
      }

      // 행성 짝에 따라 어떤 카테고리에 영향을 주는지.
      bool involves(String x) => pa == x || pb == x;
      if (involves('moon') || involves('venus')) emotion += 4 * sign;
      if (involves('mercury')) comm += 4 * sign;
      if (involves('venus') || involves('mars')) romance += 4 * sign;
    }

    int clamp(double v) => v.clamp(0, 100).round();
    final emotionScore = clamp(emotion);
    final commScore = clamp(comm);
    final romanceScore = clamp(romance);
    final total = ((emotionScore + commScore + romanceScore) / 3).round();

    return SynastryResult(
      totalScore: total,
      emotionScore: emotionScore,
      communicationScore: commScore,
      romanceScore: romanceScore,
      summary: total >= 75
          ? '서로의 흐름이 자연스럽게 이어져 편안한 온기가 느껴지는 조합입니다.'
          : total >= 55
              ? '기본적인 궁합은 좋은 편이고, 대화를 조금만 더 세심하게 챙기면 더 가까워질 수 있습니다.'
              : '리듬 차이는 있지만 서로를 이해하려는 마음이 쌓이면 관계가 충분히 깊어질 수 있습니다.',
    );
  }
}
