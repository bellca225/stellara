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
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
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
          // chart data 가 도달했다는 건 birth 가 이미 존재한다는 의미이므로 null-fallback 은 방어 코드.
        data: (chart) => _MainHomeContent(birth: birth ?? BirthInfo.demo(), chart: chart),
        ),
      ),
    );
  }
}

class _MainHomeContent extends ConsumerWidget {
  const _MainHomeContent({required this.birth, required this.chart});

  final BirthInfo birth;
  final NatalChart chart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signLabel = zodiacLabelKo(chart.sunSign);
    final big3 = [
      '태양 ${zodiacNameKo(chart.sunSign)}',
      '달 ${zodiacNameKo(chart.moonSign)}',
      '상승 ${zodiacNameKo(chart.ascendantSign)}',
    ];

    // 즐겨찾기 친구 목록 (실데이터)
    final favoritesList = ref.watch(friendListProvider);
    final favorites = favoritesList.when(
      data: (friends) => friends.where((f) => f.isFavorite).toList(),
      loading: () => const <Friend>[],
      error: (_, __) => const <Friend>[],
    );

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

          // ── 오빗 (즐겨찾기 친구들 + 나) ──────────────────────────
          _OrbitPreview(
            favorites: favorites,
            isLoading: favoritesList.isLoading,
            onTapMe: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AstrologyScreen()),
            ),
            onTapFriend: (friend) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendScreen()),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── 친구 목록 버튼 ───────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FriendScreen()),
            ),
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

          // ── Big 3 ─────────────────────────────────────────────
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
                  children: [
                    for (final label in big3) _SignChip(label: label),
                  ],
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

// ── 오빗 위젯 (실데이터 연결) ─────────────────────────────────────────
class _OrbitPreview extends StatelessWidget {
  const _OrbitPreview({
    required this.favorites,
    required this.isLoading,
    required this.onTapMe,
    required this.onTapFriend,
  });

  final List<Friend> favorites;
  final bool isLoading;
  final VoidCallback onTapMe;
  final void Function(Friend) onTapFriend;

  /// 표시 인원 상한. 즐겨찾기 최대 3명이라 현재는 3이 최대.
  /// 향후 kMaxFavorites 변경 시 자동 반영되도록 상수로 관리.
  static const int _maxVisible = 8;

  /// uid 해시 기반 deterministic 각도 계산.
  /// 같은 uid 는 항상 같은 각도 → 새로고침해도 위치 고정.
  /// index 를 기반으로 균등 분배 후 uid 해시로 ±15° 오프셋 추가.
  static double _angleFor(String uid, int index, int total) {
    final baseAngle = 360.0 / total * index;
    // uid 해시로 -15 ~ +15 오프셋 (같은 uid면 항상 동일)
    final offset = (uid.hashCode % 30) - 15.0;
    return baseAngle + offset;
  }

  /// 친구 수에 따라 적절한 궤도 반경 비율 할당.
  static double _radiusFor(int index, int total) {
    if (total <= 3) {
      // 1~3명: r2(0.35) 와 r3(0.46) 교대 배치
      return index % 2 == 0 ? 0.35 : 0.46;
    } else if (total <= 6) {
      // 4~6명: r2, r3 교대
      return index % 2 == 0 ? 0.32 : 0.44;
    } else {
      // 7~8명: r1, r2, r3 순환
      const radii = [0.26, 0.35, 0.46];
      return radii[index % 3];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 320.0);
        final cx = size / 2;
        final cy = size / 2;

        final visible = favorites.take(_maxVisible).toList();

        // 친구 위치 계산 (deterministic)
        final dots = <_FriendDot>[];
        for (var i = 0; i < visible.length; i++) {
          final f = visible[i];
          final angle = _angleFor(f.uid, i, visible.length);
          final r = _radiusFor(i, visible.length);
          dots.add(_FriendDot(
            friend: f,
            r: r,
            angle: angle,
            size: size,
          ));
        }

        // 궤도 링 반경 (표시된 친구 수에 맞게)
        final ringRadii = visible.isEmpty
            ? [size * 0.22, size * 0.35]
            : dots.map((d) => d.r * size).toSet().toList()..sort();

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 궤도 링
                for (final r in ringRadii)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OrbitRingPainter(cx, cy, r),
                    ),
                  ),

                // 친구 행성들
                for (final dot in dots)
                  Positioned(
                    left: dot.x - dot.bubbleSize / 2,
                    top: dot.y - dot.bubbleSize / 2,
                    child: GestureDetector(
                      onTap: () => onTapFriend(dot.friend),
                      child: _OrbitFriendBubble(
                        name: dot.friend.nickname,
                        diameter: dot.bubbleSize,
                      ),
                    ),
                  ),

                // 태양 (나)
                Positioned(
                  left: cx - size * 0.07,
                  top: cy - size * 0.07,
                  child: _SunBubble(diameter: size * 0.14, onTap: onTapMe),
                ),

                // 즐겨찾기 친구 없을 때 안내
                if (!isLoading && visible.isEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: size * 0.08,
                    child: const Text(
                      '친구를 즐겨찾기하면\n여기에 나타나요 ⭐',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x88AABBFF),
                        fontSize: 11,
                        height: 1.5,
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

// ── 친구 위치 데이터 클래스 ────────────────────────────────────────────
class _FriendDot {
  final Friend friend;
  final double x, y, bubbleSize;
  final double r;

  _FriendDot({
    required this.friend,
    required this.r,
    required double angle,
    required double size,
  }) : x = size / 2 + size * r * math.cos(angle * math.pi / 180),
       y = size / 2 + size * r * math.sin(angle * math.pi / 180),
       bubbleSize = size * 0.07;
}

// ── 기존 서브 위젯 (디자인 유지) ──────────────────────────────────────

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
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.radius != radius || old.cx != cx || old.cy != cy;
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
    // 이름 최대 5자 표시 (화면 겹침 방지)
    final displayName = name.length > 5 ? '${name.substring(0, 4)}…' : name;
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
          displayName,
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
