import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../compatibility/presentation/match_screen.dart';

class FriendScreen extends StatelessWidget {
  const FriendScreen({super.key});

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
            const WireframeHeader('FRIEND-001 · 친구 관리'),
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
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '받은 요청',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _FriendRequestTile(name: '박하늘'),
                  const SizedBox(height: AppSpacing.sm),
                  const _FriendRequestTile(name: '윤서'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '친구 코드 검색',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: '친구 코드',
                      hintText: '예: AQU2024',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('친구 요청 보내기'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '친구 목록',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FriendListTile(
                    name: '박하늘',
                    sign: '물병자리',
                    onTapMatch: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MatchScreen()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FriendListTile(
                    name: '윤서',
                    sign: '게자리',
                    onTapMatch: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MatchScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('수락')),
        ],
      ),
    );
  }
}

class _FriendListTile extends StatelessWidget {
  const _FriendListTile({
    required this.name,
    required this.sign,
    required this.onTapMatch,
  });

  final String name;
  final String sign;
  final VoidCallback onTapMatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sign,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTapMatch,
            child: const Text('궁합 보기'),
          ),
        ],
      ),
    );
  }
}
