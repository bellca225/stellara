// lib/features/friends/domain/friend.dart
//
// 친구 관계 도메인 모델.
//
// SDD 8.3 스키마 기준:
//   - sunSign 은 users/{uid} 에 denormalized 저장 (출생 차트 생성 시 업데이트)
//   - friendRequests 의 fromNickname 은 UI 표시용 denormalized 필드 (실용적 확장)

class Friend {
  const Friend({
    required this.uid,
    required this.nickname,
    required this.friendCode,
    required this.sunSign,
    required this.isFavorite,
  });

  final String uid;
  final String nickname;
  final String friendCode;

  /// 태양 별자리. users/{uid}.sunSign (denormalized). 차트 미생성 시 '-'.
  final String sunSign;
  final bool isFavorite;

  String get initial => nickname.isNotEmpty ? nickname[0] : '?';
}

/// 받은 친구 요청.
class FriendRequest {
  const FriendRequest({
    required this.requestId,
    required this.fromUid,
    required this.fromNickname,
    required this.fromSunSign,
    required this.status,
    this.createdAt,
  });

  final String requestId;
  final String fromUid;

  /// 요청 전송 시 denormalized 저장 (users/{fromUid}.nickname 스냅샷).
  final String fromNickname;

  /// 요청 전송 시 denormalized 저장 (users/{fromUid}.sunSign 스냅샷).
  final String fromSunSign;

  final String status;
  final DateTime? createdAt;

  String get initial => fromNickname.isNotEmpty ? fromNickname[0] : '?';

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    return FriendRequest(
      requestId: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromNickname: map['fromNickname'] as String? ?? '',
      fromSunSign: map['fromSunSign'] as String? ?? '-',
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }
}

/// 내가 보낸 친구 요청 (pending 상태).
class SentRequest {
  const SentRequest({
    required this.requestId,
    required this.toUid,
    required this.toNickname,
    required this.status,
    this.createdAt,
  });

  final String requestId;
  final String toUid;

  /// friendRequests.toUid 기준 역조회한 닉네임 (users/{toUid}.nickname).
  final String toNickname;

  final String status;
  final DateTime? createdAt;

  String get initial => toNickname.isNotEmpty ? toNickname[0] : '?';

  factory SentRequest.fromMap(
    String id,
    Map<String, dynamic> map, {
    String toNickname = '',
  }) {
    return SentRequest(
      requestId: id,
      toUid: map['toUid'] as String? ?? '',
      toNickname: toNickname,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }
}
