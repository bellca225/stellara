// lib/features/friends/application/friend_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final friendListProvider = FutureProvider<List<Friend>>((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.valueOrNull;
  if (profile == null) return [];
  return ref
      .watch(friendRepositoryProvider)
      .getFriends(profile.uid, profile.favoriteIds);
});

/// 받은 친구 요청 목록.
final receivedRequestsProvider = FutureProvider((ref) async {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.valueOrNull;
  if (profile == null) return [];
  return ref
      .watch(friendRepositoryProvider)
      .getReceivedRequests(profile.uid);
});
