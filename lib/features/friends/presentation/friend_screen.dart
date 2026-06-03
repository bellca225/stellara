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
import '../../compatibility/presentation/match_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../domain/friend.dart';
import 'add_friend_screen.dart';

const _glassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
  BoxShadow(color: Color(0x26FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
];

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('친구가 되었어요!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('수락에 실패했어요. 다시 시도해주세요.')));
      }
    }
  }

  // ── 친구 요청 거절 ──────────────────────────────────────────────
  Future<void> _rejectRequest(FriendRequest request) async {
    try {
      await ref.read(friendRepositoryProvider).rejectRequest(request.requestId);
      ref.invalidate(receivedRequestsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('요청을 거절했어요.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('거절에 실패했어요. 다시 시도해주세요.')));
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
    final allRequests = requestsAsync.valueOrNull ?? <FriendRequest>[];

    // 검색 필터 적용
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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _RoundBackButton(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      '친구 관리',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _SearchField(
                  hintText: _tab == _FriendTab.friends ? '친구 검색' : '받은 요청 검색',
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
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
                          onTap: () =>
                              setState(() => _tab = _FriendTab.received),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if (_tab == _FriendTab.friends) ...[
                      if (allFriends.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '즐겨찾기 $favoriteCount/$kMaxFavorites',
                            style: const TextStyle(
                              color: AppColors.inkMuted,
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
                                                  initialFriendUid: friend.uid,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ] else ...[
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
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x662B7FFF), Color(0x40155DFC)],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 0.636,
              ),
              boxShadow: _glassBoxShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddFriendScreen()),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '친구 추가 요청',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xCC10224A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.636,
        ),
        boxShadow: _glassBoxShadow,
      ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (friend.sunSign.isNotEmpty && friend.sunSign != '-')
                  Text(
                    friend.sunSign,
                    style: const TextStyle(
                      color: Color(0xFF8EC5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          _CircleActionButton(
            onTap: onFavorite,
            child: Icon(
              friend.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: friend.isFavorite
                  ? const Color(0xFFFDC700)
                  : const Color(0xFF8EC5FF),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          _GlassPillButton(
            label: '궁합 보기',
            onTap: onMatch,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xCC10224A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.636,
        ),
        boxShadow: _glassBoxShadow,
      ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    if (request.fromSunSign.isNotEmpty &&
                        request.fromSunSign != '-')
                      Text(
                        request.fromSunSign,
                        style: const TextStyle(
                          color: Color(0xFF8EC5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                    color: Color(0xFF51A2FF),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlassActionButton(
                  label: '✓ 수락',
                  primary: true,
                  onTap: onAccept,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GlassActionButton(
                  label: '✕ 거절',
                  primary: false,
                  onTap: onReject,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF2B7FFF), Color(0xFF155DFC)],
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.inkMuted,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.636,
            ),
            boxShadow: _glassBoxShadow,
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF8EC5FF),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hintText, required this.onChanged});

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.636,
        ),
        boxShadow: _glassBoxShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0x808EC5FF), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFF8EC5FF),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xCC8EC5FF),
                  fontSize: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xCC10224A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.636,
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.inkMuted, height: 1.5),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0x8020335E),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.636,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({
    required this.label,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  });

  final String label;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.636,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  const _GlassActionButton({
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: primary
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x662B7FFF), Color(0x40155DFC)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                  ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.636,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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
