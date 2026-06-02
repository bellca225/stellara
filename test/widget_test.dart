import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/app.dart';

void main() {
  testWidgets('landing screen renders login and signup entry points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StellaraApp()));
    await tester.pumpAndSettle();

    expect(find.text('Stellera'), findsOneWidget);
    expect(find.text('계정 만들기'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
