import 'question_item.dart';

enum RandomQuestionSessionStatus {
  questionReady,
  answerReady,
}

class RandomQuestionSession {
  const RandomQuestionSession({
    required this.sessionId,
    required this.pairKey,
    required this.chartPairVersion,
    required this.myUid,
    required this.friendUid,
    required this.friendDisplayName,
    required this.revision,
    required this.question,
    required this.status,
    required this.promptVersion,
    required this.generatedAt,
    required this.updatedAt,
    this.docId,
    this.contextSnapshot = const {},
  });

  final String sessionId;
  final String pairKey;
  final String chartPairVersion;
  final String myUid;
  final String friendUid;
  final String friendDisplayName;
  final int revision;
  final QuestionItem question;
  final RandomQuestionSessionStatus status;
  final String promptVersion;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final String? docId;
  final Map<String, dynamic> contextSnapshot;

  bool get hasAnswer => question.hasAnswer;
  bool get isRemoteAi => question.isAiGenerated;

  RandomQuestionSession copyWith({
    String? sessionId,
    String? pairKey,
    String? chartPairVersion,
    String? myUid,
    String? friendUid,
    String? friendDisplayName,
    int? revision,
    QuestionItem? question,
    RandomQuestionSessionStatus? status,
    String? promptVersion,
    DateTime? generatedAt,
    DateTime? updatedAt,
    String? docId,
    Map<String, dynamic>? contextSnapshot,
  }) {
    return RandomQuestionSession(
      sessionId: sessionId ?? this.sessionId,
      pairKey: pairKey ?? this.pairKey,
      chartPairVersion: chartPairVersion ?? this.chartPairVersion,
      myUid: myUid ?? this.myUid,
      friendUid: friendUid ?? this.friendUid,
      friendDisplayName: friendDisplayName ?? this.friendDisplayName,
      revision: revision ?? this.revision,
      question: question ?? this.question,
      status: status ?? this.status,
      promptVersion: promptVersion ?? this.promptVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      docId: docId ?? this.docId,
      contextSnapshot: contextSnapshot ?? this.contextSnapshot,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'pairKey': pairKey,
        'chartPairVersion': chartPairVersion,
        'myUid': myUid,
        'friendUid': friendUid,
        'friendDisplayName': friendDisplayName,
        'userIds': [myUid, friendUid]..sort(),
        'revision': revision,
        'question': question.toJson(),
        'status': status.name,
        'promptVersion': promptVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'contextSnapshot': contextSnapshot,
      };

  factory RandomQuestionSession.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return RandomQuestionSession(
      sessionId: json['sessionId'] as String? ?? '',
      pairKey: json['pairKey'] as String? ?? '',
      chartPairVersion: json['chartPairVersion'] as String? ?? '',
      myUid: json['myUid'] as String? ?? '',
      friendUid: json['friendUid'] as String? ?? '',
      friendDisplayName: json['friendDisplayName'] as String? ?? '',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      question: QuestionItem.fromJson(
        Map<String, dynamic>.from(
          (json['question'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
      ),
      status: RandomQuestionSessionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RandomQuestionSessionStatus.questionReady,
      ),
      promptVersion: json['promptVersion'] as String? ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      docId: docId,
      contextSnapshot:
          Map<String, dynamic>.from(
            (json['contextSnapshot'] as Map?)?.cast<String, dynamic>() ??
                const {},
          ),
    );
  }
}
