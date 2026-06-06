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
    // 중요: 여기서 oldValue를 반환하면(=조합값을 되돌리면) 프레임워크 값과
    // 엔진(IME) 상태가 어긋나, 엔진이 text:"" + composing:[0,1] 같은
    // 불일치 editing state를 보내 "composing.end > text.length" assertion이
    // 발생한다. 따라서 조합 중에는 newValue를 '그대로 통과'시키고,
    // 조합이 끝난 뒤(TextRange.empty)에만 필터링한다.
    if (newValue.composing != TextRange.empty) {
      return newValue;
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
    // LoginIdTextFormatter와 동일한 이유로 IME 조합 중에는 개입하지 않고
    // newValue를 그대로 통과시킨다(조합 완료 후 필터링).
    if (newValue.composing != TextRange.empty) {
      return newValue;
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
