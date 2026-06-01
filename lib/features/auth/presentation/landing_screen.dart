// lib/features/auth/presentation/landing_screen.dart
//
// 앱 최초 진입 시작 화면 (비로그인 상태).
// "계정 만들기" → SignUpScreen, "로그인" → LoginScreen
//
// 스타일/애니메이션은 디자인 담당자(도연)가 별도 작업 예정.
// 이 파일에서는 라우팅 연결과 별 배경만 담당.

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 배경 그라디언트 ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A1F), Color(0xFF08235F)],
              ),
            ),
          ),

          // ── 별 배경 (기존 login_screen 동일) ────────────────────
          ...List.generate(40, (i) {
            final x = (i * 137.5) % 100;
            final y = (i * 97.3) % 100;
            final size = (i % 3 + 1).toDouble();
            final opacity = (i % 5 + 3) / 10;
            return Positioned(
              left: x / 100 * MediaQuery.of(context).size.width,
              top: y / 100 * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),

          // ── 콘텐츠 ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // 앱 이름
                  const Text(
                    'Stellera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover What the Stars Reveal',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 계정 만들기
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5FD4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const SignUpScreen()),
                      ),
                      child: const Text(
                        '계정 만들기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 로그인
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                            color: Colors.white30, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.white10,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
