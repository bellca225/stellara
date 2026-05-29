class Friend {
  const Friend({
    required this.uid,
    required this.nickname,
    required this.friendCode,
    required this.sign,
    required this.isFavorite,
  });

  final String uid;
  final String nickname;
  final String friendCode;
  final String sign;
  final bool isFavorite;

  String get initial => nickname.isNotEmpty ? nickname[0] : '?';

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      uid: map['uid'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      friendCode: map['friendCode'] as String? ?? '',
      sign: map['sign'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.requestId,
    required this.fromUid,
    required this.fromNickname,
    required this.fromSign,
    required this.status,
  });

  final String requestId;
  final String fromUid;
  final String fromNickname;
  final String fromSign;
  final String status;

  String get initial => fromNickname.isNotEmpty ? fromNickname[0] : '?';

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      requestId: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromNickname: map['fromNickname'] as String? ?? '',
      fromSign: map['fromSign'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}
