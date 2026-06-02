// lib/app.dart
//
// 앱 루트 위젯.
//
// _AuthGate 분기:
//   - 세션 복원 중 → 로딩 스플래시 (깜빡임 방지)
//   - 비로그인   → LandingScreen (계정 만들기 / 로그인)
//   - 로그인 + profileCompleted=false → OnboardingScreen
//   - 로그인 + profileCompleted=true  → AppShell

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/app_alerts.dart';
import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/landing_screen.dart';
import 'features/onboarding/app_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/users/application/user_providers.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class StellaraApp extends StatelessWidget {
  const StellaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellara',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      scrollBehavior: const AppScrollBehavior(),
      navigatorKey: appNavigatorKey,
      home: const _AuthGate(),
    );
  }
}

/// Firebase Auth 상태 기반 첫 화면 분기.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  /// 세션 복원 완료 여부. false 동안은 로딩 화면을 보여줘 깜빡임 방지.
  bool _sessionRestored = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (FirebaseBootstrap.isReady) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final user = await AuthRepository().getUser(firebaseUser.uid);
        if (user != null && mounted) {
          ref.read(currentUserProvider.notifier).state = user;
        }
      }
    }
    if (mounted) setState(() => _sessionRestored = true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(currentUserProfileProvider, (_, next) {
      final profile = next.valueOrNull;
      final current = ref.read(currentUserProvider);
      if (profile == null || current == null) {
        return;
      }
      if (current.loginId == profile.loginId &&
          current.nickname == profile.nickname &&
          current.friendCode == profile.friendCode &&
          current.profileCompleted == profile.profileCompleted &&
          current.sunSign == profile.sunSign) {
        return;
      }
      ref.read(currentUserProvider.notifier).state = current.copyWith(
        loginId: profile.loginId,
        nickname: profile.nickname,
        friendCode: profile.friendCode,
        profileCompleted: profile.profileCompleted,
        sunSign: profile.sunSign,
      );
    });

    // 세션 복원 전: 별 배경만 있는 스플래시 (깜빡임 없음)
    if (!_sessionRestored) return const _SplashScreen();

    final user = ref.watch(currentUserProvider);
    if (user == null) return const LandingScreen();
    if (!user.profileCompleted) return const OnboardingScreen();
    return const AppShell();
  }
}

/// 세션 복원 중 보여주는 최소 스플래시.
/// 불필요한 로그인 화면 깜빡임을 막기 위해 사용.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A1F),
      body: Center(
        child: Text(
          'Stellera',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 32,
            fontWeight: FontWeight.w300,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
