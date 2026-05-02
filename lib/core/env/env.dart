// lib/core/env/env.dart
//
// .env 파일에서 민감 정보(클라이언트 ID/Secret 등)를 읽어오는 단일 진입점입니다.
// flutter_dotenv 패키지가 main()에서 한 번 await load() 한 뒤,
// 앱 어디서든 Env.prokeralaClientId 식으로 접근합니다.
//
// 왜 이렇게 분리했는가
// - 화면 코드에 dotenv.env['XXX'] 가 흩어져 있으면 키 오타/철자 변경에 취약합니다.
// - Env 클래스에 모아두면 IDE 자동완성과 타입 체크가 동작하고,
//   "이 키가 없을 때 어떻게 처리할지" 도 한 곳에서 결정할 수 있습니다.

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Prokerala / 그 외 환경 변수를 읽어오는 정적 헬퍼.
///
/// 호출 전에 반드시 [Env.load] 를 한 번 실행해야 합니다.
/// (앱 진입점인 main.dart 에서 1회만 호출.)
class Env {
  // ── 내부 상수 ───────────────────────────────────────────────
  static const _kProkeralaClientId = 'PROKERALA_CLIENT_ID';
  static const _kProkeralaClientSecret = 'PROKERALA_CLIENT_SECRET';
  static const _kProkeralaBaseUrl = 'PROKERALA_BASE_URL';
  static const _kProkeralaTokenUrl = 'PROKERALA_TOKEN_URL';
  static const _kUseFixtureInDebug = 'USE_FIXTURE_IN_DEBUG';

  /// .env 파일을 메모리에 로드한다. 앱 시작 시 한 번 호출.
  ///
  /// 파일이 없거나 키가 비어있으면 [MissingEnvException] 을 던진다.
  /// 이렇게 일찍 실패하게 두면 "릴리즈 빌드에서야 secret 빠진 걸 발견" 하는
  /// 사고를 막을 수 있다.
  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);
    // 반드시 있어야 하는 값 검증
    _require(_kProkeralaClientId);
    _require(_kProkeralaClientSecret);
  }

  static void _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw MissingEnvException(key);
    }
  }

  // ── 외부에서 사용하는 게터 ───────────────────────────────────
  static String get prokeralaClientId => dotenv.get(_kProkeralaClientId);

  static String get prokeralaClientSecret =>
      dotenv.get(_kProkeralaClientSecret);

  /// 기본값을 두어 .env에 누락돼도 앱은 동작하게 한다 (URL은 secret이 아니므로 OK).
  static String get prokeralaBaseUrl =>
      dotenv.maybeGet(_kProkeralaBaseUrl) ?? 'https://api.prokerala.com';

  static String get prokeralaTokenUrl =>
      dotenv.maybeGet(_kProkeralaTokenUrl) ?? 'https://api.prokerala.com/token';

  /// 디버그 모드에서 fixture(녹화된 응답)를 우선 사용할지 여부.
  /// true 로 두면 개발 중 credit 소모를 줄이고 오프라인에서도 화면이 뜬다.
  static bool get useFixtureInDebug =>
      (dotenv.maybeGet(_kUseFixtureInDebug) ?? 'true').toLowerCase() == 'true';
}

/// .env에서 필수 키가 빠졌을 때 던지는 예외.
class MissingEnvException implements Exception {
  MissingEnvException(this.key);
  final String key;

  @override
  String toString() =>
      'MissingEnvException: .env 파일에 $key 가 비어있거나 누락되었습니다. '
      '.env.example 을 참고해 채워주세요.';
}
