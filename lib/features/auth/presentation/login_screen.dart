// lib/features/auth/presentation/login_screen.dart
//
// LOGIN-001 — 흑백 로그인 진입.
// 9주차에서는 Kakao OAuth 미연동 상태이므로,
// "데모 데이터로 시작하기" 버튼 한 개만 노출.
// Kakao 연동은 10주차에 추가.

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl),
          children: [
            const ScreenCodeChip(code: 'LOGIN-001', label: '카카오 로그인 (10주차 예정)'),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'Stellara',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '내 별자리 차트로\n관계와 하루를 읽어요',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '출생 정보로 나의 행성을 만들고 친구와의 궁합, '
              '오늘의 운세를 가볍게 확인합니다.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              ),
              child: const Text('시작하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              ),
              child: const Text('데모 데이터로 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}
