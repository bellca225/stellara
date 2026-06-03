import '../domain/natal_chart.dart';

/// Prokerala natal chart 응답(JSON)을 앱 도메인인 [NatalChart]로 매핑한다.
///
/// 응답 키 이름이 완전히 고정되지 않은 상태라 방어적으로 파싱한다.
class NatalChartMapper {
  const NatalChartMapper._();

  static NatalChart fromJson(Map<String, dynamic> json) {
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
