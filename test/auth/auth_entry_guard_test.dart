import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/auth/domain/app_user.dart';
import 'package:stellara/features/auth/presentation/auth_entry_guard.dart';

void main() {
  group('resolveAuthEntryState', () {
    const completedUser = AppUser(
      uid: 'u1',
      loginId: 'user1',
      nickname: '사용자1',
      friendCode: 'ABC123',
      profileCompleted: true,
      authProvider: 'email',
    );

    const onboardingUser = AppUser(
      uid: 'u2',
      loginId: 'user2',
      nickname: '사용자2',
      friendCode: 'DEF456',
      profileCompleted: false,
      authProvider: 'email',
    );

    test('allows auth entry when no auth session exists', () {
      expect(
        resolveAuthEntryState(
          currentUser: null,
          firebaseUid: null,
          authStateLoading: false,
        ),
        AuthEntryState.allow,
      );
    });

    test('stays loading while firebase auth state is resolving', () {
      expect(
        resolveAuthEntryState(
          currentUser: null,
          firebaseUid: null,
          authStateLoading: true,
        ),
        AuthEntryState.loading,
      );
    });

    test('redirects completed users to home', () {
      expect(
        resolveAuthEntryState(
          currentUser: completedUser,
          firebaseUid: 'u1',
          authStateLoading: false,
        ),
        AuthEntryState.redirectHome,
      );
    });

    test('redirects incomplete users to onboarding', () {
      expect(
        resolveAuthEntryState(
          currentUser: onboardingUser,
          firebaseUid: 'u2',
          authStateLoading: false,
        ),
        AuthEntryState.redirectOnboarding,
      );
    });
  });
}
