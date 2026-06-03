import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late Animation<double> _fadeIn;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _glow = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 별빛 배경
          const Positioned.fill(child: _StarField()),

          // 2. 블루 방사형 글로우
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glow,
              builder: (_, __) =>
                  CustomPaint(painter: _GlowPainter(_glow.value)),
            ),
          ),

          // 3. 메인 콘텐츠
          FadeTransition(
            opacity: _fadeIn,
            child: SafeArea(
              child: Column(
                children: [
                  // 로고 — 화면 위쪽 45% 위치에 중앙 배치
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Stellerara',
                            style: GoogleFonts.sulphurPoint(
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 5.152,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Discover What the Stars Reveal',
                            style: GoogleFonts.sulphurPoint(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF8EC5FF),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 버튼 영역
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GlassButton(
                          label: '계정 만들기',
                          isPrimary: true,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _GlassButton(
                          label: '로그인',
                          isPrimary: false,
                          onTap: () {},
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────
// 별빛 배경
// ─────────────────────────────────────────────────────────────────────
class _StarField extends StatefulWidget {
  const _StarField();

  @override
  State<_StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<_StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _StarFieldPainter(_ctrl.value),
        child: Container(),
      ),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double twinkle;
  _StarFieldPainter(this.twinkle);

  static final List<List<double>> _stars = _buildStars();

  static List<List<double>> _buildStars() {
    final rng = math.Random(42);
    return List.generate(
      180,
      (_) => [
        rng.nextDouble(),
        rng.nextDouble(),
        rng.nextDouble() * 1.6 + 0.4,
        rng.nextDouble() * 0.7 + 0.3,
      ],
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 딥 네이비 그라디언트 배경
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050B1A), Color(0xFF071530), Color(0xFF0A1E46)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (final s in _stars) {
      final x = s[0] * size.width;
      final y = s[1] * size.height;
      final r = s[2];
      final baseAlpha = s[3];

      final phase = (x + y) / (size.width + size.height);
      final alpha =
          (baseAlpha * (0.6 + 0.4 * math.sin((twinkle + phase) * math.pi)))
              .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6);

      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => old.twinkle != twinkle;
}

// ─────────────────────────────────────────────────────────────────────
// 블루 방사형 글로우
// ─────────────────────────────────────────────────────────────────────
class _GlowPainter extends CustomPainter {
  final double anim;
  _GlowPainter(this.anim);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final radius = size.width * (0.7 + 0.1 * anim);
    final alpha = (0.22 + 0.08 * anim).clamp(0.0, 1.0);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(26, 95, 212, alpha),
          Color.fromRGBO(12, 46, 122, alpha * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.anim != anim;
}

// ─────────────────────────────────────────────────────────────────────
// 유리 버튼
// ─────────────────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  Gradient get _gradient => isPrimary
      ? const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x662B7FFF), // rgba(43,127,255, 0.40)
            Color(0x40155DFC), // rgba(21,93,252, 0.25)
          ],
        )
      : LinearGradient(
          // 135deg → begin(-0.707,-0.707) end(0.707,0.707)
          begin: const Alignment(-0.707, -0.707),
          end: const Alignment(0.707, 0.707),
          colors: const [
            Color(0x1AFFFFFF), // rgba(255,255,255, 0.10)
            Color(0x0DFFFFFF), // rgba(255,255,255, 0.05)
          ],
        );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: const Color(0x26FFFFFF), // rgba(255,255,255, 0.15)
            width: 0.612,
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
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
