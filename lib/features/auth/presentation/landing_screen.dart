import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/glass.dart';
import '../../../core/widgets/star_field.dart';
import 'auth_entry_guard.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guarded = buildAuthEntryGuard(context, ref);
    if (guarded != null) return guarded;

    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라데이션 + 공용 트윙클 별필드
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF04091A), Color(0xFF071530), Color(0xFF0C1E4A)],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: StarField()),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) =>
                  CustomPaint(painter: _GlowPainter(_glowAnim.value)),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Column(
                children: [
                  // 상단 여백 (화면의 약 25%)
                  const Spacer(flex: 25),

                  // 로고
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stellara',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sulphurPoint(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 5.15,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Discover What the Stars Reveal',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sulphurPoint(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8EC5FF),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),

                  // 로고~버튼 사이 여백
                  const Spacer(flex: 8),

                  // 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassButton(
                          label: '계정 만들기',
                          isPrimary: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassButton(
                          label: '로그인',
                          isPrimary: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 하단 여백
                  const Spacer(flex: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double a;
  _GlowPainter(this.a);

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 파란 글로우 제거
    // _drawGlow(
    //   canvas,
    //   center: Offset(size.width / 2, size.height * 0.38),
    //   radius: size.width * (0.65 + 0.07 * a),
    //   alpha: (0.10 + 0.03 * a).clamp(0.0, 1.0),
    //   innerColor: const Color(0xFF1A5FD4),
    //   outerColor: const Color(0xFF0C2E7A),
    // );

    // _drawGlow(
    //   canvas,
    //   center: Offset(size.width / 2, size.height * 0.78),
    //   radius: size.width * (0.45 + 0.05 * a),
    //   alpha: (0.12 + 0.04 * a).clamp(0.0, 1.0),
    //   innerColor: const Color(0xFF1A4FBC),
    //   outerColor: const Color(0xFF08206A),
    // );
  }

  void _drawGlow(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
    required Color innerColor,
    required Color outerColor,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          innerColor.withOpacity(alpha),
          outerColor.withOpacity(alpha * 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GlowPainter o) => o.a != a;
}
