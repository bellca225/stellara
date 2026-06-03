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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
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
                                letterSpacing: 5.15,
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
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Column(
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
                        const SizedBox(height: 48),
                      ],
                    ),
                  ],
                ),
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
    return List.generate(
      200,
      (_) => [
        rng.nextDouble(),
        rng.nextDouble(),
        rng.nextDouble() * 1.4 + 0.4,
        rng.nextDouble() * 0.65 + 0.35,
      ],
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF04091A), Color(0xFF071530), Color(0xFF0B2050)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (final s in _stars) {
      final x = s[0] * size.width;
      final y = s[1] * size.height;
      final r = s[2];
      final base = s[3];
      final phase = (x + y) / (size.width + size.height);
      final alpha = (base * (0.55 + 0.45 * math.sin((t + phase) * math.pi)))
          .clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Colors.white.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5);
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
    final center = Offset(size.width / 2, size.height * 0.40);
    final radius = size.width * (0.72 + 0.08 * a);
    final alpha = (0.20 + 0.08 * a).clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.fromRGBO(26, 95, 212, alpha),
          Color.fromRGBO(12, 46, 122, alpha * 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
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

  Gradient get _gradient => isPrimary
      ? const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x662B7FFF), Color(0x40155DFC)],
        )
      : LinearGradient(
          begin: const Alignment(-0.707, -0.707),
          end: const Alignment(0.707, 0.707),
          colors: const [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
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
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.612),
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
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
