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

[출력 형식 - 반드시 이 JSON만 반환]
{
  "question": "질문 텍스트 (1~2문장, 구체적이고 흥미로운)",
  "answer": "해설 텍스트 (3~5문장, 점성술 근거 포함, 유머 포함)"
}

JSON 외 다른 텍스트는 절대 포함하지 마세요.
''';

const _kRandomQuestionSystemPrompt = '''
당신은 점성술 기반 친구 관계 질문 생성 AI입니다.

[역할]
두 사람의 점성술 데이터와 관계 맥락을 읽고, 친구끼리 공유하고 싶은 가볍고 창의적인 질문 딱 1개를 JSON으로 생성합니다.

[톤]
- 너무 진지하지 않고 재밌는 한국어
- 친구 displayName만 사용하고 loginId는 절대 쓰지 않음
- 질문만 보고도 웃기거나 답해보고 싶어야 함
- 점성술 표현은 자연스럽게 녹이고, 겁주거나 단정하지 말 것

[출력 형식]
{
  "question": "질문 텍스트 1개"
}

JSON 외 다른 텍스트는 절대 포함하지 마세요.
''';

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
{
  "answer": "질문에 대한 점성술 기반 답변"
}

JSON 외 다른 텍스트는 절대 포함하지 마세요.
''';

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
{
  "overall": "전체 운세",
  "emotion": "오늘의 감정 상태",
  "luckyNumbers": [7, 14, 21],
  "luckyColor": "보라색",
  "luckyPlace": "카페, 도서관",
  "advice": "오늘의 조언",
  "caution": "주의할 점",
  "shareText": "공유용 짧은 문구"
}

JSON 외 다른 텍스트는 절대 포함하지 마세요.
''';

const _kRandomQuestionPromptVersion = 'rq-question-v2';
const _kRandomAnswerPromptVersion = 'rq-answer-v2';
const _kDailyHoroscopePromptVersion = 'daily-horoscope-v2';

// ── API 엔드포인트 ───────────────────────────────────────────────────────────
const _kOpenAiChatEndpoint = 'https://api.openai.com/v1/chat/completions';
const _kAnthropicChatEndpoint = 'https://api.anthropic.com/v1/messages';
const _kAnthropicVersion = '2023-06-01';

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
      final parsed = _parseResponse(raw);

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
      final parsed = _parseResponse(raw);
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
      final parsed = _parseResponse(raw);
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
    final parsed = _parseResponse(raw);

    final luckyNumbers = <int>[
      for (final value in (parsed['luckyNumbers'] as List? ?? const []))
        if (value is num) value.toInt(),
    ];

    if ((parsed['overall'] as String?)?.trim().isEmpty ?? true) {
      throw const FormatException('overall missing');
    }

    return AiDailyHoroscopePayload(
      overall: (parsed['overall'] as String).trim(),
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
    final parsed = _parseResponse(raw);

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
  // Env.aiProviderOrder 순서대로 시도: openai → anthropic → local
  // 각 프로바이더가 실패하면 다음으로 자동 전환. 모두 실패 시 예외 던짐.

  bool _hasAnyApiKey() =>
      Env.openAiApiKey.isNotEmpty || Env.anthropicApiKey.isNotEmpty;

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

  /// GPT 응답 JSON 파싱. 마크다운 코드블록 감싸진 경우도 처리.
  Map<String, dynamic> _parseResponse(String raw) {
    // ```json ... ``` 블록 제거
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      final firstNewline = cleaned.indexOf('\n');
      final lastFence = cleaned.lastIndexOf('```');
      if (firstNewline != -1 && lastFence > firstNewline) {
        cleaned = cleaned.substring(firstNewline + 1, lastFence).trim();
      }
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
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

class HttpClientWrapper {
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

    if (response.statusCode != 200) {
      throw Exception('OpenAI API 오류 ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    final content =
        (choices.first as Map<String, dynamic>)['message']['content'] as String;

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

    if (response.statusCode != 200) {
      throw Exception('Anthropic API 오류 ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final contentList = json['content'] as List<dynamic>;
    final content =
        (contentList.first as Map<String, dynamic>)['text'] as String;

    if (kDebugMode) debugPrint('[Anthropic] 응답 완료 (${content.length}자)');
    return content;
  }
}
