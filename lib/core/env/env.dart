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

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProkeralaCredential {
  const ProkeralaCredential({
    required this.label,
    required this.clientId,
    required this.clientSecret,
  });

  final String label;
  final String clientId;
  final String clientSecret;
}

/// Prokerala / 그 외 환경 변수를 읽어오는 정적 헬퍼.
///
/// 호출 전에 반드시 [Env.load] 를 한 번 실행해야 합니다.
/// (앱 진입점인 main.dart 에서 1회만 호출.)
class Env {
  // ── 내부 상수 ───────────────────────────────────────────────
  static const _kProkeralaClientId = 'PROKERALA_CLIENT_ID';
  static const _kProkeralaClientSecret = 'PROKERALA_CLIENT_SECRET';
  static const _kProkeralaClientIdSeoyeon = 'PROKERALA_CLIENT_ID_SEOYEON';
  static const _kProkeralaClientSecretSeoyeon =
      'PROKERALA_CLIENT_SECRET_SEOYEON';
  static const _kProkeralaClientIdSeonwoo = 'PROKERALA_CLIENT_ID_SEONWOO';
  static const _kProkeralaClientSecretSeonwoo =
      'PROKERALA_CLIENT_SECRET_SEONWOO';
  static const _kProkeralaClientIdDoyeon = 'PROKERALA_CLIENT_ID_DOYEON';
  static const _kProkeralaClientSecretDoyeon =
      'PROKERALA_CLIENT_SECRET_DOYEON';
  static const _kProkeralaBaseUrl = 'PROKERALA_BASE_URL';
  static const _kProkeralaTokenUrl = 'PROKERALA_TOKEN_URL';
  static const _kProkeralaRemoteEnabled = 'PROKERALA_REMOTE_ENABLED';
  static const _kUseFixtureInDebug = 'USE_FIXTURE_IN_DEBUG';
  static const _kAiRemoteEnabled = 'AI_REMOTE_ENABLED';

  // ── AI 멀티 프로바이더 설정 (Codex 구조와 통일) ─────────────────
  // AI_PROVIDER_DEFAULT: 기본 호출 프로바이더 ('openai' | 'anthropic' | 'auto')
  // AI_PROVIDER_ORDER: fallback 순서 ('openai,anthropic' 등 comma-separated)
  static const _kAiProviderDefault = 'AI_PROVIDER_DEFAULT';
  static const _kAiProviderOrder = 'AI_PROVIDER_ORDER';
  static const _kAiModelOpenAiDefault = 'AI_MODEL_OPENAI_DEFAULT';
  static const _kAiModelAnthropicDefault = 'AI_MODEL_ANTHROPIC_DEFAULT';
  static const _kOpenAiApiKey = 'OPENAI_API_KEY';
  static const _kAnthropicApiKey = 'ANTHROPIC_API_KEY';

  /// .env 파일을 메모리에 로드한다. 앱 시작 시 한 번 호출.
  ///
  /// 파일이 없거나 키가 비어있으면 [MissingEnvException] 을 던진다.
  /// 단, 기본 브랜치에서는 Prokerala 원격 호출을 잠그고,
  /// 디버그 + fixture 우선 모드에서도 실호출을 하지 않으므로
  /// client id/secret 없이도 앱을 띄울 수 있게 예외를 완화한다.
  /// 이렇게 하면 비개발자/디자인 작업자도 API 키 없이 화면 작업을 시작할 수 있다.
  static Future<void> load({String fileName = '.env'}) async {
    await dotenv.load(fileName: fileName);

    // 기본 브랜치에서 원격 호출을 잠근 상태이거나,
    // 디버그 + fixture 우선 모드에서는 네트워크 호출 전 단계에서 종료되므로
    // Prokerala 키를 강제하지 않는다.
    if (!prokeralaRemoteEnabled || (kDebugMode && useFixtureInDebug)) {
      return;
    }

    if (prokeralaCredentials.isEmpty) {
      throw MissingEnvException(
        'PROKERALA_CLIENT_ID / PROKERALA_CLIENT_SECRET '
        '(or backup credential set)',
      );
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

  /// 무료 플랜/무과금 보호를 위해 기본 브랜치에서는 Prokerala 원격 호출을 막는다.
  static bool get prokeralaRemoteEnabled =>
      (dotenv.maybeGet(_kProkeralaRemoteEnabled) ?? 'false').toLowerCase() ==
      'true';

  /// 디버그 모드에서 fixture(녹화된 응답)를 우선 사용할지 여부.
  /// true 로 두면 개발 중 credit 소모를 줄이고 오프라인에서도 화면이 뜬다.
  static bool get useFixtureInDebug =>
      (dotenv.maybeGet(_kUseFixtureInDebug) ?? 'false').toLowerCase() == 'true';

  /// 현재 빌드/환경 정책상 Prokerala 네트워크를 타면 안 되는지 여부.
  static bool get shouldUseFixtureForProkerala =>
      !prokeralaRemoteEnabled || (kDebugMode && useFixtureInDebug);

  /// 학교 프로젝트 무료 운영 정책:
  /// 기본 브랜치에서는 원격 AI 호출을 막고 local question set 만 사용한다.
  static bool get aiRemoteEnabled =>
      (dotenv.maybeGet(_kAiRemoteEnabled) ?? 'false').toLowerCase() == 'true';

  // ── AI 멀티 프로바이더 getter ────────────────────────────────────

  /// OpenAI API 키. AI_REMOTE_ENABLED=true 일 때만 사용.
  /// 키가 없으면 빈 문자열 반환 → repository에서 다음 프로바이더로 fallback.
  static String get openAiApiKey =>
      dotenv.maybeGet(_kOpenAiApiKey)?.trim() ?? '';

  /// Anthropic API 키. openAiApiKey가 없거나 실패 시 fallback으로 사용.
  static String get anthropicApiKey =>
      dotenv.maybeGet(_kAnthropicApiKey)?.trim() ?? '';

  /// 기본 AI 프로바이더. 'openai' | 'anthropic' | 'auto'(=순서대로 시도)
  /// 기본값: 'auto' (AI_PROVIDER_ORDER 순서로 시도)
  static String get aiProviderDefault =>
      dotenv.maybeGet(_kAiProviderDefault)?.trim() ?? 'auto';

  /// fallback 순서. 'openai,anthropic' 형태의 comma-separated 문자열.
  /// 앞쪽 프로바이더가 실패하면 다음 프로바이더로 자동 전환.
  static List<String> get aiProviderOrder {
    final raw = dotenv.maybeGet(_kAiProviderOrder)?.trim() ?? 'openai,anthropic';
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// 사용할 OpenAI 모델. 기본값: gpt-4o-mini (랜덤 질문용 비용/속도 최적).
  /// AI 성격 리포트 등 장문 생성은 별도 key(AI_MODEL_OPENAI_REPORT 등)로 분리 예정.
  static String get aiModelOpenAi =>
      dotenv.maybeGet(_kAiModelOpenAiDefault)?.trim() ?? 'gpt-4o-mini';

  /// 사용할 Anthropic 모델. 기본값: claude-3-5-haiku-latest (fallback용 경량 모델).
  static String get aiModelAnthropic =>
      dotenv.maybeGet(_kAiModelAnthropicDefault)?.trim() ?? 'claude-3-5-haiku-latest';

  static List<ProkeralaCredential> get prokeralaCredentials {
    final credentials = <ProkeralaCredential>[];

    void addCredential({
      required String label,
      required String clientIdKey,
      required String clientSecretKey,
    }) {
      final clientId = dotenv.maybeGet(clientIdKey)?.trim() ?? '';
      final clientSecret = dotenv.maybeGet(clientSecretKey)?.trim() ?? '';
      if (clientId.isEmpty || clientSecret.isEmpty) {
        return;
      }
      credentials.add(
        ProkeralaCredential(
          label: label,
          clientId: clientId,
          clientSecret: clientSecret,
        ),
      );
    }

    addCredential(
      label: 'primary',
      clientIdKey: _kProkeralaClientId,
      clientSecretKey: _kProkeralaClientSecret,
    );
    addCredential(
      label: 'seoyeon',
      clientIdKey: _kProkeralaClientIdSeoyeon,
      clientSecretKey: _kProkeralaClientSecretSeoyeon,
    );
    addCredential(
      label: 'seonwoo',
      clientIdKey: _kProkeralaClientIdSeonwoo,
      clientSecretKey: _kProkeralaClientSecretSeonwoo,
    );
    addCredential(
      label: 'doyeon',
      clientIdKey: _kProkeralaClientIdDoyeon,
      clientSecretKey: _kProkeralaClientSecretDoyeon,
    );

    return credentials;
  }
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
