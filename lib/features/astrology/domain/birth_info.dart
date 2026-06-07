// lib/features/astrology/domain/birth_info.dart
//
// 출생 정보 도메인 모델.
//
// freezed를 쓸 수도 있지만 이 모델은 form 입력값 + 좌표 변환 결과만
// 보관하는 단순 값이라 직접 작성한다(코드 생성 의존을 한 곳이라도 줄이려는 의도).
// 향후 Firestore 저장이 추가되면 freezed 로 옮기는 것을 권장.

class BirthInfo {
  BirthInfo({
    required this.nickname,
    required this.dateTime,
    required this.latitude,
    required this.longitude,
    required this.utcOffset,
    this.placeName,
  });

  final String nickname;

  /// "현지 시각" 기준 출생일시. (예: 1999-02-25 14:30, 한국 출생이면 KST.)
  /// utcOffset 와 함께 보관해야 Prokerala 가 정확한 절대 시각을 계산할 수 있다.
  final DateTime dateTime;

  final double latitude;
  final double longitude;

  /// "+09:00" 형태의 UTC offset 문자열.
  final String utcOffset;

  /// 사용자에게 표시용으로 보여줄 출생지 이름(선택).
  final String? placeName;

  BirthInfo copyWith({
    String? nickname,
    DateTime? dateTime,
    double? latitude,
    double? longitude,
    String? utcOffset,
    String? placeName,
  }) {
    return BirthInfo(
      nickname: nickname ?? this.nickname,
      dateTime: dateTime ?? this.dateTime,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      utcOffset: utcOffset ?? this.utcOffset,
      placeName: placeName ?? this.placeName,
    );
  }

  /// 화면 안내용 데모 데이터. (실 API 호출 전, 화면 진입 즉시 빈 화면이 보이지 않게.)
  static BirthInfo demo() => BirthInfo(
        nickname: '물병자리의 꿈',
        dateTime: DateTime(2002, 1, 1, 00, 00),
        latitude: 37.5665,
        longitude: 126.9780,
        utcOffset: '+09:00',
        placeName: '서울특별시',
      );

  /// 차트 캐시 키. SDD 5.6.2 정의를 그대로 따름:
  ///   `${dateTimeLocal}_${lat}_${lng}_${utcOffset}`
  ///
  /// 어느 한 필드라도 바뀌면 새 키가 되어 자동으로 캐시 miss → 재호출.
  String get chartVersion {
    String pad(int n) => n.toString().padLeft(2, '0');
    final dt = '${dateTime.year}-${pad(dateTime.month)}-${pad(dateTime.day)}'
        'T${pad(dateTime.hour)}:${pad(dateTime.minute)}:${pad(dateTime.second)}';
    return '${dt}_${latitude}_${longitude}_$utcOffset';
  }

  /// Riverpod .family 캐시 키로 사용되므로 값 기반 동등성이 필수.
  /// 같은 출생 정보면 동일 객체로 취급 → 불필요한 provider 재생성 방지.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BirthInfo &&
          other.dateTime == dateTime &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.utcOffset == utcOffset &&
          other.nickname == nickname;

  @override
  int get hashCode => Object.hash(dateTime, latitude, longitude, utcOffset, nickname);

  @override
  String toString() =>
      'BirthInfo(nickname=$nickname, dt=$dateTime, lat=$latitude, lng=$longitude, '
      'offset=$utcOffset, place=$placeName)';
}
