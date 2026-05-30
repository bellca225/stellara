import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../onboarding/app_shell.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xxl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const ScreenCodeChip(code: 'LOGIN-001', label: '로그인'),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'Stellara',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '내 별자리 차트로\n관계와 하루를 읽어요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '출생 정보로 나의 행성을 만들고 친구와의 궁합, 오늘의 운세를 가볍게 확인합니다.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () => _googleLogin(context, ref),
              icon: const Icon(Icons.login),
              label: const Text('Google로 시작하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _devLogin(context, ref, 'demo-doyeon'),
              child: const Text('개발 모드 진입 (demo-doyeon)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _googleLogin(BuildContext context, WidgetRef ref) async {
    final repo = AuthRepository();
    final user = await repo.signInWithGoogle();
    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      if (context.mounted) {
        if (!user.profileCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        }
      }
    }
  }

  Future<void> _devLogin(
    BuildContext context,
    WidgetRef ref,
    String uid,
  ) async {
    final repo = AuthRepository();
    final user =
        await repo.getUser(uid) ??
        AppUser(
          uid: uid,
          nickname: '김도연',
          friendCode: 'DOY001',
          profileCompleted: false,
          authProvider: 'dev',
        );
    ref.read(currentUserProvider.notifier).state = user;
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }
}
