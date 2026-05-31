// lib/main.dart
//
// 앱 진입점.
//
// 9주차 변경 요약
// 1. .env 를 dotenv 로 로드 (Prokerala 인증 정보).
// 2. ProviderScope 로 Riverpod 활성화.
// 3. 기존 1782줄 통합 위젯은 features/* 로 모두 분리. 이 파일은 부트스트랩만 담당.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/cache/disk_cache.dart';
import 'core/env/env.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  // dotenv 가 비동기 I/O 를 하므로 Flutter binding 이 먼저 깨어나 있어야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Env.load();
  } on MissingEnvException catch (e) {
    // .env 누락 시에도 앱이 즉사하지 않고, 사용자에게 어떤 키가 빠졌는지
    // 친절하게 알려주는 화면을 보여준다.
    runApp(_EnvErrorApp(message: e.toString()));
    return;
  }

  debugPrint(
    '[RuntimePolicy] prokeralaRemote=${Env.prokeralaRemoteEnabled} '
    'fixtureDebug=${Env.useFixtureInDebug} '
    'aiRemote=${Env.aiRemoteEnabled}',
  );

  final firebaseStatus = await FirebaseBootstrap.initialize();
  debugPrint(firebaseStatus.toLogLine());

  // SDD 5.6 L2 디스크 캐시 부트스트랩.
  // SharedPreferences 는 비동기 init 이라 main 에서 한 번 await 한 뒤
  // ProviderScope override 로 주입한다 (이후 Provider 는 sync 로 접근 가능).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const StellaraApp(),
    ),
  );
}

class _EnvErrorApp extends StatelessWidget {
  const _EnvErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '환경 설정이 누락되었어요',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(message),
                const SizedBox(height: 24),
                const Text(
                  '.env 파일을 프로젝트 루트에 두고 다시 실행해 주세요. '
                  '예시는 .env.example 참고.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
