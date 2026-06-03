// lib/features/friends/presentation/friend_screen.dart
//
// 친구 관리 화면 — Figma 친구관리1/2/3 구조 기준
//
// 친구관리1: 내 친구 탭 — 친구 목록 + 즐겨찾기 카운트 + 궁합 보기
// 친구관리2: 받은 요청 탭 — 요청 카드 + 시간 표시 + 수락/거절
// 친구 추가: 하단 "친구 추가 요청" 버튼 → AddFriendScreen (별도 파일)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../compatibility/presentation/match_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../data/friend_repository.dart';
import '../domain/friend.dart';
import 'add_friend_screen.dart';

class FriendScreen extends ConsumerStatefulWidget {
  const FriendScreen({super.key});

  @override
  ConsumerState<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends ConsumerState<FriendScreen> {
  _FriendTab _tab = _FriendTab.friends;

  // 친구 목록 로컬 필터용 검색어
  String _searchQuery = '';

  // ── 친구 요청 수락 ──────────────────────────────────────────────
  Future<void> _acceptRequest(FriendRequest request) async {
    final uid = ref.read(currentUserProfileProvider).valueOrNull?.uid
        ?? ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) return;

    try {
      await ref.read(friendRepositoryProvider).acceptRequest(
        requestId: request.requestId,
        fromUid: request.fromUid,
        toUid: uid,
      );
      ref.invalidate(friendListProvider);
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('친구가 되었어요!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수락에 실패했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  // ── 친구 요청 거절 ──────────────────────────────────────────────
  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await ref.read(friendRepositoryProvider).rejectRequest(request.requestId);
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('요청을 거절했어요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거절에 실패했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  // ── 즐겨찾기 토글 ──────────────────────────────────────────────
  Future<void> _toggleFavorite(Friend friend) async {
    try {
      await ref.read(toggleFavoriteProvider(friend).future);
      ref.invalidate(friendListProvider);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final requestsAsync = ref.watch(receivedRequestsProvider);

    final allFriends = friendsAsync.valueOrNull ?? <Friend>[];
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;

    // 검색 필터 적용
    final filteredFriends = _searchQuery.isEmpty
        ? allFriends
        : allFriends
            .where((f) => f.nickname.contains(_searchQuery))
            .toList();

    final favoriteCount = allFriends.where((f) => f.isFavorite).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 관리'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── 검색바 ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              decoration: InputDecoration(
                hintText: _tab == _FriendTab.friends
                    ? '친구 검색'
                    : '아이디로 친구 검색',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),

          // ── 탭 ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: '내 친구 (${allFriends.length})',
                    isSelected: _tab == _FriendTab.friends,
                    onTap: () => setState(() => _tab = _FriendTab.friends),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TabButton(
                    label: '받은 요청 ($requestCount)',
                    isSelected: _tab == _FriendTab.received,
                    onTap: () => setState(() => _tab = _FriendTab.received),
                  ),
                ),
              ],
            ),
          ),

          // ── 콘텐츠 영역 ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_tab == _FriendTab.friends) ...[
                  // 즐겨찾기 카운터
                  if (allFriends.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '즐겨찾기 $favoriteCount/$kMaxFavorites',
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // 친구 목록
                  friendsAsync.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '데이터를 불러오지 못했어요.\n(${e.toString().split('\n').first})',
                        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                      ),
                    ),
                    data: (_) => filteredFriends.isEmpty
                        ? Panel(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? '검색 결과가 없어요.'
                                      : '아직 친구가 없어요.\n아래 버튼을 눌러 친구를 추가해보세요!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.inkMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Panel(
                            child: Column(
                              children: [
                                for (var i = 0; i < filteredFriends.length; i++) ...[
                                  _FriendRow(
                                    friend: filteredFriends[i],
                                    onFavorite: () =>
                                        _toggleFavorite(filteredFriends[i]),
                                    onMatch: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => MatchScreen(
                                          initialFriendUid:
                                              filteredFriends[i].uid,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (i != filteredFriends.length - 1)
                                    const Divider(height: 1),
                                ],
                              ],
                            ),
                          ),
                  ),
                ] else ...[
                  // ── 받은 요청 탭 ──────────────────────────────
                  requestsAsync.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '데이터를 불러오지 못했어요.\n(${e.toString().split('\n').first})',
                        style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
                      ),
                    ),
                    data: (requests) => requests.isEmpty
                        ? const Panel(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('받은 친구 요청이 없어요.'),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final req in requests)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
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

      // ── 친구 추가 요청 버튼 (하단 고정) ──────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddFriendScreen()),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('친구 추가 요청'),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.onFavorite,
    required this.onMatch,
  });

  final Friend friend;
  final VoidCallback onFavorite;
  final VoidCallback onMatch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _InitialAvatar(initial: friend.initial),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.nickname,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (friend.sunSign.isNotEmpty && friend.sunSign != '-')
                  Text(
                    friend.sunSign,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              friend.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: friend.isFavorite
                  ? const Color(0xFFFFB020)
                  : AppColors.inkSubtle,
            ),
          ),
          OutlinedButton(
            onPressed: onMatch,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('궁합 보기'),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InitialAvatar(initial: request.initial),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fromNickname,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (request.fromSunSign.isNotEmpty &&
                        request.fromSunSign != '-')
                      Text(
                        request.fromSunSign,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // 시간 표시 (X시간 전 / X일 전)
              if (request.createdAt != null)
                Text(
                  _timeAgo(request.createdAt!),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  child: const Text('✓ 수락'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('✕ 거절'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Material + InkWell 조합은 Web에서 mouse_tracker assertion 유발
    // GestureDetector(HitTestBehavior.opaque) 사용 — mouse region 생성 없음
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.paper : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.canvas,
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Text(
        initial,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

/// 상대 시간 표시 (예: "2시간 전", "1일 전")
String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${diff.inDays ~/ 7}주 전';
}

enum _FriendTab { friends, received }
