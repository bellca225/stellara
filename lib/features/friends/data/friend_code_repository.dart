// lib/features/friends/data/friend_code_repository.dart
//
// 친구 코드 발급 (T16).
//
// 흐름:
//   issue(uid) 호출
//     → 6자리 코드 랜덤 생성
//     → 충돌 검사 (friendCodes/{code} 존재 여부)
//     → runTransaction: friendCodes/{code} 생성 + users/{uid}.friendCode 갱신

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendCodeRepository {
  FriendCodeRepository(this._firestore);
  final FirebaseFirestore _firestore;

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외
  static const _maxRetry = 5;

  /// 새 친구 코드를 발급하고 반환한다.
  ///
  /// 이미 friendCode 가 있는 사용자라도 재발급 가능 (마이페이지 재생성 시).
  /// 충돌이 [_maxRetry] 회 초과하면 예외를 던진다.
  Future<String> issue(String uid) async {
    for (var i = 0; i < _maxRetry; i++) {
      final code = _generate();
      final codeRef = _firestore.collection('friendCodes').doc(code);
      final userRef = _firestore.collection('users').doc(uid);

      try {
        await _firestore.runTransaction((txn) async {
          // 트랜잭션 안에서 쓰기 전에 반드시 read 먼저 수행해야 함.
          final codeSnap = await txn.get(codeRef);
          await txn.get(userRef); // userRef 도 read 해야 update 허용됨

          if (codeSnap.exists) throw _CodeConflict(); // 이미 사용 중 → 재시도

          txn.set(codeRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          txn.update(userRef, {
            'friendCode': code,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          });
        });
        return code; // 성공
      } on _CodeConflict {
        continue; // 충돌 → 다음 코드 시도
      }
    }
    throw Exception('친구 코드 발급 실패: $_maxRetry 회 충돌. 잠시 후 다시 시도해 주세요.');
  }

  String _generate() {
    final rng = Random.secure();
    return List.generate(6, (_) => _chars[rng.nextInt(_chars.length)]).join();
  }
}

class _CodeConflict implements Exception {}
