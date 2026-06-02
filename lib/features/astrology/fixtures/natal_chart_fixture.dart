// lib/features/astrology/fixtures/natal_chart_fixture.dart
//
// Prokerala 응답을 흉내 낸 fixture(녹화) 데이터. 개발 중에 credit 을 아끼고,
// 오프라인 상태에서도 화면이 의미있는 데이터로 채워지도록 한다.
//
// 9주차 동안에는 fixture 위주로 화면을 만들고, 첫 실호출 1회 후 실응답으로 교체.
// (Repository 에서 .fromApi() 가 실패하면 자동으로 이 fixture 가 fallback 되도록 구성.)

import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';

NatalChart demoNatalChart() {
  return buildFallbackNatalChart(BirthInfo.demo());
}

const List<String> _zodiacSigns = <String>[
  'Aries',
  'Taurus',
  'Gemini',
  'Cancer',
  'Leo',
  'Virgo',
  'Libra',
  'Scorpio',
  'Sagittarius',
  'Capricorn',
  'Aquarius',
  'Pisces',
];

NatalChart buildFallbackNatalChart(BirthInfo birth) {
  final seed = _seedFromBirth(birth);
  final sunIndex = _sunSignIndex(birth.dateTime);
  final moonIndex = _positiveMod(
    (birth.dateTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) +
        birth.dateTime.hour * 2 +
        (birth.dateTime.minute ~/ 10) +
        birth.latitude.round() +
        birth.longitude.round(),
    12,
  );
  final ascendantIndex = _positiveMod(
    ((birth.dateTime.hour * 60 + birth.dateTime.minute) ~/ 120) +
        ((birth.longitude + 180) / 30).floor(),
    12,
  );
  final ascendantDegreeInSign =
      ((birth.dateTime.minute + birth.latitude.abs()).toDouble() % 30)
          .clamp(0.0, 29.99);
  final ascendantDegree = _normalizeDegree(
    ascendantIndex * 30.0 + ascendantDegreeInSign,
  );

  Planet buildPlanet(
    String name,
    int signIndex,
    int salt, {
    double? forcedDegreeInSign,
  }) {
    final degreeInSign = forcedDegreeInSign ??
        ((_positiveMod(seed ~/ (salt + 11), 3000)) / 100.0)
            .clamp(0.0, 29.99);
    final degree = _normalizeDegree(signIndex * 30.0 + degreeInSign);
    final house = ((_normalizeDegree(degree - ascendantDegree)) ~/ 30).toInt() + 1;
    return Planet(
      name: name,
      sign: _zodiacSigns[signIndex],
      degree: degree,
      house: house,
    );
  }

  final sunDegreeInSign = _sunDegreeInSign(birth.dateTime);
  final mercuryIndex = _positiveMod(sunIndex + _smallOffset(seed, 1, 1), 12);
  final venusIndex = _positiveMod(sunIndex + _smallOffset(seed, 2, 2), 12);
  final marsIndex = _positiveMod(
    (birth.dateTime.year + birth.dateTime.month + birth.dateTime.day + seed) ~/ 7,
    12,
  );
  final jupiterIndex = _positiveMod((birth.dateTime.year + seed) ~/ 9, 12);
  final saturnIndex = _positiveMod((birth.dateTime.year + seed) ~/ 17, 12);

  final planets = <Planet>[
    buildPlanet('Sun', sunIndex, 13, forcedDegreeInSign: sunDegreeInSign),
    buildPlanet('Moon', moonIndex, 23),
    buildPlanet('Mercury', mercuryIndex, 31),
    buildPlanet('Venus', venusIndex, 41),
    buildPlanet('Mars', marsIndex, 53),
    buildPlanet('Jupiter', jupiterIndex, 67),
    buildPlanet('Saturn', saturnIndex, 79),
  ];

  final houses = List<HouseCusp>.generate(12, (index) {
    final degree = _normalizeDegree(ascendantDegree + index * 30.0);
    return HouseCusp(
      house: index + 1,
      degree: degree,
      sign: _zodiacSigns[(degree ~/ 30).floor() % 12],
    );
  });

  final aspects = _buildAspects(planets);

  return NatalChart(
    sunSign: _zodiacSigns[sunIndex],
    moonSign: _zodiacSigns[moonIndex],
    ascendantSign: _zodiacSigns[ascendantIndex],
    planets: planets,
    houses: houses,
    aspects: aspects,
  );
}

List<Aspect> _buildAspects(List<Planet> planets) {
  const aspectTargets = <String, double>{
    'Conjunction': 0,
    'Sextile': 60,
    'Square': 90,
    'Trine': 120,
    'Opposition': 180,
  };

  final aspects = <Aspect>[];
  for (var i = 0; i < planets.length; i++) {
    for (var j = i + 1; j < planets.length; j++) {
      final a = planets[i];
      final b = planets[j];
      final diff = _aspectDistance(a.degree, b.degree);

      String? matchedAspect;
      double? matchedOrb;
      for (final entry in aspectTargets.entries) {
        final orb = (diff - entry.value).abs();
        if (orb <= 6.0 && (matchedOrb == null || orb < matchedOrb)) {
          matchedAspect = entry.key;
          matchedOrb = orb;
        }
      }

      if (matchedAspect != null && matchedOrb != null) {
        aspects.add(
          Aspect(
            planetA: a.name,
            planetB: b.name,
            aspect: matchedAspect,
            orb: double.parse(matchedOrb.toStringAsFixed(1)),
          ),
        );
      }
    }
  }

  aspects.sort((a, b) => a.orb.compareTo(b.orb));
  return aspects.take(6).toList();
}

int _seedFromBirth(BirthInfo birth) {
  return birth.dateTime.microsecondsSinceEpoch ^
      birth.latitude.toStringAsFixed(4).hashCode ^
      birth.longitude.toStringAsFixed(4).hashCode ^
      birth.utcOffset.hashCode;
}

int _smallOffset(int seed, int salt, int radius) {
  return _positiveMod(seed ~/ (salt + 19), radius * 2 + 1) - radius;
}

double _aspectDistance(double a, double b) {
  final raw = (a - b).abs() % 360.0;
  return raw > 180.0 ? 360.0 - raw : raw;
}

double _normalizeDegree(double value) {
  final normalized = value % 360.0;
  return normalized < 0 ? normalized + 360.0 : normalized;
}

int _positiveMod(int value, int mod) {
  final result = value % mod;
  return result < 0 ? result + mod : result;
}

int _sunSignIndex(DateTime dateTime) {
  final month = dateTime.month;
  final day = dateTime.day;
  if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 0;
  if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 1;
  if ((month == 5 && day >= 21) || (month == 6 && day <= 21)) return 2;
  if ((month == 6 && day >= 22) || (month == 7 && day <= 22)) return 3;
  if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 4;
  if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 5;
  if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 6;
  if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 7;
  if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 8;
  if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 9;
  if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 10;
  return 11;
}

double _sunDegreeInSign(DateTime dateTime) {
  final start = _sunSignStart(dateTime);
  final next = _nextSunSignStart(dateTime);
  final totalMinutes = next.difference(start).inMinutes;
  if (totalMinutes <= 0) {
    return 0;
  }
  final progressedMinutes = dateTime.difference(start).inMinutes;
  return ((progressedMinutes / totalMinutes) * 30.0).clamp(0.0, 29.99);
}

DateTime _sunSignStart(DateTime dateTime) {
  final year = dateTime.year;
  final month = dateTime.month;
  final day = dateTime.day;
  if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
    return DateTime(year, 3, 21);
  }
  if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
    return DateTime(year, 4, 20);
  }
  if ((month == 5 && day >= 21) || (month == 6 && day <= 21)) {
    return DateTime(year, 5, 21);
  }
  if ((month == 6 && day >= 22) || (month == 7 && day <= 22)) {
    return DateTime(year, 6, 22);
  }
  if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
    return DateTime(year, 7, 23);
  }
  if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
    return DateTime(year, 8, 23);
  }
  if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
    return DateTime(year, 9, 23);
  }
  if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
    return DateTime(year, 10, 23);
  }
  if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
    return DateTime(year, 11, 22);
  }
  if (month == 12 && day >= 22) {
    return DateTime(year, 12, 22);
  }
  if (month == 1 && day >= 20) {
    return DateTime(year, 1, 20);
  }
  if (month == 2 && day >= 19) {
    return DateTime(year, 2, 19);
  }
  return DateTime(year - 1, 12, 22);
}

DateTime _nextSunSignStart(DateTime dateTime) {
  final currentStart = _sunSignStart(dateTime);
  final month = currentStart.month;
  final year = currentStart.year;
  switch (month) {
    case 1:
      return DateTime(year, 2, 19);
    case 2:
      return DateTime(year, 3, 21);
    case 3:
      return DateTime(year, 4, 20);
    case 4:
      return DateTime(year, 5, 21);
    case 5:
      return DateTime(year, 6, 22);
    case 6:
      return DateTime(year, 7, 23);
    case 7:
      return DateTime(year, 8, 23);
    case 8:
      return DateTime(year, 9, 23);
    case 9:
      return DateTime(year, 10, 23);
    case 10:
      return DateTime(year, 11, 22);
    case 11:
      return DateTime(year, 12, 22);
    default:
      return DateTime(year + 1, 1, 20);
  }
}
