// lib/features/auth/domain/app_user.dart
//
// 로그인/세션 컨텍스트에서 쓰는 경량 사용자 모델.
// 상세 프로필(출생정보 등)은 UserProfile(users/{uid})에서 관리한다.

class AppUser {
  const AppUser({
    required this.uid,
    required this.nickname,
    required this.friendCode,
    required this.profileCompleted,
    required this.authProvider,
    this.sunSign,
  });

  final String uid;
  final String nickname;
  final String friendCode;
  final bool profileCompleted;

  /// "anonymous" | "dev"
  final String authProvider;

  /// 나탈 차트 생성 후 charts/{uid}.sunSign 에서 채워짐. 미생성 시 null.
  final String? sunSign;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      authProvider: map['authProvider'] as String? ?? 'anonymous',
      sunSign: map['sunSign'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'friendCode': friendCode,
      'profileCompleted': profileCompleted,
      'authProvider': authProvider,
      if (sunSign != null) 'sunSign': sunSign,
    };
  }

  AppUser copyWith({
    String? nickname,
    String? friendCode,
    bool? profileCompleted,
    String? sunSign,
  }) {
    return AppUser(
      uid: uid,
      nickname: nickname ?? this.nickname,
      friendCode: friendCode ?? this.friendCode,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      authProvider: authProvider,
      sunSign: sunSign ?? this.sunSign,
    );
  }
}
