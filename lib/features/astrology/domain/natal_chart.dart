// lib/features/astrology/domain/natal_chart.dart
//
// 화면이 그릴 수 있도록 다듬은 출생 차트 모델.
//
// 왜 freezed 를 쓰지 않았나
// - Prokerala 응답 키 이름이 정식 확정되지 않은 9주차 단계.
// - freezed + json_serializable 로 묶으면 키가 바뀔 때마다 코드 생성을 다시 돌려야 한다.
// - 따라서 이 단계에선 "응답 → 도메인" 매핑을 Repository 에서 직접 작성하고,
//   응답 모양이 안정화되면 freezed 로 옮기기로 한다 (향후 작업 후보).

class Planet {
  const Planet({
    required this.name,
    required this.sign,
    required this.degree,
    this.house,
  });

  /// 'Sun', 'Moon', 'Mercury' …
  final String name;

  /// 황도 12궁 영문명. 'Aquarius', 'Pisces' …
  final String sign;

  /// 0~360°. 화면에 표시할 때는 sign 안에서의 degree 로 환산해 보인다.
  final double degree;

  /// 1~12. 응답에 없을 수 있어 nullable.
  final int? house;

  /// `degree` 를 sign 안에서의 0~30° 표기로 보여줄 때 사용.
  double get degreeInSign => degree % 30.0;
}

class HouseCusp {
  const HouseCusp({required this.house, required this.degree, required this.sign});
  final int house; // 1~12
  final double degree; // 0~360
  final String sign;
}

class Aspect {
  const Aspect({
    required this.planetA,
    required this.planetB,
    required this.aspect,
    required this.orb,
  });

  /// 'Sun', 'Moon' …
  final String planetA;
  final String planetB;

  /// 'Conjunction', 'Trine', 'Square' …
  final String aspect;

  /// 어스펙트 정확도 (도수 차이). 작을수록 강한 어스펙트.
  final double orb;
}

/// 화면(ASTROLOGY-001) 이 직접 사용하는 통합 모델.
class NatalChart {
  const NatalChart({
    required this.planets,
    required this.houses,
    required this.aspects,
    required this.ascendantSign,
    required this.sunSign,
    required this.moonSign,
  });

  final List<Planet> planets;
  final List<HouseCusp> houses;
  final List<Aspect> aspects;

  /// "Big 3" — 메인 홈 카드에 바로 보여주는 핵심 별자리.
  final String ascendantSign;
  final String sunSign;
  final String moonSign;

  /// 빈 차트(로딩 중에 화면이 무너지지 않도록).
  static const empty = NatalChart(
    planets: [],
    houses: [],
    aspects: [],
    ascendantSign: '-',
    sunSign: '-',
    moonSign: '-',
  );
}
