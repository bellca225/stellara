import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/core/input/app_input_formatters.dart';

void main() {
  test('login id formatter keeps only ascii id characters and lowercases them', () {
    final formatter = LoginIdTextFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'AbC_12 한글-!'),
    );

    expect(result.text, equals('abc_12'));
  });

  test('friend code formatter uppercases and strips non-alphanumeric chars', () {
    final formatter = FriendCodeTextFormatter();
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'ab-12 한글_cd'),
    );

    expect(result.text, equals('AB12CD'));
  });
}
