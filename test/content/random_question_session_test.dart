import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/content/data/random_question_session_repository.dart';
import 'package:stellara/features/content/domain/question_item.dart';
import 'package:stellara/features/content/domain/random_question_session.dart';

void main() {
  test('pair key and doc id are stable regardless of uid order', () {
    final pairA = RandomQuestionSessionRepository.buildPairKey('uid-b', 'uid-a');
    final pairB = RandomQuestionSessionRepository.buildPairKey('uid-a', 'uid-b');
    final docA = RandomQuestionSessionRepository.buildDocId(
      myUid: 'uid-b',
      friendUid: 'uid-a',
      myChartVersion: 'chart-2',
      friendChartVersion: 'chart-1',
    );
    final docB = RandomQuestionSessionRepository.buildDocId(
      myUid: 'uid-a',
      friendUid: 'uid-b',
      myChartVersion: 'chart-1',
      friendChartVersion: 'chart-2',
    );

    expect(pairA, pairB);
    expect(docA, docB);
  });

  test('session json round-trips question and answer state', () {
    final session = RandomQuestionSession(
      docId: 'pair__chart',
      sessionId: 'session-1',
      pairKey: 'uid-a__uid-b',
      chartPairVersion: 'chart-1__chart-2',
      myUid: 'uid-a',
      friendUid: 'uid-b',
      friendDisplayName: '민수',
      revision: 3,
      question: const QuestionItem(
        id: 'question-1',
        prompt: '민수와 여행 가면 누가 더 계획파일까?',
        answer: '겉보기와 달리 네가 더 흐름을 잡을 가능성이 커요.',
        source: QuestionSource.remoteAi,
        sessionId: 'session-1',
      ),
      status: RandomQuestionSessionStatus.answerReady,
      promptVersion: 'rq-question-v2|rq-answer-v2',
      generatedAt: DateTime(2026, 6, 3, 12),
      updatedAt: DateTime(2026, 6, 3, 12, 5),
      contextSnapshot: const {
        'me': {'sun': 'Gemini'},
        'friend': {'sun': 'Leo'},
      },
    );

    final decoded = RandomQuestionSession.fromJson(
      session.toJson(),
      docId: session.docId,
    );

    expect(decoded.docId, 'pair__chart');
    expect(decoded.hasAnswer, isTrue);
    expect(decoded.question.prompt, contains('민수'));
    expect(decoded.promptVersion, contains('rq-question-v2'));
    expect(decoded.contextSnapshot['me'], isA<Map<String, dynamic>>());
  });
}
