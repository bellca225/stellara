// lib/features/users/application/user_providers.dart
//
// users 도메인의 Riverpod Provider 정의.
//
// 가드 정책:
//   - Firebase 가 init 되지 않은 환경(Web/iOS 또는 init 실패)에서는
//     [currentUserIdProvider] 가 null stream 을 emit 해 화면이 안전하게 빈 상태가 된다.
//   - 따라서 화면은 `ref.watch(currentUserProfileProvider).valueOrNull`
//     형태로 null-safe 하게 사용하면 된다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../data/user_repository.dart';
import '../domain/user_profile.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  if (!FirebaseBootstrap.isReady) {
    throw StateError(
      'FirebaseBootstrap 가 ready 가 아닙니다. '
      'firestoreProvider 는 이 가드 통과 후에만 read 되어야 합니다.',
    );
  }
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(firestoreProvider)),
);

/// 현재 anonymous 로그인 사용자의 uid. Firebase 가 ready 가 아니면 null stream.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  if (!FirebaseBootstrap.isReady) {
    return Stream.value(null);
  }
  return FirebaseAuth.instance.authStateChanges().map((u) => u?.uid);
});

/// 현재 사용자 프로필 stream. Firestore 의 users/{uid} 를 구독.
///
/// 화면은 `ref.watch(currentUserProfileProvider).when(...)` 로 사용.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uidAsync = ref.watch(currentUserIdProvider);
  return uidAsync.when(
    data: (uid) {
      if (uid == null) return Stream.value(null);
      if (!FirebaseBootstrap.isReady) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watch(uid);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
