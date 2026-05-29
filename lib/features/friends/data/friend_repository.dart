import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/friend.dart';

class FriendRepository {
  final _db = FirebaseFirestore.instance;

  // 친구 코드로 사용자 검색
  Future<Map<String, dynamic>?> findUserByCode(String code) async {
    try {
      final doc = await _db.collection('friendCodes').doc(code).get();
      if (!doc.exists) return null;
      final uid = doc.data()?['uid'] as String?;
      if (uid == null) return null;
      final userDoc = await _db.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (e) {
      return null;
    }
  }

  // 친구 요청 보내기
  Future<void> sendRequest({
    required String fromUid,
    required String fromNickname,
    required String toUid,
  }) async {
    final pairKey = [fromUid, toUid]..sort();
    await _db.collection('friendRequests').add({
      'fromUid': fromUid,
      'fromNickname': fromNickname,
      'toUid': toUid,
      'pairKey': pairKey.join('__'),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 받은 친구 요청 목록
  Future<List<FriendRequest>> getReceivedRequests(String uid) async {
    try {
      final snapshot = await _db
          .collection('friendRequests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs
          .map((doc) => FriendRequest.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // 친구 요청 수락
  Future<void> acceptRequest({
    required String requestId,
    required String fromUid,
    required String toUid,
  }) async {
    final pairKey = [fromUid, toUid]..sort();
    final batch = _db.batch();

    final requestRef = _db.collection('friendRequests').doc(requestId);
    batch.update(requestRef, {'status': 'accepted'});

    final friendshipRef = _db.collection('friendships').doc(pairKey.join('__'));
    batch.set(friendshipRef, {
      'pairKey': pairKey.join('__'),
      'uids': pairKey,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // 친구 목록 조회
  Future<List<Friend>> getFriends(String uid, List<String> favoriteIds) async {
    try {
      final snapshot = await _db
          .collection('friendships')
          .where('uids', arrayContains: uid)
          .get();

      final friends = <Friend>[];
      for (final doc in snapshot.docs) {
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
          sign: data['sign'] as String? ?? '',
          isFavorite: favoriteIds.contains(friendUid),
        ));
      }
      return friends;
    } catch (e) {
      return [];
    }
  }

  // 즐겨찾기 업데이트
  Future<void> updateFavorites(String uid, List<String> favoriteIds) async {
    await _db.collection('users').doc(uid).update({
      'favoriteIds': favoriteIds,
    });
  }
}