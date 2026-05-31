// lib/features/friends/data/friend_repository.dart
//
// 친구 관계 Firestore 클라이언트 wrapper.
//
// SDD T16/T17/T18/T19 기준 구현:
//   - 친구 코드 검색: friendCodes/{code} 단건 조회
//   - 친구 요청 전송: friendRequests 문서 생성
//   - 친구 요청 수락: runTransaction (friendRequests + friendships 원자적 처리)
//   - 친구 목록: friendships where uids array-contains
//   - 즐겨찾기: users/{uid}.favoriteIds 업데이트 (최대 3명)
//
// SDD 4.1 중 Cloud Functions 경로는 Blaze 전환 시 이전. 현재는 클라이언트 직접 처리.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/friend.dart';

class FriendRepository {
  final _db = FirebaseFirestore.instance;

  // ── 친구 코드 검색 ────────────────────────────────────────────
  Future<Map<String, dynamic>?> findUserByCode(String code) async {
    try {
      final codeDoc = await _db.collection('friendCodes').doc(code).get();
      if (!codeDoc.exists) return null;
      final uid = codeDoc.data()?['uid'] as String?;
      if (uid == null) return null;
      final userDoc = await _db.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (_) {
      return null;
    }
  }

  // ── 친구 요청 전송 ────────────────────────────────────────────
  /// [fromNickname], [fromSunSign] 은 UI 표시용 denormalized 스냅샷.
  Future<void> sendRequest({
    required String fromUid,
    required String fromNickname,
    required String fromSunSign,
    required String toUid,
  }) async {
    final pairKey = ([fromUid, toUid]..sort()).join('__');
    await _db.collection('friendRequests').add({
      'fromUid': fromUid,
      'fromNickname': fromNickname,
      'fromSunSign': fromSunSign,
      'toUid': toUid,
      'pairKey': pairKey,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── 받은 친구 요청 목록 ───────────────────────────────────────
  Future<List<FriendRequest>> getReceivedRequests(String uid) async {
    try {
      final snap = await _db
          .collection('friendRequests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.docs
          .map((d) => FriendRequest.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── 친구 요청 수락 ────────────────────────────────────────────
  /// SDD T18: runTransaction 으로 friendRequests.status=accepted +
  /// friendships/{pairKey} 생성을 원자적으로 처리.
  /// pairKey 문서 ID 자체가 중복 friendship 방지.
  Future<void> acceptRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    final pairKey = ([fromUid, toUid]..sort()).join('__');
    final requestRef = _db.collection('friendRequests').doc(requestId);
    final friendshipRef = _db.collection('friendships').doc(pairKey);

    await _db.runTransaction((txn) async {
      final requestSnap = await txn.get(requestRef);
      if (!requestSnap.exists) throw Exception('friendRequest not found');
      if (requestSnap.data()?['status'] != 'pending') {
        throw Exception('request already processed');
      }

      txn.update(requestRef, {
        'status': 'accepted',
        'actedAt': FieldValue.serverTimestamp(),
      });
      txn.set(friendshipRef, {
        'pairKey': pairKey,
        'uids': [fromUid, toUid]..sort(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdFromRequestId': requestId,
      });
    });
  }

  // ── 친구 요청 거절 ────────────────────────────────────────────
  Future<void> rejectRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).update({
      'status': 'rejected',
      'actedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── 친구 목록 조회 ────────────────────────────────────────────
  Future<List<Friend>> getFriends(String uid, List<String> favoriteIds) async {
    try {
      final snap = await _db
          .collection('friendships')
          .where('uids', arrayContains: uid)
          .get();

      final friends = <Friend>[];
      for (final doc in snap.docs) {
        final uids = List<String>.from(doc.data()['uids'] as List);
        final friendUid = uids.firstWhere((u) => u != uid, orElse: () => '');
        if (friendUid.isEmpty) continue;

        final userDoc = await _db.collection('users').doc(friendUid).get();
        if (!userDoc.exists) continue;
        final data = userDoc.data()!;

        friends.add(Friend(
          uid: friendUid,
          nickname: data['nickname'] as String? ?? '',
          friendCode: data['friendCode'] as String? ?? '',
          // sunSign: users/{uid} 에 denormalized 저장 (차트 생성 시 업데이트)
          sunSign: data['sunSign'] as String? ?? '-',
          isFavorite: favoriteIds.contains(friendUid),
        ));
      }
      return friends;
    } catch (_) {
      return [];
    }
  }

  // ── 즐겨찾기 업데이트 ─────────────────────────────────────────
  /// SDD 8.5: 최대 3명 제한은 Firestore Security Rules 에서 서버 강제.
  /// 클라이언트에서도 사전 검증해 UX 매끄럽게 처리.
  Future<void> updateFavorites(String uid, List<String> favoriteIds) async {
    if (favoriteIds.length > 3) {
      throw ArgumentError('즐겨찾기는 최대 3명까지 등록할 수 있어요.');
    }
    await _db.collection('users').doc(uid).update({
      'favoriteIds': favoriteIds,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
