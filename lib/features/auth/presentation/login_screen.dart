import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              '출생 정보로 나의 행성을 만들고 친구와의 궁합, 오늘의 운세를 가볍게 확인합니다.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: () => _devLogin(context, ref, 'demo-doyeon'),
              child: const Text('개발 모드 진입 (demo-doyeon)'),
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

  Future<void> _devLogin(BuildContext context, WidgetRef ref, String uid) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.getUser(uid);
    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
    } else {
      ref.read(currentUserProvider.notifier).state = AppUser(
        uid: uid,
        nickname: '김도연',
        friendCode: 'DOY001',
        profileCompleted: false,
        authProvider: 'dev',
      );
    }
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }
}