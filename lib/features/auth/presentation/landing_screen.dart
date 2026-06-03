import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    final rng = math.Random(42);
    _stars = List.generate(60, (_) => _Star(rng));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF060618),
                  Color(0xFF0A0F2E),
                  Color(0xFF0D1F5C),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                ...List.generate(60, (i) {
                  final s = _stars[i];
                  return Positioned(
                    left: s.x * MediaQuery.of(context).size.width,
                    top: s.y * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: s.opacity,
                      child: Container(
                        width: s.size,
                        height: s.size,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
                Center(
                  child: Opacity(
                    opacity: _glowAnim.value * 0.3,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0xFF2B7FFF), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 5),
                        const Text(
                          'Stellerara',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 5.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Discover What the Stars Reveal',
                          style: TextStyle(
                            color: Color(0xFF8EC5FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(flex: 3),
                        _LandingButton(
                          label: '계정 만들기',
                          isPrimary: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SignUpScreen()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LandingButton(
                          label: '로그인',
                          isPrimary: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Star {
  final double x, y, size, opacity;
  _Star(math.Random rng)
    : x = rng.nextDouble(),
      y = rng.nextDouble(),
      size = rng.nextDouble() * 2 + 0.5,
      opacity = rng.nextDouble() * 0.6 + 0.2;
}

class _LandingButton extends StatelessWidget {
  const _LandingButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF2B7FFF), Color(0xFF155DFC)],
                )
              : const LinearGradient(
                  colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)],
                ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withOpacity(isPrimary ? 0.15 : 0.12),
            width: 0.636,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
