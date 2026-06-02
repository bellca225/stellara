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
const _kSystemPrompt = '''
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

// ── API 엔드포인트 ───────────────────────────────────────────────────────────
const _kOpenAiChatEndpoint = 'https://api.openai.com/v1/chat/completions';
const _kAnthropicChatEndpoint = 'https://api.anthropic.com/v1/messages';
const _kAnthropicVersion = '2023-06-01';

class AiQuestionRepository {
  AiQuestionRepository({QuestionRepository? localFallback})
      : _local = localFallback ?? QuestionRepository();

  final QuestionRepository _local;
  final _client = HttpClientWrapper();

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

      final raw = await _sendRequest(userMessage);
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

    final raw = await _sendRequest(context);
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

  Future<String> _sendRequest(String userMessage) async {
    final order = _resolveProviderOrder();
    Exception? lastError;

    for (final provider in order) {
      try {
        return await _callProvider(provider, userMessage);
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

  Future<String> _callProvider(String provider, String userMessage) async {
    switch (provider) {
      case 'openai':
        return _client.postOpenAi(
          apiKey: Env.openAiApiKey,
          model: Env.aiModelOpenAi,
          systemPrompt: _kSystemPrompt,
          userMessage: userMessage,
        );
      case 'anthropic':
        return _client.postAnthropic(
          apiKey: Env.anthropicApiKey,
          model: Env.aiModelAnthropic,
          systemPrompt: _kSystemPrompt,
          userMessage: userMessage,
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
      buf.writeln('감정: ${synastry.emotionScore}% / 대화: ${synastry.communicationScore}% / 연애: ${synastry.romanceScore}%');
      buf.writeln('총점: ${synastry.totalScore}%');
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
        'temperature': 0.9,
        'max_tokens': 400,
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
        'max_tokens': 400,
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

