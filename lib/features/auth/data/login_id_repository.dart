// lib/features/auth/data/login_id_repository.dart
//
// loginIds/{loginId} 컬렉션 wrapper.
//
// 역할:
//   - 아이디 중복 여부 확인
//   - 아이디 → UID 역방향 조회 (로그인 시 Firebase 이메일 복원)
//   - 아이디 형식 검증
//
// Firebase Auth 전략:
//   실제 이메일 없이 아이디/비밀번호 로그인을 지원하기 위해
//   "{loginId}@stellara.internal" 형태의 가상 이메일로 Auth 계정을 생성.
//   사용자는 아이디/비밀번호만 알면 되고, 이메일은 내부에서만 사용.

import 'package:cloud_firestore/cloud_firestore.dart';

class LoginIdRepository {
  LoginIdRepository(this._db);
  final FirebaseFirestore _db;

  /// 가상 이메일 변환. Firebase Auth 에 등록할 식별자.
  static String toEmail(String loginId) =>
      '${loginId.toLowerCase().trim()}@stellara.internal';

  /// 아이디 형식 검증.
  /// 규칙: 4~20자, 영문 소문자·숫자·언더스코어만 허용, 숫자로 시작 불가.
  static String? validate(String loginId) {
    final id = loginId.trim();
    if (id.length < 4) return '아이디는 4자 이상이어야 해요.';
    if (id.length > 20) return '아이디는 20자 이하여야 해요.';
    if (!RegExp(r'^[a-z_][a-z0-9_]*$').hasMatch(id)) {
      return '영문 소문자, 숫자, _만 사용 가능하고 숫자로 시작할 수 없어요.';
    }
    return null; // 유효
  }

  /// 아이디 사용 가능 여부 확인. true = 사용 가능.
  Future<bool> isAvailable(String loginId) async {
    final doc = await _db
        .collection('loginIds')
        .doc(loginId.toLowerCase().trim())
        .get();
    return !doc.exists;
  }

  /// loginId → uid 조회. 로그인 시 uid 확인용.
  Future<String?> getUid(String loginId) async {
    final doc = await _db
        .collection('loginIds')
        .doc(loginId.toLowerCase().trim())
        .get();
    return doc.data()?['uid'] as String?;
  }

  /// 아이디 등록. users/{uid} 생성과 같은 트랜잭션에서 호출.
  Future<void> register(Transaction txn, String loginId, String uid) async {
    final ref = _db.collection('loginIds').doc(loginId.toLowerCase().trim());
    txn.set(ref, {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
