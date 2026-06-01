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
      backgroundColor: AppColors.background,
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
  const _MainHomeContent({required this.birth, required this.chart});

  final BirthInfo birth;
  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    final signLabel = zodiacLabelKo(chart.sunSign);
    final big3 = [
      '태양 ${zodiacNameKo(chart.sunSign)}',
      '달 ${zodiacNameKo(chart.moonSign)}',
      '상승 ${zodiacNameKo(chart.ascendantSign)}',
    ];

    return StarBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text(
            '나의 우주',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            signLabel,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          _OrbitPreview(
            onTapMe: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AstrologyScreen())),
          ),
          const SizedBox(height: AppSpacing.xl),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FriendScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_alt_outlined,
                    color: AppColors.ink,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '친구 목록',
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
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('나의 Big 3', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final label in big3) _SignChip(label: label)],
                ),
                const SizedBox(height: AppSpacing.lg),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AstrologyScreen()),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2E5A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Center(
                      child: Text(
                        '상세 보기',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitPreview extends StatelessWidget {
  const _OrbitPreview({required this.onTapMe});
  final VoidCallback onTapMe;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 320.0);
        final cx = size / 2;
        final cy = size / 2;

        const r1 = 0.22;
        const r2 = 0.35;
        const r3 = 0.46;

        final friends = [
          _FriendDot(name: '박서준', r: r2, angle: 210, size: size),
          _FriendDot(name: '이지은', r: r3, angle: -40, size: size),
          _FriendDot(name: '김민수', r: r2, angle: 110, size: size),
          _FriendDot(name: '최유진', r: r3, angle: -80, size: size),
        ];

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitRingPainter(cx, cy, size * r3),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitRingPainter(cx, cy, size * r2),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OrbitRingPainter(cx, cy, size * r1),
                  ),
                ),
                for (final f in friends)
                  Positioned(
                    left: f.x - f.bubbleSize / 2,
                    top: f.y - f.bubbleSize / 2,
                    child: _OrbitFriendBubble(
                      name: f.name,
                      diameter: f.bubbleSize,
                    ),
                  ),
                Positioned(
                  left: cx - size * 0.07,
                  top: cy - size * 0.07,
                  child: _SunBubble(diameter: size * 0.14, onTap: onTapMe),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FriendDot {
  final String name;
  final double x, y, bubbleSize;
  _FriendDot({
    required this.name,
    required double r,
    required double angle,
    required double size,
  }) : x = size / 2 + size * r * math.cos(angle * math.pi / 180),
       y = size / 2 + size * r * math.sin(angle * math.pi / 180),
       bubbleSize = size * 0.07;
}

class _OrbitRingPainter extends CustomPainter {
  final double cx, cy, radius;
  _OrbitRingPainter(this.cx, this.cy, this.radius);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0x556699FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) => false;
}

class _SunBubble extends StatelessWidget {
  const _SunBubble({required this.diameter, required this.onTap});
  final double diameter;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFCC44),
          boxShadow: [
            BoxShadow(
              color: const Color(0x88FFCC44),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrbitFriendBubble extends StatelessWidget {
  const _OrbitFriendBubble({required this.name, required this.diameter});
  final String name;
  final double diameter;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: diameter,
          height: diameter,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF4A90D9),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SignChip extends StatelessWidget {
  const _SignChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2E5A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x446699FF), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
        const SkeletonBox(height: 56, radius: 999),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 150, radius: 16),
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
          '메인 화면을 불러오지 못했습니다.\n$message',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
