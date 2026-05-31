import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../auth/application/auth_providers.dart';
import '../application/friend_providers.dart';
import '../domain/friend.dart';

class FriendScreen extends ConsumerStatefulWidget {
  const FriendScreen({super.key});

  @override
  ConsumerState<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends ConsumerState<FriendScreen> {
  final _searchController = TextEditingController();

  bool _isSearching = false;
  Map<String, dynamic>? _searchResult;
  String? _searchError;

  List<Friend> _friends = [];
  List<FriendRequest> _requests = [];

  bool _loading = true;
  bool _showFriends = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    final repo = ref.read(friendRepositoryProvider);

    // Firestore에서 favoriteIds 가져오기
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final favoriteIds = List<String>.from(
      userDoc.data()?['favoriteIds'] as List? ?? [],
    );
    final friends = await repo.getFriends(user.uid, favoriteIds);
    final requests = await repo.getReceivedRequests(user.uid);

    if (mounted) {
      setState(() {
        _friends = friends;
        _requests = requests;
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    final code = _searchController.text.trim();

    if (code.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });

    final repo = ref.read(friendRepositoryProvider);

    final result = await repo.findUserByCode(code);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearching = false;

      if (result == null) {
        _searchError = '해당 코드의 사용자를 찾을 수 없어요.';
      } else {
        _searchResult = result;
      }
    });
  }

  Future<void> _sendRequest(String toUid, String toNickname) async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    final repo = ref.read(friendRepositoryProvider);

    await repo.sendRequest(
      fromUid: user.uid,
      fromNickname: user.nickname,
      fromSunSign: user.sunSign ?? '-',
      toUid: toUid,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈어요!')));

    setState(() {
      _searchResult = null;
      _searchController.clear();
    });
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    final repo = ref.read(friendRepositoryProvider);

    await repo.acceptRequest(
      requestId: request.requestId,
      fromUid: request.fromUid,
      toUid: user.uid,
    );

    await _loadData();
  }

  Future<void> _toggleFavorite(Friend friend) async {
    final user = ref.read(currentUserProvider);

    if (user == null) {
      return;
    }

    final repo = ref.read(friendRepositoryProvider);

    final favoriteIds = _friends
        .where((f) => f.isFavorite)
        .map((f) => f.uid)
        .toList();

    if (friend.isFavorite) {
      favoriteIds.remove(friend.uid);
    } else {
      if (favoriteIds.length >= 3) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('즐겨찾기는 최대 3명까지 가능해요.')));
        return;
      }

      favoriteIds.add(friend.uid);
    }

    await repo.updateFavorites(user.uid, favoriteIds);

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
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

            // 친구 검색
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
                          decoration: const InputDecoration(
                            hintText: '예: DOY001',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
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
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  if (_searchResult != null) ...[
                    const SizedBox(height: 12),

                    Builder(
                      builder: (_) {
                        final nickname =
                            _searchResult!['nickname'] as String? ?? '?';

                        return Row(
                          children: [
                            _InitialBadge(
                              initial: nickname.isNotEmpty ? nickname[0] : '?',
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                nickname,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 72,
                              child: ElevatedButton(
                                onPressed: () => _sendRequest(
                                  _searchResult!['uid'] as String,
                                  nickname,
                                ),
                                child: const Text('요청'),
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

            // 탭
            Row(
              children: [
                _TabChip(
                  label: '전체 친구 (${_friends.length})',
                  isSelected: _showFriends,
                  onTap: () {
                    setState(() {
                      _showFriends = true;
                    });
                  },
                ),

                const SizedBox(width: 8),

                _TabChip(
                  label: '받은 요청 (${_requests.length})',
                  isSelected: !_showFriends,
                  onTap: () {
                    setState(() {
                      _showFriends = false;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_showFriends)
              _friends.isEmpty
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
                          for (var i = 0; i < _friends.length; i++) ...[
                            _FriendRow(
                              friend: _friends[i],
                              onFavorite: () => _toggleFavorite(_friends[i]),
                            ),

                            if (i != _friends.length - 1)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
                    )
            else
              _requests.isEmpty
                  ? const Panel(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('받은 친구 요청이 없어요.')),
                      ),
                    )
                  : Panel(
                      child: Column(
                        children: [
                          for (var i = 0; i < _requests.length; i++) ...[
                            _RequestRow(
                              request: _requests[i],
                              onAccept: () => _acceptRequest(_requests[i]),
                            ),

                            if (i != _requests.length - 1)
                              const Divider(height: 24),
                          ],
                        ],
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.friend, required this.onFavorite});

  final Friend friend;
  final VoidCallback onFavorite;

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

              Text(
                friend.friendCode,
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onAccept});

  final FriendRequest request;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InitialBadge(initial: request.initial),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            request.fromNickname,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),

        SizedBox(
          width: 72,
          child: ElevatedButton(onPressed: onAccept, child: const Text('수락')),
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
