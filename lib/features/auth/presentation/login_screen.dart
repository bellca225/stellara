// lib/features/auth/presentation/login_screen.dart
//
// LOGIN-001 — Firebase Anonymous Auth 기반 시작 화면.
// 별도 회원가입/소셜 로그인 없이 "시작하기" 버튼으로 진입.
// 신규 사용자 → ONBOARDING-001, 기존 사용자 → AppShell.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../onboarding/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _start() async {
    setState(() => _loading = true);
    final repo = ref.read(authRepositoryProvider);
    final (:user, :wasReinstalled) = await repo.signInOrRestore();

    if (!mounted) return;

    if (wasReinstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('앱이 재설치되어 새 계정이 생성되었어요. 이전 친구 관계는 초기화됩니다.'),
          duration: Duration(seconds: 4),
        ),
      );
    }

    if (user != null) {
      ref.read(currentUserProvider.notifier).state = user;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              user.profileCompleted ? const AppShell() : const OnboardingScreen(),
        ),
      );
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _devLogin(String uid) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.devLogin(uid);
    if (user != null && mounted) {
      ref.read(currentUserProvider.notifier).state = user;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const ScreenCodeChip(code: 'LOGIN-001', label: '시작'),
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
              onPressed: _loading ? null : _start,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('시작하기'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => _devLogin('demo-una'),
              child: const Text('데모 데이터로 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}
