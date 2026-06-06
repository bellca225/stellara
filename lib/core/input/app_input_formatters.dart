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
    // 한글 등 IME 조합(composing) 중에는 formatter를 개입시키지 않는다.
    //
    // 이유: formatter가 조합 중인 한글 문자를 제거해 text=""를 반환하면,
    // Chrome 웹엔진이 아직 composingExtent=1 상태인 이벤트를 한 번 더 보내고,
    // Flutter가 "Range end 1 is out of text of length 0" assertion을 발생시킨다.
    // composing이 완료된 뒤(TextRange.empty) 필터링하면 이 경쟁 조건을 피할 수 있다.
    if (newValue.composing != TextRange.empty) {
      return oldValue;
    }
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
/// - friendCodes/{code} 문서 ID 자체가 대문자 6자리 규칙이므로
///   검색 입력도 같은 스키마로 맞춘다.
class FriendCodeTextFormatter extends TextInputFormatter {
  static final RegExp _allowed = RegExp(r'[A-Za-z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // LoginIdTextFormatter와 동일한 이유로 IME 조합 중에는 개입하지 않는다.
    if (newValue.composing != TextRange.empty) {
      return oldValue;
    }
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
