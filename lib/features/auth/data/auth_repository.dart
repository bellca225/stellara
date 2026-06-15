// lib/features/auth/data/auth_repository.dart
//
// 인증 전략: Firebase Email/Password Auth (가상 이메일)
//
// 흐름:
//   회원가입: loginId → "{loginId}@stellara.internal" 가상 이메일로 Auth 계정 생성
//   로그인: loginId → 가상 이메일로 변환 → Firebase signInWithEmailAndPassword
//   세션 복원: Firebase.currentUser 존재 → Firestore에서 AppUser 로드
//
// 왜 가상 이메일인가:
//   Firebase Auth 는 이메일 기반만 지원. 실제 이메일 없이 아이디/비밀번호 로그인을
//   지원하기 위해 "{loginId}@stellara.internal" 형태의 내부 이메일을 사용.
//   사용자에게는 노출되지 않으며, loginId만 기억하면 됨.

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/app_user.dart';
import 'login_id_repository.dart';

class AuthRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _loginIdRepo = LoginIdRepository(FirebaseFirestore.instance);

  // ── 회원가입 ────────────────────────────────────────────────────
  /// 아이디/비밀번호로 신규 계정을 생성한다.
  ///
  /// 저장 흐름 (원자성 보장):
  ///   ① 아이디 중복 확인
  ///   ② Firebase Auth 계정 생성
  ///   ③ runTransaction: users/{uid} + loginIds/{loginId} + friendCodes/{code} 동시 생성
  ///
  /// Firebase Auth 생성 성공 후 Firestore 저장 실패 시:
  ///   - Auth 계정을 삭제해 불완전 상태 방지 (롤백)
  Future<AppUser> signUp({
    required String loginId,
    required String password,
    String? displayName,
  }) async {
    final id = loginId.toLowerCase().trim();

    // ① 아이디 중복 확인
    final available = await _loginIdRepo.isAvailable(id);
    if (!available) throw AuthError.loginIdTaken;

    // ② Firebase Auth 계정 생성
    final email = LoginIdRepository.toEmail(id);
    late UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }

    final uid = cred.user!.uid;

    // ③ Firestore 원자적 저장 (실패 시 Auth 롤백)
    try {
      // 충돌이 없는 친구 코드를 찾을 때까지 재시도 (최대 5회)
      String friendCode = _generateFriendCode();
      for (var attempt = 0; attempt < 5; attempt++) {
        final snap = await _db.collection('friendCodes').doc(friendCode).get();
        if (!snap.exists) break;
        friendCode = _generateFriendCode();
      }

      await _db.runTransaction((txn) async {
        final userRef = _db.collection('users').doc(uid);
        final loginIdRef = _db.collection('loginIds').doc(id);
        final codeRef = _db.collection('friendCodes').doc(friendCode);

        // 트랜잭션 안에서 쓰기 전 read 먼저
        final codeSnap = await txn.get(codeRef);
        await txn.get(userRef);
        await txn.get(loginIdRef);

        // 코드 충돌 최종 방어 — 트랜잭션 내에서도 확인
        if (codeSnap.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'friend-code-conflict',
            message: '친구 코드가 이미 사용 중이에요. 다시 시도해주세요.',
          );
        }

        final now = FieldValue.serverTimestamp();
        txn.set(userRef, {
          'uid': uid,
          'loginId': id,
          // displayName: 온보딩 이름 step 에서 입력. 회원가입 시점엔 미입력.
          if (displayName != null && displayName.trim().isNotEmpty)
            'displayName': displayName.trim(),
          'nickname': id, // 기존 호환 유지. displayName 이 없으면 nickname fallback
          'friendCode': friendCode,
          'profileCompleted': false,
          'authProvider': 'email',
          'createdAt': now,
          'updatedAt': now,
        });
        txn.set(loginIdRef, {
          'uid': uid,
          'createdAt': now,
        });
        txn.set(codeRef, {
          'uid': uid,
          'createdAt': now,
        });
      });

      return AppUser(
        uid: uid,
        loginId: id,
        displayName: displayName?.trim().isNotEmpty == true ? displayName!.trim() : null,
        nickname: id,
        friendCode: friendCode,
        profileCompleted: false,
        authProvider: 'email',
      );
    } catch (e, st) {
      // Firestore 저장 실패 → Auth 계정 롤백
      debugPrint('[AuthRepository] signUp Firestore 트랜잭션 실패: $e\n$st');
      await cred.user?.delete();
      rethrow;
    }
  }

  // ── 로그인 ──────────────────────────────────────────────────────
  /// 아이디 + 비밀번호로 로그인.
  Future<AppUser> signInWithId({
    required String loginId,
    required String password,
  }) async {
    final id = loginId.toLowerCase().trim();
    final email = LoginIdRepository.toEmail(id);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = await getUser(cred.user!.uid);
      if (user == null) throw AuthError.userNotFound;
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    }
  }

  // ── 세션 복원 ───────────────────────────────────────────────────
  /// 앱 재시작 시 호출. Firebase 세션이 살아있으면 Firestore 에서 유저 로드.
  Future<AppUser?> restoreSession() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;
      return await getUser(firebaseUser.uid);
    } catch (_) {
      return null;
    }
  }

  // ── 공통 ────────────────────────────────────────────────────────
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── 헬퍼 ────────────────────────────────────────────────────────
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// 암호학적으로 안전한 Random 을 사용해 6자리 친구 코드를 생성한다.
  /// 이전 타임스탬프 기반 알고리즘은 동일 기기에서 동일 코드를 생성하는 버그가 있었음.
  String _generateFriendCode() {
    final rng = Random.secure();
    return List.generate(6, (_) => _codeChars[rng.nextInt(_codeChars.length)]).join();
  }

  AuthError _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return AuthError.loginIdTaken;
      case 'weak-password':
        return AuthError.weakPassword;
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return AuthError.invalidCredential;
      case 'too-many-requests':
        return AuthError.tooManyRequests;
      default:
        return AuthError.unknown;
    }
  }
}

// ── 에러 타입 ─────────────────────────────────────────────────────
enum AuthError implements Exception {
  loginIdTaken,
  weakPassword,
  invalidCredential,
  tooManyRequests,
  userNotFound,
  unknown;

  String get message {
    switch (this) {
      case AuthError.loginIdTaken:
        return '이미 사용 중인 아이디예요.';
      case AuthError.weakPassword:
        return '비밀번호는 6자 이상으로 설정해주세요.';
      case AuthError.invalidCredential:
        return '아이디 또는 비밀번호가 올바르지 않아요.';
      case AuthError.tooManyRequests:
        return '시도 횟수를 초과했어요. 잠시 후 다시 시도해주세요.';
      case AuthError.userNotFound:
        return '계정 정보를 찾을 수 없어요.';
      case AuthError.unknown:
        return '오류가 발생했어요. 잠시 후 다시 시도해주세요.';
    }
  }
}
