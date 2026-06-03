import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/core/theme/app_theme.dart';

void main() {
  testWidgets('button theme does not force infinite width inside Row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('친구 이름')),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('궁합 보기'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Text('요청자 이름')),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('수락'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('궁합 보기'), findsOneWidget);
    expect(find.text('수락'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
