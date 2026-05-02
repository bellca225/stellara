// lib/app.dart
//
// 앱 루트 위젯. main.dart 에서 ProviderScope 를 감싼 뒤 이걸 띄운다.

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';

class StellaraApp extends StatelessWidget {
  const StellaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellara',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // 9주차에서는 go_router 도입을 미루고 Navigator.push 로 단순 시작.
      // 라우터 도입은 11주차 친구 기능과 맞물려 진행 예정.
      home: const LoginScreen(),
    );
  }
}
