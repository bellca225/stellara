// lib/features/auth/domain/app_user.dart
//
// 로그인/세션 컨텍스트에서 쓰는 경량 사용자 모델.
// 상세 프로필(출생정보 등)은 UserProfile(users/{uid})에서 관리한다.
//
// [loginId]  : 로그인 전용 식별자. 화면에 노출하지 않음.
// [displayName]: 사용자가 온보딩에서 입력한 표시 이름. 화면 전반 노출.
// [nickname] : 기존 호환 필드. displayName 미존재 시 fallback.

class AppUser {
  const AppUser({
    required this.uid,
    required this.loginId,
    required this.nickname,
    required this.friendCode,
    required this.profileCompleted,
    required this.authProvider,
    this.displayName,
    this.sunSign,
  });

  final String uid;

  /// 서비스용 로그인 아이디. loginIds/{loginId} 컬렉션으로 중복 방지.
  /// 로그인 외의 화면에는 노출하지 않음.
  final String loginId;

  /// UI 표시용 이름. 온보딩 이름 step 에서 사용자가 직접 입력.
  /// null 이면 [nickname] → [loginId] 순으로 fallback.
  final String? displayName;

  /// 기존 호환 필드. [displayName] 미존재 시 표시 이름으로 사용.
  final String nickname;

  final String friendCode;
  final bool profileCompleted;

  /// "email" | "anonymous" | "dev"
  final String authProvider;

  /// 나탈 차트 생성 후 charts/{uid}.sunSign 에서 채워짐. 미생성 시 null.
  final String? sunSign;

  /// 화면 전반에서 사용할 표시 이름.
  /// displayName → nickname → loginId 순으로 우선순위 적용.
  String get effectiveDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (nickname.trim().isNotEmpty) return nickname;
    return loginId;
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      loginId: map['loginId'] as String? ?? '',
      displayName: map['displayName'] as String?,
      nickname: map['nickname'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      authProvider: map['authProvider'] as String? ?? 'email',
      sunSign: map['sunSign'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'loginId': loginId,
      if (displayName != null) 'displayName': displayName,
      'nickname': nickname,
      'friendCode': friendCode,
      'profileCompleted': profileCompleted,
      'authProvider': authProvider,
      if (sunSign != null) 'sunSign': sunSign,
    };
  }

  AppUser copyWith({
    String? loginId,
    String? displayName,
    String? nickname,
    String? friendCode,
    bool? profileCompleted,
    String? sunSign,
  }) {
    return AppUser(
      uid: uid,
      loginId: loginId ?? this.loginId,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      friendCode: friendCode ?? this.friendCode,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      authProvider: authProvider,
      sunSign: sunSign ?? this.sunSign,
    );
  }
}
