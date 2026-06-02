// lib/features/users/domain/user_profile.dart
//
// SDD 8.3 의 `users/{uid}` 컬렉션 스키마를 반영한 도메인 모델.
//
// 매핑 규칙 (SDD 8.1)
//   - Dart `BirthInfo.dateTime` (DateTime, 현지 시각) ↔ Firestore `dateTimeLocal` (String, ISO 8601)
//   - 변환은 본 파일의 toFirestore/fromFirestore 단계에서만 수행한다.
//
// freezed 미사용 정책 유지 (SDD 3.2). 직접 작성한다.

import '../../astrology/domain/birth_info.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.authProvider,
    required this.loginId,
    required this.nickname,
    required this.profileCompleted,
    this.friendCode,
    this.sunSign,
    this.birthInfo,
    this.favoriteIds = const [],
    this.activeChartVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firebase uid. Email/Password Auth 기준.
  final String uid;

  /// 서비스용 아이디. loginIds/{loginId} 에 인덱스 저장.
  final String loginId;

  /// "email" | "anonymous" | "kakao".
  final String authProvider;

  final String nickname;

  /// 출생정보 + geocoding 결과까지 모두 채워졌는지. 온보딩 미완료 사용자 라우팅에 사용.
  final bool profileCompleted;

  /// 현재 활성 친구 코드. T16 에서 발급되기 전까지 null 가능.
  final String? friendCode;

  /// 태양 별자리. charts/{uid} 생성 후 동기화됨. 미생성 시 null.
  /// friend_repository 에서 data['sunSign'] 으로 읽으므로 toFirestore 에 반드시 포함.
  final String? sunSign;

  /// 출생정보. 온보딩 진입 전이면 null 가능.
  final BirthInfo? birthInfo;

  /// 즐겨찾기 친구 uid 목록. SDD 8.5 제약: 최대 3명, friendship 멤버만.
  final List<String> favoriteIds;

  /// `charts/{uid}.chartVersion` 과 동기화. stale 차트 감지에 사용 (T12 ~).
  final String? activeChartVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? uid,
    String? authProvider,
    String? loginId,
    String? nickname,
    bool? profileCompleted,
    String? friendCode,
    String? sunSign,
    BirthInfo? birthInfo,
    List<String>? favoriteIds,
    String? activeChartVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      authProvider: authProvider ?? this.authProvider,
      loginId: loginId ?? this.loginId,
      nickname: nickname ?? this.nickname,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      friendCode: friendCode ?? this.friendCode,
      sunSign: sunSign ?? this.sunSign,
      birthInfo: birthInfo ?? this.birthInfo,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      activeChartVersion: activeChartVersion ?? this.activeChartVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Firestore 저장용 변환. SDD 8.1 매핑 규칙:
  ///   - `dateTime` 은 ISO 8601 문자열 `dateTimeLocal` 로 직렬화
  ///   - timestamp 는 Firestore Timestamp 가 아니라 문자열 ISO 8601 로 저장 (테스트/디버그 가독성).
  ///     운영 단계에서 정렬/쿼리 효율이 필요하면 Timestamp 로 마이그레이션.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'loginId': loginId,
      'authProvider': authProvider,
      'nickname': nickname,
      'profileCompleted': profileCompleted,
      'friendCode': friendCode,
      'sunSign': sunSign,
      'birthInfo': birthInfo == null ? null : _birthInfoToFirestore(birthInfo!),
      'favoriteIds': favoriteIds,
      'activeChartVersion': activeChartVersion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// `users/{uid}` 문서 → 도메인 모델. uid 는 문서 ID 에서 받음.
  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      loginId: (data['loginId'] as String?) ?? '',
      authProvider: (data['authProvider'] as String?) ?? 'email',
      nickname: (data['nickname'] as String?) ?? '익명의 행성',
      profileCompleted: (data['profileCompleted'] as bool?) ?? false,
      friendCode: data['friendCode'] as String?,
      sunSign: data['sunSign'] as String?,
      birthInfo: data['birthInfo'] is Map<String, dynamic>
          ? _birthInfoFromFirestore(data['birthInfo'] as Map<String, dynamic>)
          : null,
      favoriteIds: (data['favoriteIds'] as List?)?.cast<String>() ?? const [],
      activeChartVersion: data['activeChartVersion'] as String?,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now().toUtc(),
    );
  }

  static Map<String, dynamic> _birthInfoToFirestore(BirthInfo b) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final dt = '${b.dateTime.year}-${pad(b.dateTime.month)}-${pad(b.dateTime.day)}'
        'T${pad(b.dateTime.hour)}:${pad(b.dateTime.minute)}:${pad(b.dateTime.second)}';
    return {
      'nickname': b.nickname,
      'dateTimeLocal': dt,
      'utcOffset': b.utcOffset,
      'placeName': b.placeName,
      'latitude': b.latitude,
      'longitude': b.longitude,
    };
  }

  static BirthInfo? _birthInfoFromFirestore(Map<String, dynamic> data) {
    final dtLocal = data['dateTimeLocal'] as String?;
    final lat = data['latitude'];
    final lng = data['longitude'];
    final offset = data['utcOffset'] as String?;
    if (dtLocal == null || lat is! num || lng is! num || offset == null) {
      return null;
    }
    final parsed = DateTime.tryParse(dtLocal);
    if (parsed == null) return null;
    return BirthInfo(
      nickname: (data['nickname'] as String?) ?? '익명의 행성',
      dateTime: parsed,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      utcOffset: offset,
      placeName: data['placeName'] as String?,
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
