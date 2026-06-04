// lib/features/users/domain/user_profile.dart
//
// SDD 8.3 의 `users/{uid}` 컬렉션 스키마를 반영한 도메인 모델.
//
// 필드 구분 (displayName 도입 이후):
//   - loginId     : 로그인 전용 식별자. 화면에 노출하지 않음.
//   - displayName : 온보딩에서 사용자가 직접 입력한 표시 이름. 화면 전반 노출.
//   - nickname    : 기존 호환 필드. displayName 미존재 시 fallback.
//
// 매핑 규칙 (SDD 8.1)
//   - Dart `BirthInfo.dateTime` (DateTime, 현지 시각) ↔ Firestore `dateTimeLocal` (String, ISO 8601)
//   - 변환은 본 파일의 toFirestore/fromFirestore 단계에서만 수행한다.

import '../../astrology/domain/birth_info.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.authProvider,
    required this.loginId,
    required this.nickname,
    required this.profileCompleted,
    this.displayName,
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

  /// 서비스용 로그인 아이디. 로그인 외에는 노출하지 않음.
  final String loginId;

  /// "email" | "anonymous" | "kakao".
  final String authProvider;

  /// 온보딩 이름 step 에서 사용자가 직접 입력한 표시 이름.
  /// null 이면 [nickname] → [loginId] 순으로 fallback.
  final String? displayName;

  /// 기존 호환 필드. [displayName] 미존재 시 표시 이름으로 사용.
  final String nickname;

  /// 화면 전반에서 사용할 표시 이름.
  String get effectiveDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (nickname.trim().isNotEmpty && nickname != loginId) return nickname;
    return loginId;
  }

  /// 출생정보 + geocoding 결과까지 모두 채워졌는지.
  final bool profileCompleted;

  /// 현재 활성 친구 코드.
  final String? friendCode;

  /// 태양 별자리. charts/{uid} 생성 후 동기화됨.
  final String? sunSign;

  /// 출생정보.
  final BirthInfo? birthInfo;

  /// 즐겨찾기 친구 uid 목록.
  final List<String> favoriteIds;

  /// `charts/{uid}.chartVersion` 과 동기화.
  final String? activeChartVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? uid,
    String? authProvider,
    String? loginId,
    String? displayName,
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
      displayName: displayName ?? this.displayName,
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

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'loginId': loginId,
      'authProvider': authProvider,
      if (displayName != null) 'displayName': displayName,
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

  factory UserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      loginId: (data['loginId'] as String?) ?? '',
      authProvider: (data['authProvider'] as String?) ?? 'email',
      displayName: data['displayName'] as String?,
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
    final rawOffset = data['utcOffset'] as String?;
    // dateTimeLocal, 좌표는 필수.
    // utcOffset은 구버전 호환을 위해 null/빈 값이면 +09:00(한국 표준시) 기본값 사용.
    if (dtLocal == null || lat is! num || lng is! num) return null;
    final parsed = DateTime.tryParse(dtLocal);
    if (parsed == null) return null;
    final offset =
        (rawOffset == null || rawOffset.trim().isEmpty) ? '+09:00' : rawOffset;
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
