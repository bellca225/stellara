// lib/features/friends/application/friend_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../users/application/user_providers.dart';
import '../data/friend_code_repository.dart';
import '../data/friend_repository.dart';
import '../domain/friend.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository();
});

final friendCodeRepositoryProvider = Provider<FriendCodeRepository>(
  (ref) => FriendCodeRepository(FirebaseFirestore.instance),
);

/// 현재 사용자의 친구 목록. FRIEND-001, MAIN-001 에서 사용.
/// invalidate() 하면 Firestore 재조회.
final friendListProvider = FutureProvider<List<Friend>>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.valueOrNull;
  if (profile == null) return [];
  return ref
      .watch(friendRepositoryProvider)
      .getFriends(profile.uid, profile.favoriteIds);
});

/// 받은 친구 요청 목록.
final receivedRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.valueOrNull;
  if (profile == null) return [];
  return ref
      .watch(friendRepositoryProvider)
      .getReceivedRequests(profile.uid);
});

/// 즐겨찾기 토글. 성공 시 friendListProvider 를 invalidate 해 목록 갱신.
///
/// 호출 방법:
///   await ref.read(toggleFavoriteProvider(friend).future);
///   ref.invalidate(friendListProvider);
final toggleFavoriteProvider =
    FutureProvider.family<void, Friend>((ref, friend) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) throw Exception('로그인 정보를 찾을 수 없어요.');

  // 현재 favorites 목록을 Firestore 에서 직접 읽어 최신 상태로 토글.
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final currentFavorites = List<String>.from(
    doc.data()?['favoriteIds'] as List? ?? [],
  );

  final updated = List<String>.from(currentFavorites);
  if (friend.isFavorite) {
    updated.remove(friend.uid);
  } else {
    if (updated.length >= 3) {
      throw Exception('즐겨찾기는 최대 3명까지 가능해요.');
    }
    if (!updated.contains(friend.uid)) updated.add(friend.uid);
  }

  await ref.read(friendRepositoryProvider).updateFavorites(uid, updated);
});
