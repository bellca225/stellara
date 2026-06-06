// lib/features/friends/presentation/friend_screen.dart
//
// 친구 관리 화면 — Figma 친구관리1/2 구조 기준
//
// 친구관리1: 내 친구 탭 — 친구 목록 + 즐겨찾기 카운트 + 궁합 보기
// 친구관리2: 받은 요청 탭 — 요청 카드 + 시간 표시 + 수락/거절
// 친구 추가: 하단 "친구 추가 요청" 버튼 → AddFriendScreen (별도 파일)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../compatibility/presentation/match_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/friend_providers.dart';
import '../domain/friend.dart';
import 'add_friend_screen.dart';

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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    // 검색창
                    _SearchField(
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
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
                              onTap: () =>
                                  setState(() => _tab = _FriendTab.received),
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
        // ── 하단 친구 추가 버튼 ──────────────────────────────────
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 0, 24, 16),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: _glassCardDecoration(radius: 24),
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
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                if (friend.sunSign.isNotEmpty && friend.sunSign != '-')
                  Text(
                    friend.sunSign,
                    style: const TextStyle(
                      color: Color(0xFF8EC5FF),
                      fontSize: 14,
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
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          _GlassPillButton(label: '궁합 보기', onTap: onMatch),
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
      decoration: _glassCardDecoration(radius: 24),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (request.fromSunSign.isNotEmpty &&
                        request.fromSunSign != '-')
                      Text(
                        request.fromSunSign,
                        style: const TextStyle(
                          color: Color(0xFF8EC5FF),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (request.createdAt != null)
                Text(
                  _timeAgo(request.createdAt!),
                  style: const TextStyle(
                    color: Color(0xFF51A2FF),
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlassActionButton(
                  label: '수락',
                  icon: Icons.check,
                  primary: true,
                  onTap: onAccept,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GlassActionButton(
                  label: '거절',
                  icon: Icons.close,
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
        height: 36,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x4D2B7FFF), Color(0x4D155DFC)],
                )
              : null,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0x99FFFFFF),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            letterSpacing: -0.2,
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
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x4D3B82F6), blurRadius: 7.5)],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: -0.2,
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
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
            ),
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.636),
            boxShadow: kGlassShadow,
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

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  // StatefulWidget으로 전환해 TextEditingController를 안정적으로 유지한다.
  // 부모의 setState()로 _SearchField가 rebuild되더라도 controller 인스턴스가
  // 바뀌지 않으므로 Chrome Web + 한글 IME 조합 중 텍스트 상태가 desync되지 않는다.
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.636),
        boxShadow: _glassBoxShadow,
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Color(0x808EC5FF), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
              cursorColor: const Color(0xFF8EC5FF),
              decoration: const InputDecoration(
                hintText: '아이디로 친구 검색',
                hintStyle: TextStyle(
                  color: Color(0x808EC5FF),
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
      decoration: _glassCardDecoration(radius: 24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFB0C4DE),
          height: 1.5,
          fontSize: 14,
        ),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x1AFFFFFF), width: 0.636),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0x4D2B7FFF), Color(0x4D155DFC)],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.636),
            boxShadow: _glassBoxShadow,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
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
    required this.icon,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          height: 37,
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
            border: Border.all(color: const Color(0x26FFFFFF), width: 0.636),
            boxShadow: _glassBoxShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inHours < 1) return '${diff.inMinutes}분 전';
  if (diff.inDays < 1) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return '${diff.inDays ~/ 7}주 전';
}

enum _FriendTab { friends, received }
