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
import '../domain/friend.dart'; // Friend, FriendRequest, SentRequest

class FriendRepository {
  final _db = FirebaseFirestore.instance;

  // ── 친구 코드 검색 ────────────────────────────────────────────
  Future<Map<String, dynamic>?> findUserByCode(String code) async {
    try {
      final normalizedCode = code.trim().toUpperCase();
      final codeDoc = await _db
          .collection('friendCodes')
          .doc(normalizedCode)
          .get();
      if (!codeDoc.exists) return null;
      final uid = codeDoc.data()?['uid'] as String?;
      if (uid == null) return null;
      final userDoc = await _db.collection('users').doc(uid).get();
      return userDoc.data();
    } catch (_) {
      return null;
    }
  }

  // ── 이미 친구인지 확인 ────────────────────────────────────────
  Future<bool> isAlreadyFriend(String uid1, String uid2) async {
    final pairKey = ([uid1, uid2]..sort()).join('__');
    final doc = await _db.collection('friendships').doc(pairKey).get();
    return doc.exists;
  }

  /// 이미 pending 요청이 있는지 확인 (양방향).
  ///
  /// ⚠️ pairKey 쿼리를 사용하면 안 되는 이유:
  ///   Firestore Security Rules 가 LIST 쿼리를 쿼리 조건만으로 검증하는데,
  ///   pairKey 조건으로는 "fromUid 또는 toUid == auth.uid"를 증명할 수 없어
  ///   PERMISSION_DENIED 가 발생.
  ///
  /// 해결: fromUid / toUid 를 직접 쿼리해 Rule 조건과 일치시킴.
  ///   - 방향 1: 내가 보낸 요청 (fromUid == myUid) → Rule: fromUid == auth.uid ✓
  ///   - 방향 2: 상대가 보낸 요청 (toUid == myUid) → Rule: toUid == auth.uid ✓
  ///   기존 인덱스 fromUid+status, toUid+status+createdAt 으로 충분.
  Future<bool> hasPendingRequest(String myUid, String theirUid) async {
    // 방향 1: 내가 상대에게 이미 보낸 요청
    final sent = await _db
        .collection('friendRequests')
        .where('fromUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .get();
    if (sent.docs.any((d) => d.data()['toUid'] == theirUid)) return true;

    // 방향 2: 상대가 나에게 이미 보낸 요청
    final received = await _db
        .collection('friendRequests')
        .where('toUid', isEqualTo: myUid)
        .where('status', isEqualTo: 'pending')
        .get();
    return received.docs.any((d) => d.data()['fromUid'] == theirUid);
  }

  // ── 친구 요청 전송 ────────────────────────────────────────────
  /// 전송 전 자기 자신/중복/이미 친구 여부를 검사하고 에러를 던짐.
  Future<void> sendRequest({
    required String fromUid,
    required String fromNickname,
    required String fromSunSign,
    required String toUid,
  }) async {
    if (fromUid == toUid) throw FriendError.selfAdd;

    final alreadyFriend = await isAlreadyFriend(fromUid, toUid);
    if (alreadyFriend) throw FriendError.alreadyFriend;

    final hasPending = await hasPendingRequest(fromUid, toUid);
    if (hasPending) throw FriendError.duplicateRequest;

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

  // ── 보낸 친구 요청 목록 (pending) ────────────────────────────
  /// fromUid == uid, status == pending 인 요청을 조회한다.
  /// toUid 로 users/{toUid} 를 1건씩 조회해 nickname 을 채운다.
  /// 기존 인덱스 fromUid+status 재사용.
  Future<List<SentRequest>> getSentRequests(String uid) async {
    try {
      final snap = await _db
          .collection('friendRequests')
          .where('fromUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final results = <SentRequest>[];
      for (final doc in snap.docs) {
        final toUid = doc.data()['toUid'] as String? ?? '';
        String toNickname = '';
        if (toUid.isNotEmpty) {
          final userDoc = await _db.collection('users').doc(toUid).get();
          toNickname = userDoc.data()?['nickname'] as String? ?? toUid;
        }
        results.add(SentRequest.fromMap(doc.id, doc.data(), toNickname: toNickname));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // ── 보낸 친구 요청 취소 ───────────────────────────────────────
  Future<void> cancelRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).update({
      'status': 'cancelled',
      'actedAt': FieldValue.serverTimestamp(),
    });
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

/// 친구 요청 전송 시 발생할 수 있는 도메인 에러.
enum FriendError {
  selfAdd,         // 자기 자신에게 요청
  alreadyFriend,   // 이미 친구
  duplicateRequest, // 이미 pending 요청 있음
  unknown;

  String get message {
    switch (this) {
      case FriendError.selfAdd:
        return '자기 자신은 추가할 수 없어요.';
      case FriendError.alreadyFriend:
        return '이미 친구로 등록된 사용자예요.';
      case FriendError.duplicateRequest:
        return '이미 친구 요청을 보냈어요. 상대방의 수락을 기다려주세요.';
      case FriendError.unknown:
        return '오류가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}
