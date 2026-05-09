import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrapStatus {
  const FirebaseBootstrapStatus({
    required this.stage,
    required this.message,
    this.uid,
  });

  final String stage;
  final String message;
  final String? uid;

  String toLogLine() {
    final uidSuffix = uid == null ? '' : ' uid=$uid';
    return '[FirebaseBootstrap] $stage: $message$uidSuffix';
  }
}

class FirebaseBootstrap {
  static bool get _supportsCurrentPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<FirebaseBootstrapStatus> initialize() async {
    if (!_supportsCurrentPlatform) {
      return const FirebaseBootstrapStatus(
        stage: 'skipped',
        message: 'Android 외 플랫폼은 아직 Firebase 설정을 붙이지 않았습니다.',
      );
    }

    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (error) {
      return FirebaseBootstrapStatus(
        stage: 'init_failed',
        message: 'Firebase 초기화 실패 (${error.code})',
      );
    } catch (error) {
      return FirebaseBootstrapStatus(
        stage: 'init_failed',
        message: 'Firebase 초기화 실패 ($error)',
      );
    }

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
      return FirebaseBootstrapStatus(
        stage: 'ready',
        message: 'Android Firebase bootstrap + anonymous auth 완료',
        uid: user?.uid,
      );
    } on FirebaseAuthException catch (error) {
      return FirebaseBootstrapStatus(
        stage: 'auth_failed',
        message: 'anonymous auth 실패 (${error.code})',
      );
    } catch (error) {
      return FirebaseBootstrapStatus(
        stage: 'auth_failed',
        message: 'anonymous auth 실패 ($error)',
      );
    }
  }
}
