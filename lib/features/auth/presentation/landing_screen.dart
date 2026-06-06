import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
          const Positioned.fill(child: _StarField()),
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
                        'Stellerara',
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
                        _GlassButton(
                          label: '계정 만들기',
                          isPrimary: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GlassButton(
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
      builder: (_, __) =>
          CustomPaint(painter: _StarPainter(_ctrl.value), child: Container()),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double t;
  _StarPainter(this.t);

  static final List<List<double>> _stars = () {
    final rng = math.Random(42);
    return List.generate(350, (i) {
      final isBright = i >= 300;
      return [
        rng.nextDouble(),
        rng.nextDouble(),
        isBright ? rng.nextDouble() * 1.2 + 1.0 : rng.nextDouble() * 0.7 + 0.3,
        isBright ? rng.nextDouble() * 0.4 + 0.6 : rng.nextDouble() * 0.5 + 0.2,
      ];
    });
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF04091A), Color(0xFF071530), Color(0xFF0C1E4A)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (final s in _stars) {
      final x = s[0] * size.width;
      final y = s[1] * size.height;
      final r = s[2];
      final base = s[3];
      final phase = (x * 0.7 + y * 0.3) / (size.width + size.height);
      final alpha = (base * (0.5 + 0.5 * math.sin((t + phase) * math.pi)))
          .clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..maskFilter = r > 1.2
            ? MaskFilter.blur(BlurStyle.normal, r * 0.8)
            : MaskFilter.blur(BlurStyle.normal, r * 0.3);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter o) => o.t != t;
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

class _GlassButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _GlassButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  // 진한 블루(계정 만들기) / 어두운 반투명(로그인) 글라스 채움.
  // 알파를 낮춰 뒤의 별빛이 버튼 안쪽에 살짝 비쳐 보이도록 함.
  Gradient get _gradient => isPrimary
      // 진한 블루 글라스: 위쪽 약간 밝고 아래로 깊어지는 세로 그라데이션
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x592B6FE6), Color(0x592B6FE6)],
        )
      // 어두운 반투명 글라스: 별빛이 비치도록 어두운 네이비를 낮은 알파로
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x1Affffff), Color(0x1Affffff)],
          // 0A1124
        );

  // 테두리: CSS 기준 rgba(255,255,255,0.15) = 흰색 15% 투명도
  Color get _borderColor => const Color(0x26FFFFFF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(9999),
          // Figma: 0.612px solid rgba(255,255,255,0.15)
          border: Border.all(color: _borderColor, width: 1.2),
          // Figma drop shadows (두 버튼 동일):
          //  0px 4px 4px  rgba(0,0,0,0.15)
          //  0px 5px 20px rgba(30,58,138,0.5)
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Figma inset inner shadow: inset 0px 1px 1px rgba(255,255,255,0.15)
            // (Flutter BoxShadow는 inset 미지원 → 상단 얇은 흰색 하이라이트로 표현)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x26FFFFFF),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.0],
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
