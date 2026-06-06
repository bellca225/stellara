import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/glass.dart';
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
      backgroundColor: Colors.transparent,
      body: StarBackground(
        child: SafeArea(
          child: asyncChart.when(
            loading: () => const _MainHomeSkeleton(),
            error: (error, _) => _MainHomeError(message: '$error'),
            data: (chart) => _MainHomeContent(
              birth: birth ?? BirthInfo.demo(),
              chart: chart,
            ),
          ),
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

    final favoritesList = ref.watch(friendListProvider);
    final favorites = favoritesList.when(
      data: (friends) => friends.where((f) => f.isFavorite).toList(),
      loading: () => const <Friend>[],
      error: (_, __) => const <Friend>[],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        140,
      ),
      children: [
        const SizedBox(height: 35),
        Text(
          '나의 우주',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 35),
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
          favorites: favorites,
          isLoading: favoritesList.isLoading,
          onTapMe: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AstrologyScreen())),
          onTapFriend: (friend) => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FriendScreen())),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SizedBox(height: 15),

        // ── 친구 목록 버튼 ──
        GlassButton(
          label: '친구 목록',
          isPrimary: true,
          height: 56,
          leading: const Icon(
            Icons.people_alt_outlined,
            color: AppColors.ink,
            size: 20,
          ),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FriendScreen())),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Big 3 카드 ──
        GlassPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Big 3',
                style: TextStyle(
                  color: Color(0xFF8EC5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.428,
                ),
              ),
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
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0x26FFFFFF),
                      width: 0.636,
                    ),
                    boxShadow: kGlassShadow,
                  ),
                  child: const Center(
                    child: Text(
                      '상세 보기',
                      style: TextStyle(
                        color: Color(0xFFBEDBFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

class _OrbitPreview extends StatefulWidget {
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

  @override
  State<_OrbitPreview> createState() => _OrbitPreviewState();
}

class _OrbitPreviewState extends State<_OrbitPreview>
    with SingleTickerProviderStateMixin {
  static const int _maxVisible = 8;
  static const _speedMultipliers = [
    1.0,
    0.55,
    0.35,
    0.75,
    0.45,
    0.65,
    0.28,
    0.85,
  ];

  late final AnimationController _controller;

  static double _baseAngleFor(String uid, int index, int total) {
    final baseAngle = 360.0 / total * index;
    final offset = (uid.hashCode % 30) - 15.0;
    return baseAngle + offset;
  }

  static double _radiusFor(int index, int total) {
    const minRadius = 0.22;
    const maxRadius = 0.46;
    if (total <= 1) return (minRadius + maxRadius) / 2;
    return minRadius + (maxRadius - minRadius) / (total - 1) * index;
  }

  static double _speedFor(int index) =>
      _speedMultipliers[index % _speedMultipliers.length];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 360.0);
        final cx = size / 2;
        final cy = size / 2;
        final visible = widget.favorites.take(_maxVisible).toList();

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            final friendRadii = visible.isEmpty
                ? const <double>[]
                : List.generate(
                    visible.length,
                    (i) => _radiusFor(i, visible.length) * size,
                  );
            final ringRadii = friendRadii.isEmpty
                ? [size * 0.22, size * 0.35]
                : friendRadii;
            final maxRadius = friendRadii.isEmpty
                ? size * 0.35
                : friendRadii.last;

            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final r in ringRadii)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OrbitRingPainter(
                            cx: cx,
                            cy: cy,
                            radius: r,
                            maxRadius: maxRadius,
                          ),
                        ),
                      ),
                    for (var i = 0; i < visible.length; i++)
                      _buildFriendBubble(
                        friend: visible[i],
                        index: i,
                        total: visible.length,
                        size: size,
                        t: t,
                      ),
                    Positioned(
                      left: cx - size * 0.07,
                      top: cy - size * 0.07,
                      child: _SunBubble(
                        diameter: size * 0.14,
                        onTap: widget.onTapMe,
                      ),
                    ),
                    if (!widget.isLoading && visible.isEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: size * 0.08,
                        child: const Text(
                          '친구를 즐겨찾기하면\n여기에 표시돼요',
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
      },
    );
  }

  Widget _buildFriendBubble({
    required Friend friend,
    required int index,
    required int total,
    required double size,
    required double t,
  }) {
    final radius = _radiusFor(index, total);
    final speed = _speedFor(index);
    final baseAngle = _baseAngleFor(friend.uid, index, total) * math.pi / 180;
    final angle = baseAngle + t * speed;
    final bubbleSize = size * 0.08;
    final x = size / 2 + size * radius * math.cos(angle) - bubbleSize / 2;
    final y = size / 2 + size * radius * math.sin(angle) - bubbleSize / 2;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => widget.onTapFriend(friend),
        child: _OrbitFriendBubble(name: friend.nickname, diameter: bubbleSize),
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  const _OrbitRingPainter({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.maxRadius,
  });

  final double cx;
  final double cy;
  final double radius;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final ratio = maxRadius > 0 ? (radius / maxRadius) : 1.0;
    final opacity = (0.55 - ratio * 0.35).clamp(0.12, 0.55).toDouble();
    final strokeWidth = (1.6 - ratio * 0.8).clamp(0.6, 1.6).toDouble();
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Color.fromRGBO(102, 153, 255, opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_OrbitRingPainter old) =>
      old.radius != radius ||
      old.maxRadius != maxRadius ||
      old.cx != cx ||
      old.cy != cy;
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
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFCC44),
          boxShadow: [
            BoxShadow(
              color: Color(0x88FFCC44),
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
            boxShadow: [
              BoxShadow(
                color: Color(0x664A90D9),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayName,
          style: const TextStyle(
            color: Color(0xAAFFFFFF),
            fontSize: 9,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
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
      padding: const EdgeInsets.fromLTRB(13, 7, 13, 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x06FFFFFF), Color(0x03FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1EFFFFFF), width: 0.636),
        boxShadow: kGlassShadow,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 12,
          fontWeight: FontWeight.w300,
          letterSpacing: -0.2,
          height: 1.333,
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        140,
      ),
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
          '홈 화면을 불러올 수 없습니다\n$message',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
