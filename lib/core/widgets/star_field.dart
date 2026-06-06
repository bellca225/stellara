import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 투명 배경 위에 별을 그리는 애니메이션 위젯.
///
/// 배경 그라데이션 등 위에 겹쳐 쓰도록 설계되었다. (자체 배경은 그리지 않음)
/// 성능을 위해 RepaintBoundary로 격리되어, 별 애니메이션이 상위 트리를
/// 다시 그리지 않는다.
class StarField extends StatefulWidget {
  const StarField({super.key});

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(); // 이음매 없는 무한 트윙클 (정수 배속으로 루프 끊김 없음)
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _StarFieldPainter(_ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Star {
  final double x, y, r, base, speed, phase;
  final int tint; // 0=흰색, 1=차가운 블루, 2=따뜻한 톤
  final bool bright; // 글로우 부여
  final bool hero; // 십자 반짝임 부여
  const _Star(this.x, this.y, this.r, this.base, this.speed, this.phase,
      this.tint, this.bright, this.hero);
}

class _StarFieldPainter extends CustomPainter {
  final double t;
  _StarFieldPainter(this.t);

  // 틴트 색상 (은은하게)
  static const List<Color> _tints = [
    Color(0xFFFFFFFF), // 흰색
    Color(0xFFCFE0FF), // 차가운 블루
    Color(0xFFFFEFD2), // 따뜻한 톤
  ];

  static const int _count = 320;
  static const int _brightFrom = 296; // 296~319: 밝은 별 (글로우)
  static const int _heroFrom = 312; // 312~319: 가장 밝은 별 (십자 반짝임)

  static final List<_Star> _stars = () {
    final rng = math.Random(42);
    return List.generate(_count, (i) {
      final bright = i >= _brightFrom;
      final hero = i >= _heroFrom;
      final r = bright
          ? rng.nextDouble() * 0.9 + 1.0
          : rng.nextDouble() * 0.7 + 0.35;
      final base = bright
          ? rng.nextDouble() * 0.35 + 0.65
          : rng.nextDouble() * 0.5 + 0.18;
      final speed = (rng.nextInt(3) + 1).toDouble(); // 1~3 (정수 → 무한루프 연속)
      final phase = rng.nextDouble();
      final tr = rng.nextDouble();
      final tint = tr < 0.72 ? 0 : (tr < 0.92 ? 1 : 2);
      return _Star(rng.nextDouble(), rng.nextDouble(), r, base, speed, phase,
          tint, bright, hero);
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    const tau = math.pi * 2;
    // 재사용 Paint (별마다 색/blur만 갱신)
    final core = Paint();
    final glow = Paint();
    final spark = Paint()
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    for (final s in _stars) {
      final x = s.x * size.width;
      final y = s.y * size.height;

      // 부드러운 트윙클: smoothstep 이징으로 자연스러운 깜빡임
      final tw = 0.5 + 0.5 * math.sin(tau * (s.speed * t + s.phase));
      final eased = tw * tw * (3 - 2 * tw);
      final alpha = (s.base * (0.25 + 0.75 * eased)).clamp(0.0, 1.0);
      final color = _tints[s.tint];
      final center = Offset(x, y);

      if (s.bright) {
        // 은은한 글로우 (밝은 별에만 → 성능 안전)
        final pulse = 1.0 + 0.12 * eased; // 미세한 호흡
        glow
          ..color = color.withOpacity(alpha * 0.20)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s.r * 1.6);
        canvas.drawCircle(center, s.r * 1.7 * pulse, glow);

        if (s.hero) {
          // 가장 밝은 별: 아주 은은한 십자 반짝임
          final len = s.r * (2.0 + 1.2 * eased);
          spark.color = color.withOpacity(alpha * 0.22);
          spark.strokeWidth = 0.5;
          canvas.drawLine(Offset(x - len, y), Offset(x + len, y), spark);
          canvas.drawLine(Offset(x, y - len), Offset(x, y + len), spark);
        }

        core
          ..color = color.withOpacity(alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);
        canvas.drawCircle(center, s.r * pulse, core);
      } else {
        // 작은 별: blur 없이 가벼운 원 (대부분의 별 → 성능 핵심)
        core
          ..color = color.withOpacity(alpha)
          ..maskFilter = null;
        canvas.drawCircle(center, s.r, core);
      }
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter o) => o.t != t;
}
