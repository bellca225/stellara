import 'package:flutter/services.dart';

/// 로그인 아이디 전용 formatter.
///
/// - 영문/숫자/언더스코어만 허용
/// - 대문자는 소문자로 정규화
/// - 한글/공백/기타 특수문자는 입력 단계에서 제거
class LoginIdTextFormatter extends TextInputFormatter {
  static final RegExp _allowed = RegExp(r'[A-Za-z0-9_]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      final char = String.fromCharCode(rune);
      if (_allowed.hasMatch(char)) {
        buffer.write(char.toLowerCase());
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 친구 코드 검색 전용 formatter.
///
/// - 영문/숫자만 허용
/// - 소문자는 대문자로 정규화
class FriendCodeTextFormatter extends TextInputFormatter {
  static final RegExp _allowed = RegExp(r'[A-Za-z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    for (final rune in newValue.text.runes) {
      final char = String.fromCharCode(rune);
      if (_allowed.hasMatch(char)) {
        buffer.write(char.toUpperCase());
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
