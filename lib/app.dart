// lib/app.dart
//
// 앱 루트 위젯.
//
// _AuthGate: Firebase Auth 상태를 확인해 첫 화면을 결정한다.
//   - currentUser 없음 → LoginScreen (anonymous auth 시작)
//   - profileCompleted=false → OnboardingScreen
//   - profileCompleted=true → AppShell (메인 홈)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/ui/app_alerts.dart';
import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/onboarding/app_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
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
/// Firebase가 준비되지 않은 환경(Web 미설정 등)에서는 LoginScreen으로 폴백.
class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    // Firebase가 준비된 환경에서만 세션 복원 시도
    if (!FirebaseBootstrap.isReady) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final repo = AuthRepository();
    final user = await repo.getUser(firebaseUser.uid);
    if (user != null && mounted) {
      ref.read(currentUserProvider.notifier).state = user;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const LoginScreen();
    if (!user.profileCompleted) return const OnboardingScreen();
    return const AppShell();
  }
}
