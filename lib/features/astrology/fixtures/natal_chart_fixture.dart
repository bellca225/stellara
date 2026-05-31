// lib/features/astrology/fixtures/natal_chart_fixture.dart
//
// Prokerala 응답을 흉내 낸 fixture(녹화) 데이터. 개발 중에 credit 을 아끼고,
// 오프라인 상태에서도 화면이 의미있는 데이터로 채워지도록 한다.
//
// 9주차 동안에는 fixture 위주로 화면을 만들고, 첫 실호출 1회 후 실응답으로 교체.
// (Repository 에서 .fromApi() 가 실패하면 자동으로 이 fixture 가 fallback 되도록 구성.)

import '../domain/natal_chart.dart';

NatalChart demoNatalChart() {
  return const NatalChart(
    sunSign: 'Aquarius',
    moonSign: 'Cancer',
    ascendantSign: 'Libra',
    planets: [
      Planet(name: 'Sun', sign: 'Aquarius', degree: 326.4, house: 5),
      Planet(name: 'Moon', sign: 'Cancer', degree: 95.2, house: 10),
      Planet(name: 'Mercury', sign: 'Capricorn', degree: 285.0, house: 4),
      Planet(name: 'Venus', sign: 'Pisces', degree: 350.7, house: 6),
      Planet(name: 'Mars', sign: 'Sagittarius', degree: 245.1, house: 3),
      Planet(name: 'Jupiter', sign: 'Sagittarius', degree: 263.8, house: 3),
      Planet(name: 'Saturn', sign: 'Pisces', degree: 345.9, house: 6),
    ],
    houses: [
      HouseCusp(house: 1, degree: 180.0, sign: 'Libra'),
      HouseCusp(house: 4, degree: 270.0, sign: 'Capricorn'),
      HouseCusp(house: 7, degree: 0.0, sign: 'Aries'),
      HouseCusp(house: 10, degree: 90.0, sign: 'Cancer'),
    ],
    aspects: [
      Aspect(planetA: 'Sun', planetB: 'Moon', aspect: 'Square', orb: 1.2),
      Aspect(planetA: 'Sun', planetB: 'Jupiter', aspect: 'Sextile', orb: 2.5),
      Aspect(planetA: 'Venus', planetB: 'Saturn', aspect: 'Conjunction', orb: 0.8),
    ],
  );
}
