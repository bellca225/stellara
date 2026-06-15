// lib/features/friends/presentation/friend_screen.dart
//
// 친구 관리 화면 — Figma 친구관리1/2 구조 기준
//
// 친구관리1: 내 친구 탭 — 친구 목록 + 즐겨찾기 카운트 + 궁합 보기
// 친구관리2: 받은 요청 탭 — 요청 카드 + 시간 표시 + 수락/거절
// 친구 추가: 하단 "친구 추가 요청" 버튼 → AddFriendScreen (별도 파일)

import 'package:flutter/material.dart';

import '../../../core/ui/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../compatibility/presentation/match_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../domain/friend.dart';
import 'add_friend_screen.dart';

part 'friend_screen_widgets.dart';

// ── 공통 글래스 스타일 ─────────────────────────────────────────────
// 표준 글라스 그림자(검정 2단)로 통일. 파란 글로우 제거.
const _glassBoxShadow = kGlassShadow;

BoxDecoration _glassCardDecoration({double radius = 24}) => BoxDecoration(
  gradient: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
  ),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: const Color(0x1FFFFFFF), width: 0.636),
  boxShadow: _glassBoxShadow,
);

class FriendScreen extends ConsumerStatefulWidget {
  const FriendScreen({super.key});

  @override
  ConsumerState<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends ConsumerState<FriendScreen> {
  _FriendTab _tab = _FriendTab.friends;
  String _searchQuery = '';

  Future<void> _acceptRequest(FriendRequest request) async {
    final uid =
        ref.read(currentUserProfileProvider).valueOrNull?.uid ??
        ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) return;

    try {
      await ref
          .read(friendRepositoryProvider)
          .acceptRequest(
            requestId: request.requestId,
            fromUid: request.fromUid,
            toUid: uid,
          );
      ref.invalidate(friendListProvider);
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        showGlassToast(context, '친구가 되었어요!');
      }
    } catch (_) {
      if (mounted) {
        showGlassToast(
          context,
          '수락에 실패했어요. 다시 시도해주세요.',
          type: GlassToastType.error,
        );
      }
    }
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await ref.read(friendRepositoryProvider).rejectRequest(request.requestId);
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        showGlassToast(context, '요청을 거절했어요.');
      }
    } catch (_) {
      if (mounted) {
        showGlassToast(
          context,
          '거절에 실패했어요. 다시 시도해주세요.',
          type: GlassToastType.error,
        );
      }
    }
  }

  Future<void> _toggleFavorite(Friend friend) async {
    try {
      await ref.read(toggleFavoriteProvider(friend).future);
      ref.invalidate(friendListProvider);
    } on Exception catch (e) {
      if (mounted) {
        showGlassToast(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: GlassToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final requestsAsync = ref.watch(receivedRequestsProvider);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.padding.bottom;
    // 키보드 인셋과 무관하게 버튼을 화면 하단에 고정한다.
    // (검색 시 키보드가 올라와도 버튼이 위로 따라 올라가지 않도록)
    final actionBottomOffset = bottomInset + 16;
    final listBottomPadding = 24 + 61 + 16 + bottomInset;

    final allFriends = friendsAsync.valueOrNull ?? <Friend>[];
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;
    final allRequests = requestsAsync.valueOrNull ?? <FriendRequest>[];

    final filteredFriends = _searchQuery.isEmpty
        ? allFriends
        : allFriends.where((f) => f.nickname.contains(_searchQuery)).toList();
    final filteredRequests = _searchQuery.isEmpty
        ? allRequests
        : allRequests
              .where((r) => r.fromNickname.contains(_searchQuery))
              .toList();

    final favoriteCount = allFriends.where((f) => f.isFavorite).length;

    return StarBackground(
      child: Scaffold(
        extendBody: true,
        // 키보드가 올라와도 Stack 레이아웃이 리사이즈되지 않도록 고정.
        // 하단 고정 버튼의 위치가 키보드에 영향받지 않게 한다.
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── 헤더만 고정 ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        _RoundBackButton(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            Navigator.of(context).maybePop();
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '친구 관리',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── 검색창 + 탭 + 리스트 모두 스크롤 ──────────────
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        listBottomPadding.toDouble(),
                      ),
                      children: [
                        // 검색창
                        _SearchField(
                          onChanged: (v) =>
                              setState(() => _searchQuery = v.trim()),
                        ),
                        const SizedBox(height: 16),
                        // 탭
                        Container(
                          padding: const EdgeInsets.all(4.634),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0x1FFFFFFF),
                              width: 0.636,
                            ),
                            boxShadow: _glassBoxShadow,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _TabButton(
                                  label: '내 친구 (${allFriends.length})',
                                  isSelected: _tab == _FriendTab.friends,
                                  onTap: () =>
                                      setState(() => _tab = _FriendTab.friends),
                                ),
                              ),
                              Expanded(
                                child: _TabButton(
                                  label: '받은 요청 ($requestCount)',
                                  isSelected: _tab == _FriendTab.received,
                                  onTap: () => setState(
                                    () => _tab = _FriendTab.received,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── 친구 탭 ──────────────────────────────────
                        if (_tab == _FriendTab.friends) ...[
                          if (allFriends.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '즐겨찾기 $favoriteCount/$kMaxFavorites',
                                style: const TextStyle(
                                  color: Color(0xFFB0C4DE),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          friendsAsync.when(
                            loading: () => const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => _EmptyStateCard(
                              message:
                                  '데이터를 불러오지 못했어요.\n(${e.toString().split('\n').first})',
                            ),
                            data: (_) => filteredFriends.isEmpty
                                ? _EmptyStateCard(
                                    message: _searchQuery.isNotEmpty
                                        ? '검색 결과가 없어요.'
                                        : '아직 친구가 없어요.\n아래 버튼을 눌러 친구를 추가해보세요!',
                                  )
                                : Column(
                                    children: [
                                      for (final friend in filteredFriends)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _FriendRow(
                                            friend: friend,
                                            onFavorite: () =>
                                                _toggleFavorite(friend),
                                            onMatch: () =>
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => MatchScreen(
                                                      initialFriendUid:
                                                          friend.uid,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ] else ...[
                          // ── 받은 요청 탭 ──────────────────────────
                          requestsAsync.when(
                            loading: () => const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => _EmptyStateCard(
                              message:
                                  '데이터를 불러오지 못했어요.\n(${e.toString().split('\n').first})',
                            ),
                            data: (_) => filteredRequests.isEmpty
                                ? _EmptyStateCard(
                                    message: _searchQuery.isNotEmpty
                                        ? '검색 결과가 없어요.'
                                        : '받은 친구 요청이 없어요.',
                                  )
                                : Column(
                                    children: [
                                      for (final req in filteredRequests)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: _RequestCard(
                                            request: req,
                                            onAccept: () => _acceptRequest(req),
                                            onReject: () => _rejectRequest(req),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: actionBottomOffset,
              child: SizedBox(
                height: 61,
                child: GlassButton(
                  label: '친구 추가 요청',
                  isPrimary: true,
                  height: 61,
                  leading: const Icon(
                    Icons.person_add_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
