import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../auth/application/auth_providers.dart';
import '../../compatibility/presentation/match_screen.dart';
import '../application/friend_providers.dart';
import '../data/friend_repository.dart';
import '../domain/friend.dart';

class FriendScreen extends ConsumerStatefulWidget {
  const FriendScreen({super.key});

  @override
  ConsumerState<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends ConsumerState<FriendScreen> {
  final _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isSendingRequest = false;
  Map<String, dynamic>? _searchResult;
  String? _searchError;
  bool _showFriends = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── 친구 코드 검색 ──────────────────────────────────────────────
  Future<void> _search() async {
    final code = _searchController.text.trim();
    if (code.isEmpty) return;

    final myUid = ref.read(currentUserProvider)?.uid;

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });

    try {
      final result = await ref
          .read(friendRepositoryProvider)
          .findUserByCode(code);

      if (!mounted) return;

      if (result == null) {
        setState(() => _searchError = '해당 코드의 사용자를 찾을 수 없어요.');
        return;
      }

      // 자기 자신 방지
      if (result['uid'] == myUid) {
        setState(() => _searchError = '자기 자신은 추가할 수 없어요.');
        return;
      }

      setState(() => _searchResult = result);
    } catch (_) {
      if (mounted) setState(() => _searchError = '검색 중 오류가 발생했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ── 친구 요청 전송 ──────────────────────────────────────────────
  Future<void> _sendRequest(String toUid, String toNickname) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSendingRequest = true);

    try {
      await ref
          .read(friendRepositoryProvider)
          .sendRequest(
            fromUid: user.uid,
            fromNickname: user.nickname,
            fromSunSign: user.sunSign ?? '-',
            toUid: toUid,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈어요!')));
      setState(() {
        _searchResult = null;
        _searchController.clear();
      });
    } on FriendError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e, st) {
      // 실제 에러를 개발 로그에 출력해 디버깅에 활용
      if (kDebugMode) {
        debugPrint('[FriendScreen] sendRequest 실패: $e\n$st');
      }
      if (mounted) {
        // Firestore 에러 메시지에서 원인을 추출해 사용자에게 표시
        final msg = _friendlyError(e.toString());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isSendingRequest = false);
    }
  }

  // ── 친구 요청 수락 ──────────────────────────────────────────────
  Future<void> _acceptRequest(FriendRequest request) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await ref
          .read(friendRepositoryProvider)
          .acceptRequest(
            requestId: request.requestId,
            fromUid: request.fromUid,
            toUid: user.uid,
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
      await ref
          .read(friendRepositoryProvider)
          .rejectRequest(request.requestId);
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

  // ── 즐겨찾기 토글 ───────────────────────────────────────────────
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

  // Firestore/Firebase 에러 메시지를 사용자 친화적 문구로 변환
  String _friendlyError(String raw) {
    if (raw.contains('PERMISSION_DENIED') ||
        raw.contains('permission-denied')) {
      return '권한이 없어요. 로그아웃 후 다시 로그인해주세요.';
    }
    if (raw.contains('FAILED_PRECONDITION') ||
        raw.contains('requires an index')) {
      return '서버 설정 중이에요. 잠시 후 다시 시도해주세요.';
    }
    if (raw.contains('NOT_FOUND') || raw.contains('not-found')) {
      return '존재하지 않는 사용자예요.';
    }
    if (raw.contains('UNAVAILABLE') || raw.contains('network')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '요청 전송에 실패했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final requestsAsync = ref.watch(receivedRequestsProvider);

    final friendCount = friendsAsync.valueOrNull?.length ?? 0;
    final requestCount = requestsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const ScreenCodeChip(code: 'FRIEND-001', label: '친구 관리'),
            const SizedBox(height: AppSpacing.lg),
            Text('친구 관리', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            // ── 친구 코드 검색 ──────────────────────────────────
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '친구 코드로 검색',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          keyboardType: TextInputType.visiblePassword,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          inputFormatters: <TextInputFormatter>[
                            FriendCodeTextFormatter(),
                          ],
                          decoration: const InputDecoration(
                            hintText: '예: KAG6BC',
                            helperText:
                                '영문/숫자 코드만 입력 가능해요. 대소문자 구분 없이 검색돼요.',
                            counterText: '',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                          onSubmitted: (_) => _search(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _search,
                          child: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('검색'),
                        ),
                      ),
                    ],
                  ),

                  if (_searchError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _searchError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  if (_searchResult != null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (_) {
                        final nickname =
                            _searchResult!['nickname'] as String? ?? '?';
                        final toUid = _searchResult!['uid'] as String? ?? '';
                        final sunSign = _searchResult!['sunSign'] as String?;
                        return Row(
                          children: [
                            _InitialBadge(
                              initial: nickname.isNotEmpty ? nickname[0] : '?',
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nickname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (sunSign != null)
                                    Text(
                                      sunSign,
                                      style: const TextStyle(
                                        color: AppColors.inkMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              child: ElevatedButton(
                                onPressed: _isSendingRequest
                                    ? null
                                    : () => _sendRequest(toUid, nickname),
                                child: _isSendingRequest
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('요청'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── 탭 ─────────────────────────────────────────────
            Row(
              children: [
                _TabChip(
                  label: '전체 친구 ($friendCount)',
                  isSelected: _showFriends,
                  onTap: () => setState(() => _showFriends = true),
                ),
                const SizedBox(width: 8),
                _TabChip(
                  label: '받은 요청 ($requestCount)',
                  isSelected: !_showFriends,
                  onTap: () => setState(() => _showFriends = false),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── 친구 목록 ───────────────────────────────────────
            if (_showFriends)
              friendsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('친구 목록을 불러오지 못했어요: $e'),
                  ),
                ),
                data: (friends) => friends.isEmpty
                    ? const Panel(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              '아직 친구가 없어요.\n코드로 검색해서 요청해보세요!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : Panel(
                        child: Column(
                          children: [
                            for (var i = 0; i < friends.length; i++) ...[
                              _FriendRow(
                                friend: friends[i],
                                onFavorite: () => _toggleFavorite(friends[i]),
                                onMatch: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MatchScreen(
                                      initialFriendUid: friends[i].uid,
                                    ),
                                  ),
                                ),
                              ),
                              if (i != friends.length - 1)
                                const Divider(height: 24),
                            ],
                          ],
                        ),
                      ),
              )
            else
              requestsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Panel(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('요청 목록을 불러오지 못했어요: $e'),
                  ),
                ),
                data: (requests) => requests.isEmpty
                    ? const Panel(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('받은 친구 요청이 없어요.')),
                        ),
                      )
                    : Panel(
                        child: Column(
                          children: [
                            for (var i = 0; i < requests.length; i++) ...[
                              _RequestRow(
                                request: requests[i],
                                onAccept: () => _acceptRequest(requests[i]),
                                onReject: () => _rejectRequest(requests[i]),
                              ),
                              if (i != requests.length - 1)
                                const Divider(height: 24),
                            ],
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 서브 위젯 ───────────────────────────────────────────────────────

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
    return Row(
      children: [
        _InitialBadge(initial: friend.initial),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.nickname,
                style: const TextStyle(fontWeight: FontWeight.w800),
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
            friend.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
            color: friend.isFavorite
                ? const Color(0xFFFFB020)
                : AppColors.inkSubtle,
          ),
        ),
        SizedBox(
          width: 72,
          child: OutlinedButton(
            onPressed: onMatch,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontSize: 13),
            ),
            child: const Text('궁합'),
          ),
        ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _InitialBadge(initial: request.initial),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.fromNickname,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
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

class _InitialBadge extends StatelessWidget {
  const _InitialBadge({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line, width: 1.6),
      ),
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
