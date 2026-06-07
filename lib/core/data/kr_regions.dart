// 점성술 계산에 사용할 수 있는, 좌표가 확정된 한국 지역 목록.
// 출생지는 이 목록에서만 선택하도록 강제해 항상 유효한 위경도를 보장한다.

class KrRegion {
  final String name;
  final double latitude;
  final double longitude;

  const KrRegion(this.name, this.latitude, this.longitude);
}

const List<KrRegion> kKrRegions = [
  KrRegion('서울특별시', 37.5665, 126.9780),
  KrRegion('부산광역시', 35.1796, 129.0756),
  KrRegion('대구광역시', 35.8714, 128.6014),
  KrRegion('인천광역시', 37.4563, 126.7052),
  KrRegion('광주광역시', 35.1595, 126.8526),
  KrRegion('대전광역시', 36.3504, 127.3845),
  KrRegion('울산광역시', 35.5384, 129.3114),
  KrRegion('세종특별자치시', 36.4800, 127.2890),
  KrRegion('경기도 수원시', 37.2636, 127.0286),
  KrRegion('경기도 성남시', 37.4200, 127.1267),
  KrRegion('경기도 고양시', 37.6584, 126.8320),
  KrRegion('경기도 용인시', 37.2411, 127.1776),
  KrRegion('강원특별자치도 춘천시', 37.8813, 127.7298),
  KrRegion('강원특별자치도 강릉시', 37.7519, 128.8761),
  KrRegion('충청북도 청주시', 36.6424, 127.4890),
  KrRegion('충청남도 천안시', 36.8151, 127.1139),
  KrRegion('전북특별자치도 전주시', 35.8242, 127.1480),
  KrRegion('전라남도 목포시', 34.8118, 126.3922),
  KrRegion('전라남도 여수시', 34.7604, 127.6622),
  KrRegion('경상북도 포항시', 36.0190, 129.3435),
  KrRegion('경상북도 경주시', 35.8562, 129.2247),
  KrRegion('경상남도 창원시', 35.2280, 128.6811),
  KrRegion('경상남도 진주시', 35.1800, 128.1076),
  KrRegion('제주특별자치도 제주시', 33.4996, 126.5312),
  KrRegion('제주특별자치도 서귀포시', 33.2541, 126.5600),
];

/// 이름으로 지역을 찾는다. 정확히 일치하는 게 없으면 null.
KrRegion? findKrRegionByName(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  for (final r in kKrRegions) {
    if (r.name == trimmed) return r;
  }
  return null;
}
