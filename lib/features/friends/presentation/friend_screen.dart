import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';

enum _FriendTab {
  friends,
  requests,
}

class FriendScreen extends StatefulWidget {
  const FriendScreen({super.key});

  @override
  State<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  _FriendTab _selectedTab = _FriendTab.friends;

  @override
  Widget build(BuildContext context) {
    final favoriteCount = _mockFriends.where((friend) => friend.isFavorite).length;
    final friendsSelected = _selectedTab == _FriendTab.friends;

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
            const ScreenCodeChip(
              code: 'FRIEND-001',
              label: '친구 관리',
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 4),
                Text(
                  '친구 관리',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              decoration: InputDecoration(
                hintText: '아이디로 친구 검색',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.inkMuted,
                ),
                hintStyle: const TextStyle(
                  color: AppColors.inkSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _FriendTabChip(
                  label: '내 친구 (${_mockFriends.length})',
                  isSelected: friendsSelected,
                  onTap: () => setState(() => _selectedTab = _FriendTab.friends),
                ),
                _FriendTabChip(
                  label: '받은 요청 (${_mockRequests.length})',
                  isSelected: !friendsSelected,
                  onTap: () => setState(() => _selectedTab = _FriendTab.requests),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              friendsSelected ? '즐겨찾기 $favoriteCount/3' : '받은 요청 ${_mockRequests.length}건',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Panel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: friendsSelected
                    ? const _FriendListSection(key: ValueKey('friends'))
                    : const _FriendRequestSection(key: ValueKey('requests')),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.skeleton,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.ink, width: 1.2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_alt_outlined, color: AppColors.ink),
                    SizedBox(width: 8),
                    Text(
                      '친구 추가 요청',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _FriendListSection extends StatelessWidget {
  const _FriendListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _mockFriends.length; index++) ...[
          _FriendListRow(friend: _mockFriends[index]),
          if (index != _mockFriends.length - 1)
            const Divider(height: AppSpacing.xl + AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FriendRequestSection extends StatelessWidget {
  const _FriendRequestSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < _mockRequests.length; index++) ...[
          _FriendRequestRow(request: _mockRequests[index]),
          if (index != _mockRequests.length - 1)
            const Divider(height: AppSpacing.xl + AppSpacing.sm),
        ],
      ],
    );
  }
}

class _FriendListRow extends StatelessWidget {
  const _FriendListRow({
    required this.friend,
  });

  final _FriendSummary friend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InitialBadge(initial: friend.initial),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friend.name,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                friend.sign,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          friend.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
          color: friend.isFavorite ? const Color(0xFFFFB020) : AppColors.inkSubtle,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.sm),
        const SizedBox(
          width: 106,
          child: _OutlinePillButton(
            label: '궁합 보기',
          ),
        ),
      ],
    );
  }
}

class _FriendRequestRow extends StatelessWidget {
  const _FriendRequestRow({
    required this.request,
  });

  final _FriendRequestSummary request;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InitialBadge(initial: request.initial),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.sign,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.message,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Column(
          children: [
            SizedBox(
              width: 88,
              child: _SolidPillButton(
                label: '수락',
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: 88,
              child: _OutlinePillButton(
                label: '보류',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FriendTabChip extends StatelessWidget {
  const _FriendTabChip({
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.ink, width: 1.2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.paper : AppColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InitialBadge extends StatelessWidget {
  const _InitialBadge({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.paper,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line, width: 1.6),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SolidPillButton extends StatelessWidget {
  const _SolidPillButton({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.paper,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OutlinePillButton extends StatelessWidget {
  const _OutlinePillButton({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line, width: 1.4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FriendSummary {
  const _FriendSummary({
    required this.initial,
    required this.name,
    required this.sign,
    required this.isFavorite,
  });

  final String initial;
  final String name;
  final String sign;
  final bool isFavorite;
}

class _FriendRequestSummary {
  const _FriendRequestSummary({
    required this.initial,
    required this.name,
    required this.sign,
    required this.message,
  });

  final String initial;
  final String name;
  final String sign;
  final String message;
}

const _mockFriends = [
  _FriendSummary(
    initial: '김',
    name: '김민수',
    sign: '양자리',
    isFavorite: true,
  ),
  _FriendSummary(
    initial: '이',
    name: '이지은',
    sign: '천칭자리',
    isFavorite: true,
  ),
  _FriendSummary(
    initial: '박',
    name: '박서준',
    sign: '전갈자리',
    isFavorite: true,
  ),
  _FriendSummary(
    initial: '최',
    name: '최유진',
    sign: '쌍둥이자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '정',
    name: '정하늘',
    sign: '물고기자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '한',
    name: '한지민',
    sign: '염소자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '송',
    name: '송중기',
    sign: '물병자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '전',
    name: '전지현',
    sign: '쌍둥이자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '김',
    name: '김태희',
    sign: '양자리',
    isFavorite: false,
  ),
  _FriendSummary(
    initial: '현',
    name: '현빈',
    sign: '처녀자리',
    isFavorite: false,
  ),
];

const _mockRequests = [
  _FriendRequestSummary(
    initial: '박',
    name: '박하늘',
    sign: '물병자리',
    message: '나와 별자리 궁합을 보고 싶어해요.',
  ),
  _FriendRequestSummary(
    initial: '윤',
    name: '윤서',
    sign: '게자리',
    message: '친구 코드를 통해 먼저 요청을 보냈어요.',
  ),
  _FriendRequestSummary(
    initial: '정',
    name: '정하늘',
    sign: '물고기자리',
    message: '오늘의 운세와 궁합을 같이 보고 싶어해요.',
  ),
];
