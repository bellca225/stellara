// lib/features/friends/application/friend_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../users/application/user_providers.dart'; // currentUserIdProvider, currentUserProfileProvider
import '../data/friend_code_repository.dart';
import '../data/friend_repository.dart';
import '../domain/friend.dart';

/// 즐겨찾기 최대 인원. 메인 오빗 표시 및 토글 제한에 사용.
const int kMaxFavorites = 3;

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

/// 즐겨찾기된 친구만 반환. 메인 화면 오빗 표시에 사용.
/// friendListProvider 에서 isFavorite == true 인 것만 필터.
final favoriteFriendsProvider = Provider<List<Friend>>((ref) {
  final friends = ref.watch(friendListProvider).valueOrNull ?? [];
  return friends.where((f) => f.isFavorite).toList();
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

/// 내가 보낸 pending 친구 요청 목록.
///
/// 수락/거절/취소 후 `ref.invalidate(sentRequestsProvider)` 로 갱신.
final sentRequestsProvider = FutureProvider<List<SentRequest>>((ref) async {
  final uid = ref.watch(currentUserIdProvider).valueOrNull;
  if (uid == null) return [];
  return ref.watch(friendRepositoryProvider).getSentRequests(uid);
});

/// 보낸 요청 취소. 완료 후 호출 측에서 sentRequestsProvider 를 invalidate 해야 함.
final cancelRequestProvider =
    FutureProvider.family<void, String>((ref, requestId) async {
  await ref.read(friendRepositoryProvider).cancelRequest(requestId);
});

/// 즐겨찾기 토글.
///
/// ⚠️ 즐겨찾기는 최대 [kMaxFavorites]명까지만 등록 가능.
/// 초과 시 Exception 을 throw 해 화면에서 SnackBar 로 안내.
///
/// 호출 방법:
///   await ref.read(toggleFavoriteProvider(friend).future);
///   ref.invalidate(friendListProvider);
final toggleFavoriteProvider =
    FutureProvider.family<void, Friend>((ref, friend) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) throw Exception('로그인 정보를 찾을 수 없어요.');

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final currentFavorites = List<String>.from(
    doc.data()?['favoriteIds'] as List? ?? [],
  );

  final updated = List<String>.from(currentFavorites);
  if (friend.isFavorite) {
    updated.remove(friend.uid);
  } else {
    if (updated.length >= kMaxFavorites) {
      throw Exception(
        '즐겨찾기는 최대 $kMaxFavorites명까지 등록할 수 있어요.\n'
        '기존 즐겨찾기를 해제한 후 다시 시도해주세요.',
      );
    }
    if (!updated.contains(friend.uid)) updated.add(friend.uid);
  }

  await ref.read(friendRepositoryProvider).updateFavorites(uid, updated);
});
