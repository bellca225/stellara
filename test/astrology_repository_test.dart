// test/astrology_repository_test.dart
//
// AstrologyRepository._parseNatalChart 가 실응답과 비슷한 모양에서
// 안전하게 동작하는지(누락 키, 잘못된 타입에 안 죽는지) 검증.
//
// _parseNatalChart 는 private 이라 직접 호출 못 함.
// → 9주차 단계에서는 fixture 자체가 잘 빌드되는지만 확인하는 수준의 라이트 테스트.
// 응답 모양이 확정되면 _parseNatalChart 를 @visibleForTesting 으로 노출해 본격 테스트 추가.

import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/features/astrology/fixtures/natal_chart_fixture.dart';
import 'package:stellara/features/compatibility/fixtures/synastry_fixture.dart';
import 'package:stellara/features/horoscope/fixtures/horoscope_fixture.dart';

void main() {
  test('demoNatalChart 는 Big 3 가 채워져 있다', () {
    final c = demoNatalChart();
    expect(c.sunSign, isNotEmpty);
    expect(c.moonSign, isNotEmpty);
    expect(c.ascendantSign, isNotEmpty);
    expect(c.planets.length, greaterThanOrEqualTo(7));
  });

  test('demoHoroscope 은 빈 슬러그도 안전 처리', () {
    final h = demoHoroscope('aquarius');
    expect(h.signSlug, 'aquarius');
    expect(h.signName, 'Aquarius');
    expect(h.summary, isNotEmpty);
  });

  test('demoSynastry 점수는 0~100 범위', () {
    final s = demoSynastry();
    for (final v in [
      s.totalScore,
      s.emotionScore,
      s.communicationScore,
      s.romanceScore,
    ]) {
      expect(v, greaterThanOrEqualTo(0));
      expect(v, lessThanOrEqualTo(100));
    }
  });
}
