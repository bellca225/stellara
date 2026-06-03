import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_providers.dart';
import '../application/friend_providers.dart';
import '../domain/friend.dart';
import '../../compatibility/presentation/match_screen.dart';

const _svgBack = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
<path d="M9.99975 15.8329L4.16656 9.99969L9.99975 4.1665" stroke="#8EC5FF" stroke-width="1.66663" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M15.8329 9.99976H4.16656" stroke="#8EC5FF" stroke-width="1.66663" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgStarEmpty = '''
<svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9.6039 1.91249C9.64042 1.83871 9.69683 1.7766 9.76677 1.73318C9.83671 1.68976 9.9174 1.66675 9.99972 1.66675C10.082 1.66675 10.1627 1.68976 10.2327 1.73318C10.3026 1.7766 10.359 1.83871 10.3955 1.91249L12.3205 5.81156C12.4473 6.06819 12.6345 6.29022 12.866 6.45858C13.0975 6.62695 13.3664 6.73663 13.6496 6.7782L17.9545 7.40818C18.0361 7.42 18.1127 7.45441 18.1758 7.50751C18.2388 7.56062 18.2857 7.6303 18.3112 7.70868C18.3367 7.78706 18.3397 7.87101 18.32 7.95103C18.3003 8.03106 18.2585 8.10396 18.1995 8.1615L15.0863 11.1931C14.8809 11.3932 14.7273 11.6401 14.6386 11.9128C14.5499 12.1854 14.5288 12.4755 14.5771 12.758L15.3121 17.0413C15.3265 17.1228 15.3177 17.2067 15.2867 17.2835C15.2557 17.3603 15.2037 17.4268 15.1367 17.4754C15.0697 17.5241 14.9904 17.5529 14.9078 17.5587C14.8252 17.5644 14.7427 17.5468 14.6696 17.5079L10.8214 15.4846C10.5678 15.3515 10.2857 15.2819 9.99931 15.2819C9.71292 15.2819 9.43081 15.3515 9.17724 15.4846L5.32984 17.5079C5.25679 17.5466 5.17434 17.564 5.09189 17.5581C5.00944 17.5523 4.93028 17.5234 4.86343 17.4748C4.79658 17.4262 4.74472 17.3598 4.71374 17.2831C4.68276 17.2065 4.67391 17.1227 4.68819 17.0413L5.42234 12.7589C5.47083 12.4762 5.44982 12.1859 5.36112 11.9131C5.27242 11.6403 5.11869 11.3932 4.91318 11.1931L1.79993 8.16233C1.74043 8.10486 1.69826 8.03183 1.67823 7.95156C1.65821 7.8713 1.66113 7.78702 1.68666 7.70833C1.7122 7.62965 1.75932 7.55971 1.82266 7.5065C1.886 7.45329 1.96301 7.41893 2.04492 7.40735L6.34898 6.7782C6.63252 6.73695 6.90179 6.62742 7.13362 6.45903C7.36544 6.29064 7.55287 6.06844 7.67978 5.81156L9.6039 1.91249Z" stroke="#8EC5FF" stroke-width="1.66663" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgStar = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
<path d="M9.6039 1.91249C9.64042 1.83871 9.69683 1.7766 9.76677 1.73318C9.83671 1.68976 9.9174 1.66675 9.99972 1.66675C10.082 1.66675 10.1627 1.68976 10.2327 1.73318C10.3026 1.7766 10.359 1.83871 10.3955 1.91249L12.3205 5.81156C12.4473 6.06819 12.6345 6.29022 12.866 6.45858C13.0975 6.62695 13.3664 6.73663 13.6496 6.7782L17.9545 7.40818C18.0361 7.42 18.1127 7.45441 18.1758 7.50751C18.2388 7.56062 18.2857 7.6303 18.3112 7.70868C18.3367 7.78706 18.3397 7.87101 18.32 7.95103C18.3003 8.03106 18.2585 8.10396 18.1995 8.1615L15.0863 11.1931C14.8809 11.3932 14.7273 11.6401 14.6386 11.9128C14.5499 12.1854 14.5288 12.4755 14.5771 12.758L15.3121 17.0413C15.3265 17.1228 15.3177 17.2067 15.2867 17.2835C15.2557 17.3603 15.2037 17.4268 15.1367 17.4754C15.0697 17.5241 14.9904 17.5529 14.9078 17.5587C14.8252 17.5644 14.7427 17.5468 14.6696 17.5079L10.8214 15.4846C10.5678 15.3515 10.2857 15.2819 9.99931 15.2819C9.71292 15.2819 9.43081 15.3515 9.17724 15.4846L5.32984 17.5079C5.25679 17.5466 5.17434 17.564 5.09189 17.5581C5.00944 17.5523 4.93028 17.5234 4.86343 17.4748C4.79658 17.4262 4.74472 17.3598 4.71374 17.2831C4.68276 17.2065 4.67391 17.1227 4.68819 17.0413L5.42234 12.7589C5.47083 12.4762 5.44982 12.1859 5.36112 11.9131C5.27242 11.6403 5.11869 11.3932 4.91318 11.1931L1.79993 8.16233C1.74043 8.10486 1.69826 8.03183 1.67823 7.95156C1.65821 7.8713 1.66113 7.78702 1.68666 7.70833C1.7122 7.62965 1.75932 7.55971 1.82266 7.5065C1.886 7.45329 1.96301 7.41893 2.04492 7.40735L6.34898 6.7782C6.63252 6.73695 6.90179 6.62742 7.13362 6.45903C7.36544 6.29064 7.55287 6.06844 7.67978 5.81156L9.6039 1.91249Z" fill="#FDC700" stroke="#FDC700"/>
</svg>
''';

const _svgCheck = '''
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M13.3264 3.99792L5.99689 11.3275L2.66528 7.99585" stroke="white" stroke-width="1.33264" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgX = '''
<svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M11.9938 3.99792L3.99792 11.9938" stroke="white" stroke-width="1.33264" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.99792 3.99792L11.9938 11.9938" stroke="white" stroke-width="1.33264" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _glassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
  BoxShadow(color: Color(0x26FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
];

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}

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
    if (user == null) return;
    final repo = ref.read(friendRepositoryProvider);
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
    if (code.isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResult = null;
      _searchError = null;
    });
    final repo = ref.read(friendRepositoryProvider);
    final result = await repo.findUserByCode(code);
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (result == null) {
        _searchError = '해당 아이디의 사용자를 찾을 수 없어요.';
      } else {
        _searchResult = result;
      }
    });
  }

  Future<void> _sendRequest(String toUid, String toNickname) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(friendRepositoryProvider);
    try {
      await repo.sendRequest(
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _acceptRequest(FriendRequest request) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final repo = ref.read(friendRepositoryProvider);
    await repo.acceptRequest(
      requestId: request.requestId,
      fromUid: request.fromUid,
      toUid: user.uid,
    );
    await _loadData();
  }

  Future<void> _rejectRequest(FriendRequest request) async {
    final repo = ref.read(friendRepositoryProvider);
    await repo.rejectRequest(request.requestId);
    await _loadData();
  }

  Future<void> _toggleFavorite(Friend friend) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
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
    final favorites = _friends.where((f) => f.isFavorite).toList();
    final others = _friends.where((f) => !f.isFavorite).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1F), Color(0xFF0F1729), Color(0xFF1E3A8A)],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 별 배경
          ...List.generate(40, (i) {
            final x = (i * 137.5) % 100;
            final y = (i * 97.3) % 100;
            final size = (i % 3 + 1) * 0.6;
            final opacity = (i % 5 + 3) / 10;
            return Positioned(
              left: x / 100 * MediaQuery.of(context).size.width,
              top: y / 100 * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  // 헤더
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.636,
                            ),
                          ),
                          child: Center(
                            child: SvgPicture.string(
                              _svgBack,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        '친구 관리',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 32 / 24,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 검색창
                  Container(
                    height: 49,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.636,
                      ),
                      boxShadow: _glassBoxShadow,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0x808EC5FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _search(),
                            cursorColor: const Color(0xFF8EC5FF),
                            style: TextStyle(
                              color: const Color(0xFF8EC5FF).withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                            decoration: InputDecoration(
                              hintText: '아이디로 친구 검색',
                              hintStyle: TextStyle(
                                color: const Color(
                                  0xFF8EC5FF,
                                ).withOpacity(0.50),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                            ),
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (_searchError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _searchError!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  if (_searchResult != null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (_) {
                        final nickname =
                            _searchResult!['nickname'] as String? ?? '?';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B3E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                              width: 0.636,
                            ),
                            boxShadow: _glassBoxShadow,
                          ),
                          child: Row(
                            children: [
                              _InitialBadge(
                                initial: nickname.isNotEmpty
                                    ? nickname[0]
                                    : '?',
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  nickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              _AcceptButton(
                                label: '요청',
                                onTap: () => _sendRequest(
                                  _searchResult!['uid'] as String,
                                  nickname,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 탭
                  Container(
                    height: 45.26,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 0.636,
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Color(0x801E3A8A),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                        BoxShadow(
                          color: Color(0x26FFFFFF),
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabChip(
                            label: '내 친구 (${_friends.length})',
                            isSelected: _showFriends,
                            onTap: () => setState(() => _showFriends = true),
                          ),
                        ),
                        Expanded(
                          child: _TabChip(
                            label: '받은 요청 (${_requests.length})',
                            isSelected: !_showFriends,
                            onTap: () => setState(() => _showFriends = false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_showFriends) ...[
                    if (favorites.isNotEmpty) ...[
                      Text(
                        '즐겨찾기 ${favorites.length}/3',
                        style: const TextStyle(
                          color: Color(0xFF8EC5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...favorites.map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FriendCard(
                            friend: f,
                            onFavorite: () => _toggleFavorite(f),
                            onCompatibility: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MatchScreen(initialFriendUid: f.uid),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (others.isNotEmpty) const SizedBox(height: 8),
                    ],
                    ...others.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FriendCard(
                          friend: f,
                          onFavorite: () => _toggleFavorite(f),
                          onCompatibility: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchScreen(initialFriendUid: f.uid),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_friends.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '아직 친구가 없어요.\n아이디로 검색해서 요청해보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8EC5FF)),
                          ),
                        ),
                      ),
                  ] else ...[
                    if (_requests.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            '받은 친구 요청이 없어요.',
                            style: TextStyle(color: Color(0xFF8EC5FF)),
                          ),
                        ),
                      )
                    else
                      ..._requests.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RequestCard(
                            request: r,
                            onAccept: () => _acceptRequest(r),
                            onReject: () => _rejectRequest(r),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 20),

                  // 친구 추가 요청 버튼
                  GestureDetector(
                    onTap: _search,
                    child: Container(
                      height: 61,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x662B7FFF), Color(0x40155DFC)],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 0.636,
                        ),
                        boxShadow: _glassBoxShadow,
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
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onFavorite,
    required this.onCompatibility,
  });

  final Friend friend;
  final VoidCallback onFavorite;
  final VoidCallback onCompatibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.636),
        boxShadow: _glassBoxShadow,
      ),
      child: Row(
        children: [
          _InitialBadge(initial: friend.initial),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.nickname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  friend.sunSign.isNotEmpty && friend.sunSign != '-'
                      ? friend.sunSign
                      : friend.friendCode,
                  style: const TextStyle(
                    color: Color(0xFF8EC5FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onFavorite,
            child: Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: const Color(0xFF1A2B50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.636,
                ),
              ),
              child: Center(
                child: friend.isFavorite
                    ? SvgPicture.string(_svgStar, width: 20, height: 20)
                    : SvgPicture.string(_svgStarEmpty, width: 20, height: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCompatibility,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2B50),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 0.636,
                ),
              ),
              child: const Text(
                '궁합 보기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
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
    final timeAgo = _timeAgo(request.createdAt);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.636),
        boxShadow: _glassBoxShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _InitialBadge(
                initial: request.initial.isNotEmpty ? request.initial : '?',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fromNickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 24 / 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (request.fromSunSign != null &&
                        request.fromSunSign!.isNotEmpty &&
                        request.fromSunSign != '-')
                      Text(
                        request.fromSunSign!,
                        style: const TextStyle(
                          color: Color(0xFF8EC5FF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                  ],
                ),
              ),
              if (timeAgo.isNotEmpty)
                Text(
                  timeAgo,
                  style: const TextStyle(
                    color: Color(0xFF51A2FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    letterSpacing: -0.2,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AcceptButton(label: '✓ 수락', onTap: onAccept),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RejectButton(label: '✕ 거절', onTap: onReject),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 37,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x662B7FFF), Color(0x40155DFC)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.636,
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_svgCheck, width: 16, height: 16),
            const SizedBox(width: 4),
            const Text(
              '수락',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RejectButton extends StatelessWidget {
  const _RejectButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 37,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 0.636,
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_svgX, width: 16, height: 16),
            const SizedBox(width: 4),
            const Text(
              '거절',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        alignment: Alignment.center,
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
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.60),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            height: 20 / 14,
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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
