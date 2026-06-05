import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/auth_providers.dart';
import '../domain/app_user.dart';

enum AuthEntryState { allow, loading, redirectHome, redirectOnboarding }

AuthEntryState resolveAuthEntryState({
  required AppUser? currentUser,
  required String? firebaseUid,
  required bool authStateLoading,
}) {
  if (currentUser != null) {
    return currentUser.profileCompleted
        ? AuthEntryState.redirectHome
        : AuthEntryState.redirectOnboarding;
  }
  if (authStateLoading || firebaseUid != null) {
    return AuthEntryState.loading;
  }
  return AuthEntryState.allow;
}

Widget? buildAuthEntryGuard(BuildContext context, WidgetRef ref) {
  final currentUser = ref.watch(currentUserProvider);
  final uidAsync = ref.watch(currentUserIdProvider);
  final state = resolveAuthEntryState(
    currentUser: currentUser,
    firebaseUid: uidAsync.valueOrNull,
    authStateLoading: uidAsync.isLoading,
  );

  switch (state) {
    case AuthEntryState.allow:
      return null;
    case AuthEntryState.loading:
      return const _AuthEntryLoadingScreen();
    case AuthEntryState.redirectHome:
    case AuthEntryState.redirectOnboarding:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => state == AuthEntryState.redirectOnboarding
                ? const OnboardingScreen()
                : const AppShell(),
          ),
          (_) => false,
        );
      });
      return const _AuthEntryLoadingScreen();
  }
}

class _AuthEntryLoadingScreen extends StatelessWidget {
  const _AuthEntryLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A1F),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
