import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../astrology/presentation/astrology_screen.dart';
import '../../friends/presentation/friend_screen.dart';

class MainHomeScreen extends ConsumerWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);

    return Scaffold(
      body: SafeArea(
        child: asyncChart.when(
          loading: () => const _MainHomeSkeleton(),
          error: (error, _) => _MainHomeError(message: '$error'),
          data: (chart) => _MainHomeContent(birth: birth, chart: chart),
        ),
      ),
    );
  }
}

class _MainHomeContent extends StatelessWidget {
  const _MainHomeContent({
    required this.birth,
    required this.chart,
  });

  final BirthInfo birth;
  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    final signLabel = zodiacLabelKo(chart.sunSign);
    final big3 = [
      ('태양', chart.sunSign),
      ('달', chart.moonSign),
      ('상승', chart.ascendantSign),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        const ScreenCodeChip(
          code: 'MAIN-001',
          label: '메인 홈',
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '나의 우주',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 26,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          signLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _OrbitPreview(
          nickname: birth.nickname,
          onTapMe: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AstrologyScreen()),
          ),
          onTapFriend: null,
        ),
        const SizedBox(height: AppSpacing.xl),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const FriendScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
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
                  '친구',
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
        const SizedBox(height: AppSpacing.lg),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '나의 Big 3',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final item in big3)
                    _SignChip(label: '${item.$1}: ${zodiacNameKo(item.$2)}'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AstrologyScreen()),
                ),
                child: const Center(
                  child: Text(
                    '상세 보기',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrbitPreview extends StatelessWidget {
  const _OrbitPreview({
    required this.nickname,
    required this.onTapMe,
    required this.onTapFriend,
  });

  final String nickname;
  final VoidCallback onTapMe;
  final VoidCallback? onTapFriend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 340.0);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  left: size * 0.28,
                  top: size * 0.34,
                  child: _OrbitBubble(
                    diameter: size * 0.28,
                    label: '나',
                    onTap: onTapMe,
                  ),
                ),
                Positioned(
                  left: size * 0.52,
                  top: size * 0.40,
                  child: _OrbitBubble(
                    diameter: size * 0.22,
                    label: '박',
                    onTap: onTapFriend,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: size * 0.12,
                  child: Text(
                    '${firstLetter(nickname)}의 가까운 궤도',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrbitBubble extends StatelessWidget {
  const _OrbitBubble({
    required this.diameter,
    required this.label,
    required this.onTap,
  });

  final double diameter;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final bubble = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.paper : AppColors.canvas,
        shape: BoxShape.circle,
        border: Border.all(
          color: isEnabled ? AppColors.inkSubtle : AppColors.line,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isEnabled ? AppColors.ink : AppColors.inkMuted,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!isEnabled) {
      return bubble;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(diameter / 2),
        child: bubble,
      ),
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
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

class _MainHomeSkeleton extends StatelessWidget {
  const _MainHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(width: 180, height: 18),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonBox(width: double.infinity, height: 24),
        const SizedBox(height: AppSpacing.sm),
        const SkeletonBox(width: 120, height: 16),
        const SizedBox(height: AppSpacing.xl),
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.skeleton,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 62, radius: 999),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 170, radius: 16),
      ],
    );
  }
}

class _MainHomeError extends StatelessWidget {
  const _MainHomeError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '메인 홈을 불러오지 못했어요.\n$message',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
