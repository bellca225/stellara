// lib/core/firebase/firebase_bootstrap.dart
//
// Firebase 초기화 + isReady 게이트.
//
// 지원 플랫폼:
//   - Android: google-services.json 기반 자동 옵션
//   - Web: FIREBASE_WEB_* 환경변수 기반 (flutter_dotenv)
//   - iOS/macOS: GoogleService-Info.plist 기반 (설정 시 자동)
//
// main.dart 에서 await 한 뒤 isReady 게이트로 Firestore/Auth 접근 제어.
// auth 초기화는 여기서 하지 않음 — 앱 레벨(_AuthGate, LoginScreen)에서 처리.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  static FirebaseBootstrapStatus? _lastStatus;

  static FirebaseBootstrapStatus? get lastStatus => _lastStatus;

  /// Firestore/Auth 접근 전 반드시 이 게이트를 확인.
  static bool get isReady => _lastStatus?.stage == 'ready';

  static Future<FirebaseBootstrapStatus> initialize() async {
    final status = await _runInitialize();
    _lastStatus = status;
    return status;
  }

  static Future<FirebaseBootstrapStatus> _runInitialize() async {
    try {
      if (kIsWeb) {
        // Web: .env 의 FIREBASE_WEB_* 키로 초기화.
        // .env 에 값이 없으면 skipped — 웹 개발 시 채워넣어야 함.
        final apiKey = dotenv.maybeGet('FIREBASE_WEB_API_KEY') ?? '';
        if (apiKey.isEmpty) {
          return const FirebaseBootstrapStatus(
            stage: 'skipped',
            message: 'Web Firebase 환경변수 미설정 (FIREBASE_WEB_API_KEY). '
                '.env 에 FIREBASE_WEB_* 키를 채워주세요.',
          );
        }
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: apiKey,
            authDomain: dotenv.maybeGet('FIREBASE_WEB_AUTH_DOMAIN') ?? '',
            projectId: dotenv.maybeGet('FIREBASE_WEB_PROJECT_ID') ?? '',
            storageBucket: dotenv.maybeGet('FIREBASE_WEB_STORAGE_BUCKET') ?? '',
            messagingSenderId:
                dotenv.maybeGet('FIREBASE_WEB_MESSAGING_SENDER_ID') ?? '',
            appId: dotenv.maybeGet('FIREBASE_WEB_APP_ID') ?? '',
          ),
        );
      } else {
        // Android / iOS / macOS: 플랫폼 설정 파일 자동 사용.
        await Firebase.initializeApp();
      }
    } on FirebaseException catch (e) {
      return FirebaseBootstrapStatus(
        stage: 'init_failed',
        message: 'Firebase 초기화 실패 (${e.code})',
      );
    } catch (e) {
      return FirebaseBootstrapStatus(
        stage: 'init_failed',
        message: 'Firebase 초기화 실패 ($e)',
      );
    }

    return const FirebaseBootstrapStatus(
      stage: 'ready',
      message: 'Firebase 초기화 완료',
    );
  }
}
