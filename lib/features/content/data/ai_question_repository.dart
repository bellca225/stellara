// lib/features/content/data/ai_question_repository.dart
//
// AI 기반 질문/해설 생성 Repository.
//
// 흐름:
//   1. Env.aiRemoteEnabled == false  → 로컬 fallback (로컬 템플릿 반환)
//   2. openAiApiKey 비어있음          → 로컬 fallback
//   3. OpenAI GPT-4o-mini 호출       → 성공 시 QuestionItem(source: remoteAi)
//   4. 호출 실패/파싱 실패            → 로컬 fallback (사용자에게 에러 미노출)
//
// 시스템 프롬프트는 이 파일에 상수로 보관한다.
// 사용자 메시지(context)는 NatalChart + SynastryResult를 기반으로 동적 구성한다.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/env/env.dart';
import '../../../core/utils/astro_text.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../compatibility/domain/synastry_result.dart';
import '../domain/question_item.dart';
import 'question_repository.dart';

// ── JSON 전용 출력 강제 지시 (모든 프롬프트 끝에 공통 적용) ──────────────────
// gemini-2.5-flash 등 일부 모델이 responseMimeType 설정을 무시하고
// "Here is the JSON:" 같은 자연어를 앞에 붙이는 현상을 방지한다.
const _kJsonOnlyInstruction = '''

[출력 규칙 — 반드시 준수]
- 응답은 반드시 순수 JSON 객체 하나만 반환한다.
- "Here is", "Sure", "Certainly" 등 설명문을 절대 포함하지 않는다.
- markdown 코드블록(```json ... ```)을 절대 사용하지 않는다.
- JSON 앞뒤에 어떤 텍스트도 붙이지 않는다.
- Return ONLY the raw JSON object. No explanations. No markdown. No code fences.
''';

// ── 시스템 프롬프트 ───────────────────────────────────────────────────────────
const _kQuestionSetSystemPrompt = '''
당신은 점성술 기반 친구 관계 질문 생성 AI입니다.

[역할]
두 사람의 점성술 데이터(출생 차트, 궁합 점수)를 받아 창의적이고 재밌는 질문과 해설을 JSON으로 생성합니다.

[톤 & 스타일]
- Z세대 친구끼리 카톡 하듯 자연스럽고 편한 말투
- 유머와 위트가 있지만 상처 주지 않는 선
- 진지한 심리 상담이나 운세 느낌은 절대 금지
- "~할 것입니다" 같은 딱딱한 문체 금지
- 친구끼리 킥킥거리면서 볼 수 있는 느낌

[질문 타입별 가이드]
- balanceGame: "A vs B 둘 중 하나를 선택해야 한다면?" 형식. 두 극단적 선택지.
- situationPrediction: "이 두 사람이 [상황]에 처하면 어떤 일이?" 형식. 구체적인 상황 설정.
- personalityReveal: 겉으로는 가벼운 질문이지만 은근히 성향이 드러나는 질문.
- funnyCompatibility: 이 두 별자리 조합에서만 나오는 웃긴 포인트 포착.
- emotionStyle: 갈등/감정 상황에서 두 사람의 극명한 차이를 재밌게 짚기.
- creativeScenario: 현실에 없는 황당하지만 재밌는 가상 상황 설정.

[해설 작성 가이드]
- 반드시 제공된 점성술 데이터(행성/별자리/어스펙트/궁합점수)를 근거로 쓸 것
- 별자리 이름만 나열하는 답변 절대 금지
- 두 사람의 조합에서 나오는 특성을 구체적으로 묘사
- 3~5문장, 마지막 문장은 살짝 웃길 것

[출력 형식]
{"question": "질문 텍스트", "answer": "해설 텍스트"}
$_kJsonOnlyInstruction''';

const _kRandomQuestionSystemPrompt = '''
당신은 점성술 기반 친구 관계 질문 생성 AI입니다.

[역할]
두 사람의 점성술 데이터와 관계 맥락을 읽고, 친구끼리 공유하고 싶은 가볍고 창의적인 질문 딱 1개를 JSON으로 생성합니다.

[톤]
- 너무 진지하지 않고 재밌는 한국어
- 친구 displayName만 사용하고 loginId는 절대 쓰지 않음
- 질문만 보고도 웃기거나 답해보고 싶어야 함
- 점성술 표현은 자연스럽게 녹이고, 겁주거나 단정하지 말 것

[길이 제한 — 반드시 준수]
- 질문은 2줄을 절대 넘지 않는다 (모바일 기준 한 줄 약 20자, 총 40자 이내)
- 불필요한 수식어·설명·괄호 보충 없이 핵심만 담아 짧고 임팩트 있게

[출력 형식]
{"question": "질문 텍스트 1개"}
$_kJsonOnlyInstruction''';

const _kRandomAnswerSystemPrompt = '''
당신은 점성술 기반 친구 관계 해설 AI입니다.

[역할]
이미 생성된 질문 1개와 두 사람의 점성술 데이터를 읽고, 그 질문에 대한 답변/해설을 JSON으로 생성합니다.

[톤]
- 가볍고 자연스럽고 재밌는 한국어
- 태양/달/수성/금성/화성 등 실제 데이터 근거를 반드시 반영
- 너무 무섭거나 단정적인 표현 금지
- 친구끼리 공유해도 민망하지 않을 정도의 위트만 허용
- 3~5문장, 마지막 한 문장은 살짝 웃기거나 여운 있게

[출력 형식]
{"answer": "질문에 대한 점성술 기반 답변"}
$_kJsonOnlyInstruction''';

const _kDailyHoroscopeSystemPrompt = '''
당신은 개인 점성술 데이터를 바탕으로 오늘의 운세를 생성하는 AI입니다.

[역할]
사용자의 출생 차트와 오늘 날짜/시간대 정보를 읽고, 오늘 하루에 맞는 운세를 한국어 JSON으로 생성합니다.

[규칙]
- 반드시 제공된 점성술 데이터에 근거할 것
- 막연한 범용 문구나 무서운 예언 금지
- 너무 점잖은 상담체 말고, 부드럽고 자연스러운 한국어
- luckyColor 는 한국어 색상명으로 반환
- luckyPlace 는 한국어 장소명 또는 장소 묶음으로 반환
- luckyNumbers 는 3개의 정수 배열로 반환
- overall/emotion/advice/caution/shareText 는 짧고 읽기 쉽게

[출력 형식]
{"overall":"전체 운세","emotion":"감정 상태","luckyNumbers":[7,14,21],"luckyColor":"보라색","luckyPlace":"카페","advice":"조언","caution":"주의","shareText":"공유 문구"}
$_kJsonOnlyInstruction''';

const _kRandomQuestionPromptVersion = 'rq-question-v2';
const _kRandomAnswerPromptVersion = 'rq-answer-v2';
const _kDailyHoroscopePromptVersion = 'daily-horoscope-v2';

// ── API 엔드포인트 ───────────────────────────────────────────────────────────
const _kOpenAiChatEndpoint = 'https://api.openai.com/v1/chat/completions';
const _kAnthropicChatEndpoint = 'https://api.anthropic.com/v1/messages';
const _kAnthropicVersion = '2023-06-01';
// Gemini: generateContent endpoint. {model}과 {apiKey}는 런타임에 치환.
const _kGeminiEndpointTemplate =
    'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={apiKey}';

class AiDailyHoroscopePayload {
  const AiDailyHoroscopePayload({
    required this.overall,
    required this.emotion,
    required this.luckyNumbers,
    required this.luckyColor,
    required this.luckyPlace,
    required this.advice,
    required this.caution,
    required this.shareText,
    required this.promptVersion,
  });

  final String overall;
  final String emotion;
  final List<int> luckyNumbers;
  final String luckyColor;
  final String luckyPlace;
  final String advice;
  final String caution;
  final String shareText;
  final String promptVersion;
}

class AiQuestionRepository {
  AiQuestionRepository({QuestionRepository? localFallback})
      : _local = localFallback ?? QuestionRepository();

  final QuestionRepository _local;
  final _client = HttpClientWrapper();

  static String get randomQuestionPromptVersion => _kRandomQuestionPromptVersion;
  static String get randomAnswerPromptVersion => _kRandomAnswerPromptVersion;
  static String get dailyHoroscopePromptVersion => _kDailyHoroscopePromptVersion;

  // ── 공개 API ───────────────────────────────────────────────────────────────

  /// AI로 질문 세트 생성. 실패 시 로컬 fallback.
  /// [count] 개의 서로 다른 타입 질문을 생성한다.
  Future<List<QuestionItem>> generateAiQuestions({
    required String myUid,
    required String myNickname,
    required NatalChart myChart,
    required String friendUid,
    required String friendNickname,
    required NatalChart friendChart,
    SynastryResult? synastry,
    int count = 3,
    int revision = 0,
  }) async {
    if (!Env.aiRemoteEnabled || !_hasAnyApiKey()) {
      if (kDebugMode) {
        debugPrint('[AiQuestionRepository] AI 비활성화 또는 키 없음 → 로컬 fallback');
      }
      return _local.generate(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        revision: revision,
      );
    }

    // 타입 풀에서 중복 없이 count개 선택
    final types = _pickQuestionTypes(count, seed: friendUid.hashCode ^ revision);
    final results = <QuestionItem>[];

    for (final type in types) {
      try {
        final item = await _callOpenAi(
          myNickname: myNickname,
          myChart: myChart,
          friendNickname: friendNickname,
          friendChart: friendChart,
          synastry: synastry,
          questionType: type,
          friendUid: friendUid,
          revision: revision,
        );
        results.add(item);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[AiQuestionRepository] 질문 생성 실패($type): $e\n$st');
        }
        // 단일 질문 실패 시 로컬 1개로 보완
        final fallback = await _localSingleFallback(
          friendUid: friendUid,
          friendNickname: friendNickname,
          friendChart: friendChart,
          myChart: myChart,
          index: results.length,
        );
        results.add(fallback);
      }
    }

    return results;
  }

  /// 커스텀 질문(사용자 입력) → AI 해설 생성. 실패 시 로컬 fallback.
  Future<QuestionItem> generateCustomAnswer({
    required String myNickname,
    required NatalChart myChart,
    required String friendUid,
    required String friendNickname,
    required NatalChart friendChart,
    required String userPrompt,
    SynastryResult? synastry,
  }) async {
    if (!Env.aiRemoteEnabled || !_hasAnyApiKey()) {
      return _local.answerCustom(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        userPrompt: userPrompt,
      );
    }

    try {
      final context = _buildContext(
        myNickname: myNickname,
        myChart: myChart,
        friendNickname: friendNickname,
        friendChart: friendChart,
        synastry: synastry,
        questionType: QuestionType.personalityReveal,
      );

      final userMessage =
          '$context\n\n'
          '사용자가 직접 입력한 질문: "$userPrompt"\n'
          '이 질문에 대한 점성술 기반 해설을 JSON으로 생성해주세요.\n'
          'question 필드에는 사용자 질문을 그대로 쓰세요.';

      final raw = await _sendRequest(
        userMessage,
        systemPrompt: _kQuestionSetSystemPrompt,
        temperature: 0.9,
        maxTokens: 400,
      );
      final parsed = _parseResponseOrWrapRaw(raw, 'answer');

      return QuestionItem(
        id: 'ai-custom-$friendUid-${userPrompt.hashCode}',
        prompt: parsed['question'] as String? ?? userPrompt,
        answer: parsed['answer'] as String? ?? raw,
        source: QuestionSource.remoteAi,
        questionType: QuestionType.personalityReveal,
        generatedAt: DateTime.now(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AiQuestionRepository] 커스텀 답변 실패: $e\n$st');
      }
      return _local.answerCustom(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        userPrompt: userPrompt,
      );
    }
  }

  Future<QuestionItem> generateSingleRandomQuestion({
    required String myUid,
    required String myNickname,
    required NatalChart myChart,
    required String friendUid,
    required String friendNickname,
    required NatalChart friendChart,
    SynastryResult? synastry,
    int revision = 0,
  }) async {
    if (!Env.aiRemoteEnabled || !_hasAnyApiKey()) {
      return _localSingleFallback(
        friendUid: friendUid,
        friendNickname: friendNickname,
        friendChart: friendChart,
        myChart: myChart,
        index: revision,
      );
    }

    final type = _pickQuestionTypes(
      1,
      seed: myUid.hashCode ^ friendUid.hashCode ^ (revision * 41),
    ).first;

    try {
      final context = _buildContext(
        myNickname: myNickname,
        myChart: myChart,
        friendNickname: friendNickname,
        friendChart: friendChart,
        synastry: synastry,
        questionType: type,
      );
      final userMessage =
          '$context\n\n'
          '[생성 규칙]\n'
          '- 이번 revision: $revision\n'
          '- 이전 질문과 최대한 다른 결의 질문 1개를 만드세요.\n'
          '- question 필드만 채우세요.\n';

      final raw = await _sendRequest(
        userMessage,
        systemPrompt: _kRandomQuestionSystemPrompt,
        temperature: 1.0,
        maxTokens: 220,
      );
      final parsed = _parseResponseOrWrapRaw(raw, 'question');
      final prompt =
          (parsed['question'] as String?)?.trim() ??
          '$friendNickname와 함께 있으면 가장 재밌게 터질 상황은 뭐야?';

      return QuestionItem(
        id:
            'ai-question-$friendUid-$revision-${DateTime.now().millisecondsSinceEpoch}',
        prompt: prompt,
        answer: '',
        source: QuestionSource.remoteAi,
        questionType: type,
        generatedAt: DateTime.now(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AiQuestionRepository] 단일 질문 생성 실패: $e\n$st');
      }
      return _localSingleFallback(
        friendUid: friendUid,
        friendNickname: friendNickname,
        friendChart: friendChart,
        myChart: myChart,
        index: revision,
      );
    }
  }

  Future<QuestionItem> generateAnswerForQuestion({
    required String myNickname,
    required NatalChart myChart,
    required String friendUid,
    required String friendNickname,
    required NatalChart friendChart,
    required String questionPrompt,
    SynastryResult? synastry,
  }) async {
    if (!Env.aiRemoteEnabled || !_hasAnyApiKey()) {
      return _local.answerCustom(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        userPrompt: questionPrompt,
      );
    }

    try {
      final context = _buildContext(
        myNickname: myNickname,
        myChart: myChart,
        friendNickname: friendNickname,
        friendChart: friendChart,
        synastry: synastry,
        questionType: QuestionType.personalityReveal,
      );
      final userMessage =
          '$context\n\n'
          '[이미 생성된 질문]\n'
          '$questionPrompt\n\n'
          '이 질문에 대한 답변만 JSON으로 생성해주세요.';

      final raw = await _sendRequest(
        userMessage,
        systemPrompt: _kRandomAnswerSystemPrompt,
        temperature: 0.85,
        maxTokens: 320,
      );
      final parsed = _parseResponseOrWrapRaw(raw, 'answer');
      final fallbackItem = await _local.answerCustom(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        userPrompt: questionPrompt,
      );
      final resolvedAnswer =
          (parsed['answer'] as String?)?.trim().isNotEmpty ?? false
          ? (parsed['answer'] as String).trim()
          : fallbackItem.answer;

      return QuestionItem(
        id: 'ai-answer-$friendUid-${questionPrompt.hashCode}',
        prompt: questionPrompt,
        answer: resolvedAnswer,
        source: QuestionSource.remoteAi,
        questionType: QuestionType.personalityReveal,
        generatedAt: DateTime.now(),
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AiQuestionRepository] 질문 답변 생성 실패: $e\n$st');
      }
      return _local.answerCustom(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendChart.sunSign,
        mySign: myChart.sunSign,
        userPrompt: questionPrompt,
      );
    }
  }

  Future<AiDailyHoroscopePayload> generateDailyHoroscope({
    required String nickname,
    required NatalChart chart,
    required DateTime targetDate,
    required String timezone,
    String? placeName,
  }) async {
    if (!Env.aiRemoteEnabled || !_hasAnyApiKey()) {
      throw StateError('AI horoscope unavailable');
    }

    final userMessage =
        _buildDailyHoroscopeContext(
          nickname: nickname,
          chart: chart,
          targetDate: targetDate,
          timezone: timezone,
          placeName: placeName,
        );
    final raw = await _sendRequest(
      userMessage,
      systemPrompt: _kDailyHoroscopeSystemPrompt,
      temperature: 0.8,
      maxTokens: 420,
    );
    final parsed = _parseResponseOrWrapRaw(raw, 'overall');

    // luckyNumbers: int 또는 string 숫자 모두 처리
    final luckyNumbers = <int>[
      for (final value in (parsed['luckyNumbers'] as List? ?? const []))
        if (value is num)
          value.toInt()
        else if (value is String)
          int.tryParse(value) ?? -1,
    ]..removeWhere((n) => n <= 0);

    final overall = (parsed['overall'] as String?)?.trim() ?? '';
    if (overall.isEmpty) {
      // JSON 파싱은 됐지만 overall 필드가 없거나 비어있음 → local fallback으로 전환
      if (kDebugMode) debugPrint('[AiResponseParser] overall 필드 없음 → horoscope fallback');
      throw const FormatException('overall missing');
    }

    return AiDailyHoroscopePayload(
      overall: overall,
      emotion: (parsed['emotion'] as String? ?? '').trim(),
      luckyNumbers: luckyNumbers,
      luckyColor: (parsed['luckyColor'] as String? ?? '').trim(),
      luckyPlace: (parsed['luckyPlace'] as String? ?? '').trim(),
      advice: (parsed['advice'] as String? ?? '').trim(),
      caution: (parsed['caution'] as String? ?? '').trim(),
      shareText: (parsed['shareText'] as String? ?? '').trim(),
      promptVersion: _kDailyHoroscopePromptVersion,
    );
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────────────────────

  Future<QuestionItem> _callOpenAi({
    required String myNickname,
    required NatalChart myChart,
    required String friendNickname,
    required NatalChart friendChart,
    required QuestionType questionType,
    required String friendUid,
    required int revision,
    SynastryResult? synastry,
  }) async {
    final context = _buildContext(
      myNickname: myNickname,
      myChart: myChart,
      friendNickname: friendNickname,
      friendChart: friendChart,
      synastry: synastry,
      questionType: questionType,
    );

    final raw = await _sendRequest(
      context,
      systemPrompt: _kQuestionSetSystemPrompt,
      temperature: 0.9,
      maxTokens: 400,
    );
    final parsed = _parseResponseOrWrapRaw(raw, 'question');

    final id =
        'ai-$friendUid-$revision-${questionType.name}-${DateTime.now().millisecondsSinceEpoch}';

    return QuestionItem(
      id: id,
      prompt: parsed['question'] as String? ?? '이 두 사람의 조합에서 가장 특이한 점은?',
      answer: parsed['answer'] as String? ?? raw,
      source: QuestionSource.remoteAi,
      questionType: questionType,
      generatedAt: DateTime.now(),
    );
  }

  // ── 멀티 프로바이더 fallback chain ─────────────────────────────────────────
  // Env.aiProviderOrder 순서대로 시도: gemini → openai → anthropic → local
  // - AiQuotaExceededException 은 상위 catch에서 사용자 토스트 표시 후 fallback.
  // - 다른 예외는 다음 프로바이더로 자동 전환.
  // - 모든 프로바이더 실패 시 예외 던짐 → 호출부에서 local fallback 처리.

  bool _hasAnyApiKey() =>
      Env.geminiApiKey.isNotEmpty ||
      Env.openAiApiKey.isNotEmpty ||
      Env.anthropicApiKey.isNotEmpty;

  Future<String> _sendRequest(
    String userMessage, {
    required String systemPrompt,
    double temperature = 0.9,
    int maxTokens = 400,
  }) async {
    final order = _resolveProviderOrder();
    Exception? lastError;

    for (final provider in order) {
      try {
        return await _callProvider(
          provider,
          userMessage,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      } on AiQuotaExceededException {
        // quota 초과는 다음 provider로 넘기되, 예외 타입 그대로 전파해
        // 호출 스택 위쪽(화면 catch)에서 토스트를 띄울 수 있게 한다.
        if (kDebugMode) {
          debugPrint(
            '[AiQuestionRepository] $provider quota 초과 → 다음 프로바이더 시도',
          );
        }
        // 다음 provider가 없으면 quota 예외가 사용자에게 전달되어야 하므로
        // lastError에 기록하되 루프 계속.
        lastError = AiQuotaExceededException(provider);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[AiQuestionRepository] $provider 실패: $e → 다음 프로바이더 시도');
        }
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw lastError ?? Exception('모든 AI 프로바이더 실패');
  }

  List<String> _resolveProviderOrder() {
    final order = Env.aiProviderOrder;
    // 키 없는 프로바이더 제거
    return order.where((p) {
      if (p == 'gemini') return Env.geminiApiKey.isNotEmpty;
      if (p == 'openai') return Env.openAiApiKey.isNotEmpty;
      if (p == 'anthropic') return Env.anthropicApiKey.isNotEmpty;
      return false;
    }).toList();
  }

  Future<String> _callProvider(
    String provider,
    String userMessage, {
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    switch (provider) {
      case 'gemini':
        return _client.postGemini(
          apiKey: Env.geminiApiKey,
          model: Env.aiModelGemini,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      case 'openai':
        return _client.postOpenAi(
          apiKey: Env.openAiApiKey,
          model: Env.aiModelOpenAi,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      case 'anthropic':
        return _client.postAnthropic(
          apiKey: Env.anthropicApiKey,
          model: Env.aiModelAnthropic,
          systemPrompt: systemPrompt,
          userMessage: userMessage,
          maxTokens: maxTokens,
        );
      default:
        throw Exception('알 수 없는 AI 프로바이더: $provider');
    }
  }

  /// AI 응답에서 JSON 객체를 안정적으로 추출·파싱한다.
  ///
  /// 처리 순서:
  ///   1. trim
  ///   2. ` ```json ... ``` ` 마크다운 코드블록 제거
  ///   3. 첫 `{` ~ 마지막 `}` 사이 JSON 객체 부분만 추출
  ///      → "Here is the JSON: {...}" 같은 자연어 앞에 붙는 케이스 처리
  ///   4. jsonDecode 시도
  ///   5. 실패 시 [FormatException] throw → 호출부에서 fallback 처리
  Map<String, dynamic> _parseResponse(String raw) {
    if (kDebugMode) {
      final preview = raw.length > 120 ? '${raw.substring(0, 120)}…' : raw;
      debugPrint('[AiResponseParser] raw(${raw.length}자) preview: $preview');
    }

    var cleaned = raw.trim();

    // Step 1: 마크다운 코드블록 제거
    if (cleaned.contains('```')) {
      cleaned = cleaned.replaceAll(RegExp(r'```(?:json)?\s*'), '').trim();
    }

    // Step 2: 첫 { ~ 마지막 } 사이만 추출 (앞뒤 자연어 제거)
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    try {
      final result = jsonDecode(cleaned) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('[AiResponseParser] JSON 파싱 성공');
      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AiResponseParser] JSON 파싱 실패: $e');
      }
      rethrow;
    }
  }

  /// [_parseResponse] 실패 시 raw text를 단일 필드로 재활용하는 fallback 파서.
  ///
  /// Gemini/OpenAI가 JSON 포맷을 완전히 무시하고 자연어만 반환한 경우,
  /// 해당 텍스트를 [fieldName] 필드 값으로 감싸서 반환한다.
  /// 예: fieldName='question' → {"question": "...raw text..."}
  Map<String, dynamic> _parseResponseOrWrapRaw(String raw, String fieldName) {
    try {
      return _parseResponse(raw);
    } catch (_) {
      // JSON 파싱 완전 실패 → raw text를 필드 값으로 사용
      final text = raw.trim();
      if (kDebugMode) {
        debugPrint('[AiResponseParser] fallback — raw text를 "$fieldName" 필드로 사용');
      }
      return {fieldName: text};
    }
  }

  /// 질문 타입 풀에서 seed 기반으로 중복 없이 count개 선택
  List<QuestionType> _pickQuestionTypes(int count, {required int seed}) {
    final pool = List<QuestionType>.from(QuestionType.values);
    final rng = Random(seed);
    pool.shuffle(rng);
    return pool.take(count).toList();
  }

  /// 단일 로컬 fallback 질문 생성
  Future<QuestionItem> _localSingleFallback({
    required String friendUid,
    required String friendNickname,
    required NatalChart friendChart,
    required NatalChart myChart,
    required int index,
  }) async {
    final items = await _local.generate(
      providerPreference: 'local',
      friendUid: friendUid,
      friendName: friendNickname,
      friendSign: friendChart.sunSign,
      mySign: myChart.sunSign,
      revision: index,
    );
    return items.isNotEmpty
        ? items.first
        : QuestionItem(
            id: 'local-fallback-$friendUid-$index',
            prompt: '$friendNickname와 함께라면 어떤 모험을 떠나고 싶어?',
            answer: '두 사람의 조합은 예상치 못한 방향으로 흘러가는 경향이 있어요.',
            source: QuestionSource.localPreset,
          );
  }

  // ── Context 구성 ───────────────────────────────────────────────────────────

  /// OpenAI user message에 넣을 점성술 context 문자열 구성.
  /// 토큰 절약을 위해 핵심 행성(태양/달/금성/수성/화성)과 상위 3개 어스펙트만 포함.
  String _buildContext({
    required String myNickname,
    required NatalChart myChart,
    required String friendNickname,
    required NatalChart friendChart,
    required QuestionType questionType,
    SynastryResult? synastry,
  }) {
    final buf = StringBuffer();

    buf.writeln('=== 두 사람의 점성술 데이터 ===');
    buf.writeln();
    buf.writeln('[나: $myNickname]');
    buf.writeln(_formatBig3(myChart));
    buf.writeln(_formatKeyPlanets(myChart));
    buf.writeln();
    buf.writeln('[친구: $friendNickname]');
    buf.writeln(_formatBig3(friendChart));
    buf.writeln(_formatKeyPlanets(friendChart));
    buf.writeln();

    if (synastry != null) {
      buf.writeln('[궁합 점수]');
      buf.writeln(
        '감정: ${synastry.emotionScore}% / 대화: ${synastry.communicationScore}% / '
        '연애: ${synastry.romanceScore}% / 우정: ${synastry.friendshipScore}%',
      );
      buf.writeln('총점: ${synastry.totalScore}%');
      if (synastry.strengths.isNotEmpty) {
        buf.writeln('강점: ${synastry.strengths.take(2).join(' / ')}');
      }
      if (synastry.challenges.isNotEmpty) {
        buf.writeln('주의 포인트: ${synastry.challenges.take(1).join(' / ')}');
      }
      buf.writeln();
    }

    // 두 차트 간 주요 어스펙트 (orb 작은 것 상위 3개)
    final crossAspects = _findCrossAspects(myChart, friendChart);
    if (crossAspects.isNotEmpty) {
      buf.writeln('[두 사람 사이 주요 어스펙트]');
      for (final a in crossAspects) {
        buf.writeln('- ${_planetKo(a.planetA)} ${_aspectKo(a.aspect)} ${_planetKo(a.planetB)} (orb ${a.orb.toStringAsFixed(1)}°)');
      }
      buf.writeln();
    }

    buf.writeln('[생성할 질문 타입]: ${_questionTypeGuide(questionType)}');

    return buf.toString();
  }

  String _formatBig3(NatalChart chart) =>
      '태양 ${_signKo(chart.sunSign)} / 달 ${_signKo(chart.moonSign)} / 상승 ${_signKo(chart.ascendantSign)}';

  String _formatKeyPlanets(NatalChart chart) {
    final keyNames = ['Venus', 'Mercury', 'Mars'];
    final lines = <String>[];
    for (final name in keyNames) {
      final planet = chart.planets
          .where((p) => p.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (planet != null) {
        final house = planet.house != null ? ' (${planet.house}하우스)' : '';
        lines.add('${_planetKo(name)} ${_signKo(planet.sign)}$house');
      }
    }
    return lines.isEmpty ? '' : lines.join(' / ');
  }

  /// 두 차트에서 같은 행성 이름의 교차 어스펙트 시뮬레이션.
  /// 실제 시너스트리 어스펙트가 없으면 태양-태양, 달-달 degree 차이로 근사.
  List<Aspect> _findCrossAspects(NatalChart me, NatalChart friend) {
    // 같은 이름 행성 쌍의 degree 차이 → 어스펙트 근사 계산
    final pairs = <Aspect>[];
    final priorityPlanets = ['Sun', 'Moon', 'Venus', 'Mercury', 'Mars'];

    for (final name in priorityPlanets) {
      final myPlanet = me.planets
          .where((p) => p.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      final friendPlanet = friend.planets
          .where((p) => p.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      if (myPlanet == null || friendPlanet == null) continue;

      final diff = (myPlanet.degree - friendPlanet.degree).abs();
      final normalized = diff > 180 ? 360 - diff : diff;
      final aspect = _degreeToAspect(normalized);
      if (aspect != null) {
        pairs.add(Aspect(
          planetA: name,
          planetB: name,
          aspect: aspect,
          orb: (normalized - _aspectIdealDegree(aspect)).abs(),
        ));
      }
    }

    pairs.sort((a, b) => a.orb.compareTo(b.orb));
    return pairs.take(3).toList();
  }

  String? _degreeToAspect(double deg) {
    if (deg <= 10) return 'Conjunction';
    if ((deg - 60).abs() <= 6) return 'Sextile';
    if ((deg - 90).abs() <= 8) return 'Square';
    if ((deg - 120).abs() <= 8) return 'Trine';
    if ((deg - 180).abs() <= 10) return 'Opposition';
    return null;
  }

  double _aspectIdealDegree(String aspect) {
    switch (aspect) {
      case 'Conjunction': return 0;
      case 'Sextile': return 60;
      case 'Square': return 90;
      case 'Trine': return 120;
      case 'Opposition': return 180;
      default: return 0;
    }
  }

  String _questionTypeGuide(QuestionType type) {
    switch (type) {
      case QuestionType.balanceGame:
        return 'balanceGame — "A vs B 둘 중 하나 선택" 형식의 밸런스 게임';
      case QuestionType.situationPrediction:
        return 'situationPrediction — 구체적인 상황(여행/프로젝트/위기 등)에서 두 사람 예측';
      case QuestionType.personalityReveal:
        return 'personalityReveal — 가벼운 듯 보이지만 성향이 은근히 드러나는 질문';
      case QuestionType.funnyCompatibility:
        return 'funnyCompatibility — 이 두 별자리 조합에서만 나오는 웃긴 포인트';
      case QuestionType.emotionStyle:
        return 'emotionStyle — 갈등/감정 상황에서 두 사람의 극명한 차이';
      case QuestionType.creativeScenario:
        return 'creativeScenario — 황당하지만 재밌는 가상 상황 (좀비, 우주, 드라마 등)';
    }
  }

  String _buildDailyHoroscopeContext({
    required String nickname,
    required NatalChart chart,
    required DateTime targetDate,
    required String timezone,
    String? placeName,
  }) {
    final buf = StringBuffer();
    buf.writeln('=== 오늘의 운세 생성용 점성술 데이터 ===');
    buf.writeln('이름: $nickname');
    buf.writeln('날짜: ${targetDate.toIso8601String().split('T').first}');
    buf.writeln('시간대: $timezone');
    if (placeName != null && placeName.trim().isNotEmpty) {
      buf.writeln('출생지: ${placeName.trim()}');
    }
    buf.writeln();
    buf.writeln('[핵심 Big 3]');
    buf.writeln(_formatBig3(chart));
    final keyPlanets = _formatKeyPlanets(chart);
    if (keyPlanets.isNotEmpty) {
      buf.writeln('[주요 행성]');
      buf.writeln(keyPlanets);
    }
    final aspects = chart.aspects.take(3).map(
      (aspect) =>
          '- ${_planetKo(aspect.planetA)} ${_aspectKo(aspect.aspect)} ${_planetKo(aspect.planetB)} (orb ${aspect.orb.toStringAsFixed(1)}°)',
    );
    if (aspects.isNotEmpty) {
      buf.writeln('[주요 어스펙트]');
      for (final aspect in aspects) {
        buf.writeln(aspect);
      }
    }
    return buf.toString();
  }

  // ── 텍스트 변환 유틸 ────────────────────────────────────────────────────────
  String _signKo(String sign) => zodiacNameKo(sign.toLowerCase());
  String _planetKo(String planet) {
    const map = {
      'sun': '태양', 'moon': '달', 'mercury': '수성', 'venus': '금성',
      'mars': '화성', 'jupiter': '목성', 'saturn': '토성',
    };
    return map[planet.toLowerCase()] ?? planet;
  }

  String _aspectKo(String aspect) {
    const map = {
      'conjunction': '합(☌)', 'trine': '삼분(△)', 'square': '사분(□)',
      'sextile': '육분(⚹)', 'opposition': '대립(☍)',
    };
    return map[aspect.toLowerCase()] ?? aspect;
  }
}

// ── HTTP 래퍼 ─────────────────────────────────────────────────────────────────
// `http` 패키지 사용 — Android/iOS/Web 모두 지원.
// dio는 astrology feature 전용이므로 cross-feature 오염 방지 목적으로 분리.
//
// ⚠️ 보안 주의: 현재 세 API 모두 Flutter 클라이언트에서 직접 호출합니다.
//    .env 파일이 flutter_assets에 번들되어 APK/IPA 추출 시 키 노출 위험이 있습니다.
//    TODO: 프로덕션 배포 전 Firebase Functions 또는 백엔드 프록시로 이전 권장.

class HttpClientWrapper {
  // ── Gemini generateContent API ────────────────────────────────────────────
  // 공식 문서: https://ai.google.dev/api/generate-content
  // 모델: gemini-2.0-flash (기본), gemini-1.5-pro 등 변경 가능.
  // systemInstruction + user contents 구조 사용.
  Future<String> postGemini({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    required double temperature,
    required int maxTokens,
  }) async {
    if (kDebugMode) debugPrint('[Gemini] 요청 시작: $model');

    final url = _kGeminiEndpointTemplate
        .replaceFirst('{model}', model)
        .replaceFirst('{apiKey}', apiKey);

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userMessage},
            ],
          },
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
          // 순수 JSON만 반환 — 마크다운 코드블록(```json ... ```) 감싸기 방지
          'responseMimeType': 'application/json',
          // gemini-2.5-flash 등 thinking 모델에서 thinkingBudget=0 으로 thinking 비활성화.
          // thinking 모드가 활성화되면 responseMimeType 이 무시되고
          // "Here is the JSON requested:" 같은 자연어 preamble이 앞에 붙는다.
          // thinking 을 끄면 JSON 강제 설정이 정상 동작한다.
          // non-thinking 모델에서는 이 필드가 무시된다.
          'thinkingConfig': {
            'thinkingBudget': 0,
          },
        },
      }),
    );

    if (response.statusCode == 429) {
      // Gemini quota 초과 (RESOURCE_EXHAUSTED)
      if (kDebugMode) {
        debugPrint('[Gemini] 429 quota 초과: ${response.body}');
      }
      throw AiQuotaExceededException('gemini');
    }

    if (response.statusCode == 404) {
      // 모델명이 잘못됐거나 deprecated된 경우 → OpenAI fallback으로 넘어가도록 일반 예외 throw.
      // 사용자에게는 노출하지 않고 개발 로그에만 남긴다.
      if (kDebugMode) {
        debugPrint(
          '[Gemini] 404 모델 미지원: $model\n'
          '→ .env의 AI_MODEL_GEMINI_DEFAULT 값을 확인하세요.\n'
          '→ 지원 모델 목록: https://ai.google.dev/gemini-api/docs/models',
        );
      }
      throw Exception('Gemini 모델($model) 미지원 — OpenAI fallback');
    }

    if (response.statusCode != 200) {
      throw Exception('Gemini API 오류 ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Gemini 응답 body 파싱 실패: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
    }

    // safety filter 등으로 candidates 가 없는 경우 처리
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      // promptFeedback 에 blockReason 이 있으면 로그 출력
      final feedback = json['promptFeedback'] as Map<String, dynamic>?;
      final blockReason = feedback?['blockReason'] as String?;
      if (kDebugMode) {
        debugPrint('[Gemini] candidates 없음. blockReason=${blockReason ?? 'none'}');
      }
      throw Exception('Gemini 응답에 candidates가 없습니다 (blockReason=$blockReason)');
    }

    // candidates[0].content.parts[0].text 안전 추출
    final firstCandidate = candidates.first as Map<String, dynamic>?;
    final finishReason = firstCandidate?['finishReason'] as String?;
    final contentMap = firstCandidate?['content'] as Map<String, dynamic>?;
    final parts = contentMap?['parts'] as List<dynamic>?;
    final firstPart = (parts != null && parts.isNotEmpty)
        ? parts.first as Map<String, dynamic>?
        : null;
    final textRaw = firstPart?['text'];

    if (textRaw == null) {
      if (kDebugMode) {
        debugPrint('[Gemini] text 추출 실패. finishReason=$finishReason candidate=$firstCandidate');
      }
      throw Exception('Gemini 응답에서 text를 추출할 수 없습니다 (finishReason=$finishReason)');
    }

    final text = textRaw.toString();
    if (kDebugMode) debugPrint('[Gemini] 응답 완료 (${text.length}자)');
    return text;
  }

  // ── OpenAI Chat Completions ────────────────────────────────────────────────
  Future<String> postOpenAi({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    required double temperature,
    required int maxTokens,
  }) async {
    if (kDebugMode) debugPrint('[OpenAI] 요청 시작: $model');

    final response = await http.post(
      Uri.parse(_kOpenAiChatEndpoint),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode == 429) {
      // OpenAI quota 초과 (insufficient_quota 또는 rate limit)
      if (kDebugMode) {
        debugPrint('[OpenAI] 429 quota 초과: ${response.body}');
      }
      throw AiQuotaExceededException('openai');
    }

    if (response.statusCode != 200) {
      throw Exception('OpenAI API 오류 ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('OpenAI 응답 body 파싱 실패');
    }
    final choices = json['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('OpenAI 응답에 choices가 없습니다');
    }
    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content']?.toString() ?? '';
    if (content.isEmpty) {
      throw Exception('OpenAI 응답 content가 비어있습니다');
    }

    if (kDebugMode) debugPrint('[OpenAI] 응답 완료 (${content.length}자)');
    return content;
  }

  // ── Anthropic Messages API ─────────────────────────────────────────────────
  Future<String> postAnthropic({
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userMessage,
    required int maxTokens,
  }) async {
    if (kDebugMode) debugPrint('[Anthropic] 요청 시작: $model');

    final response = await http.post(
      Uri.parse(_kAnthropicChatEndpoint),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'x-api-key': apiKey,
        'anthropic-version': _kAnthropicVersion,
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': maxTokens,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    );

    if (response.statusCode == 429) {
      if (kDebugMode) {
        debugPrint('[Anthropic] 429 quota 초과: ${response.body}');
      }
      throw AiQuotaExceededException('anthropic');
    }

    if (response.statusCode != 200) {
      throw Exception('Anthropic API 오류 ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Anthropic 응답 body 파싱 실패');
    }
    final contentList = json['content'] as List<dynamic>?;
    if (contentList == null || contentList.isEmpty) {
      throw Exception('Anthropic 응답에 content가 없습니다');
    }
    final content = (contentList.first as Map<String, dynamic>?)?['text']?.toString() ?? '';
    if (content.isEmpty) {
      throw Exception('Anthropic 응답 text가 비어있습니다');
    }

    if (kDebugMode) debugPrint('[Anthropic] 응답 완료 (${content.length}자)');
    return content;
  }
}

// ── 예외 클래스 ───────────────────────────────────────────────────────────────

/// AI 프로바이더의 사용량(quota/rate limit) 초과를 나타내는 예외.
///
/// HTTP 429 응답 시 던져지며, 화면 catch 블록에서 사용자 친화적 토스트를 표시하는 데 사용됩니다.
/// [provider]: 초과가 발생한 프로바이더 이름 ('gemini' | 'openai' | 'anthropic')
class AiQuotaExceededException implements Exception {
  const AiQuotaExceededException(this.provider);

  final String provider;

  @override
  String toString() =>
      'AiQuotaExceededException: $provider API 사용량이 초과되었습니다 (HTTP 429).';
}
