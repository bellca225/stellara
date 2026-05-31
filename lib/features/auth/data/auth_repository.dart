// lib/features/auth/data/auth_repository.dart
//
// 인증 전략: Firebase Anonymous Auth + flutter_secure_storage 재설치 감지
//
// 흐름:
//   앱 시작
//     → Firebase.currentUser 존재 → Firestore에서 AppUser 로드
//     → 없으면 signInAnonymously() → UID를 SecureStorage에 저장
//     → 재설치 감지: 저장된 UID ≠ 신규 UID → 이전 계정과 연결 끊김 안내
//
// 왜 Anonymous Auth인가:
//   - 별도 가입 불필요, 앱 첫 실행 즉시 UID 발급
//   - Firestore Security Rules에서 request.auth.uid 기반 데이터 격리
//   - 추후 카카오/Google OAuth로 linkWithCredential 전환 시 uid 유지 가능
//   - refreshToken은 앱 재시작 시 자동 복원(Firebase SDK 기본 동작)
//   - 재설치 후 UID 변경은 SecureStorage UID 비교로 감지해 사용자에게 안내

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _kLastUid = 'stellara_last_uid';

  /// 앱 시작 시 호출. 기존 세션 복원 또는 신규 anonymous 로그인.
  Future<({AppUser? user, bool wasReinstalled})> signInOrRestore() async {
    try {
      User? firebaseUser = _auth.currentUser;

      // 이미 Firebase 세션 있으면 바로 사용
      if (firebaseUser == null) {
        final cred = await _auth.signInAnonymously();
        firebaseUser = cred.user!;
      }

      // 재설치 감지: 이전 UID와 비교
      final storedUid = await _storage.read(key: _kLastUid);
      final wasReinstalled =
          storedUid != null && storedUid != firebaseUser.uid;

      // 현재 UID 저장 (재설치 감지용)
      await _storage.write(key: _kLastUid, value: firebaseUser.uid);

      final user = await _loadOrCreateUser(firebaseUser);
      return (user: user, wasReinstalled: wasReinstalled);
    } catch (_) {
      return (user: null, wasReinstalled: false);
    }
  }

  /// Firestore에서 사용자 로드. 신규 사용자면 최소 문서 생성.
  Future<AppUser?> _loadOrCreateUser(User firebaseUser) async {
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap(doc.data()!);
    }

    // 신규 사용자 - 최소 문서 생성 (출생정보는 온보딩에서 채움)
    final newUser = AppUser(
      uid: firebaseUser.uid,
      nickname: '별자리 유저',
      friendCode: '',
      profileCompleted: false,
      authProvider: 'anonymous',
    );
    await _db
        .collection('users')
        .doc(firebaseUser.uid)
        .set(newUser.toMap(), SetOptions(merge: true));
    return newUser;
  }

  /// uid로 Firestore 사용자 조회.
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  /// 로그아웃 — anonymous session 종료. 다음 앱 실행 시 새 UID 발급.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 개발/데모용 — Firestore에 시딩된 테스트 사용자로 진입.
  Future<AppUser?> devLogin(String uid) async {
    return getUser(uid) ??
        AppUser(
          uid: uid,
          nickname: '테스트 유저',
          friendCode: 'DEV001',
          profileCompleted: false,
          authProvider: 'dev',
        );
  }
}
