import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/main.dart';

void main() {
  testWidgets('login onboarding and main mock flow works', (tester) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StellaraApp());

    expect(find.text('LOGIN-001'), findsOneWidget);
    expect(find.text('카카오로 시작하기'), findsOneWidget);

    await tester.tap(find.text('카카오로 시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('ONBOARDING-001'), findsOneWidget);
    expect(find.text('차트 생성하고 시작'), findsOneWidget);

    await tester.tap(find.text('차트 생성하고 시작'));
    await tester.pumpAndSettle();

    expect(find.text('MAIN-001'), findsOneWidget);
    expect(find.text('나의 우주'), findsOneWidget);
    expect(find.text('상세 보기'), findsOneWidget);
  });
}
