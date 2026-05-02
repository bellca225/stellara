// test/widget_test.dart
//
// 9주차 흑백 프로토타입의 smoke test.
// .env 로드 + Prokerala 호출은 실제 네트워크가 필요하므로 여기선 검증하지 않고,
// "앱이 크래시 없이 첫 화면에 도달하는가" 만 본다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen 첫 화면 렌더링', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );

    // 흑백 로그인 화면의 핵심 카피.
    expect(find.text('Stellara'), findsOneWidget);
    expect(find.text('LOGIN-001'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
    expect(find.text('데모 데이터로 둘러보기'), findsOneWidget);
  });
}
