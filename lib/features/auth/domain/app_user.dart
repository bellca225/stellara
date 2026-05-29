class AppUser {
  const AppUser({
    required this.uid,
    required this.nickname,
    required this.friendCode,
    required this.profileCompleted,
    required this.authProvider,
  });

  final String uid;
  final String nickname;
  final String friendCode;
  final bool profileCompleted;
  final String authProvider;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      nickname: map['nickname'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      authProvider: map['authProvider'] as String? ?? 'dev',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nickname': nickname,
      'friendCode': friendCode,
      'profileCompleted': profileCompleted,
      'authProvider': authProvider,
    };
  }
}