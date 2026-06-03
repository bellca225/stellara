// lib/features/content/domain/question_item.dart
//
// 질문/해설 단위 도메인 모델.
//
// QuestionSource: 질문이 어디서 생성되었는지 추적.
//   - localPreset  : 앱 번들 내 로컬 템플릿 (AI 꺼져 있을 때 fallback)
//   - localCustom  : 사용자가 직접 입력한 커스텀 질문 (로컬 해석)
//   - remoteAi     : OpenAI GPT-4o-mini 원격 생성
//
// QuestionType: 질문의 성격 분류 (AI 프롬프트에서 다양성 확보에 사용).

enum QuestionSource { localPreset, localCustom, remoteAi }

/// AI가 생성하는 질문의 유형.
/// 시스템 프롬프트에서 각 타입별로 다른 생성 가이드를 적용한다.
enum QuestionType {
  /// "A vs B 중 선택?" 밸런스 게임 형식
  balanceGame,

  /// "이 두 사람이 여행 가면?" 상황 예측
  situationPrediction,

  /// "SNS 갑자기 삭제한 이유는?" 은근히 성향 드러내기
  personalityReveal,

  /// "이 조합의 가장 웃긴 점은?" 궁합 유머 포인트
  funnyCompatibility,

  /// "싸웠을 때 각자 반응은?" 감정 스타일 차이
  emotionStyle,

  /// "좀비 아포칼립스에서 역할은?" 창의적 가상 상황
  creativeScenario,
}

class QuestionItem {
  const QuestionItem({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.source,
    this.questionType,
    this.sessionId,
    this.generatedAt,
  });

  final String id;

  /// 화면에 표시되는 질문 텍스트
  final String prompt;

  /// AI 또는 로컬이 생성한 해설 텍스트
  final String answer;

  /// 생성 출처
  final QuestionSource source;

  /// 질문 유형 — remoteAi 질문에만 채워짐. 로컬은 null.
  final QuestionType? questionType;

  /// Firestore 세션 ID — 캐시 추적용. 로컬은 null.
  final String? sessionId;

  /// 생성 시각 — 캐시 만료 계산용
  final DateTime? generatedAt;

  bool get hasAnswer => answer.trim().isNotEmpty;
  bool get isCustom => source == QuestionSource.localCustom;
  bool get isAiGenerated => source == QuestionSource.remoteAi;

  QuestionItem copyWith({
    String? id,
    String? prompt,
    String? answer,
    QuestionSource? source,
    QuestionType? questionType,
    String? sessionId,
    DateTime? generatedAt,
  }) {
    return QuestionItem(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      answer: answer ?? this.answer,
      source: source ?? this.source,
      questionType: questionType ?? this.questionType,
      sessionId: sessionId ?? this.sessionId,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'answer': answer,
        'source': source.name,
        'questionType': questionType?.name,
        'sessionId': sessionId,
        'generatedAt': generatedAt?.toIso8601String(),
      };

  factory QuestionItem.fromJson(Map<String, dynamic> json) => QuestionItem(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        answer: json['answer'] as String,
        source: QuestionSource.values.firstWhere(
          (s) => s.name == json['source'],
          orElse: () => QuestionSource.localPreset,
        ),
        questionType: json['questionType'] == null
            ? null
            : QuestionType.values.firstWhere(
                (t) => t.name == json['questionType'],
                orElse: () => QuestionType.situationPrediction,
              ),
        sessionId: json['sessionId'] as String?,
        generatedAt: json['generatedAt'] == null
            ? null
            : DateTime.tryParse(json['generatedAt'] as String),
      );
}
