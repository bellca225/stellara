import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/content/data/question_repository.dart';
import 'package:stellara/features/content/domain/question_item.dart';

void main() {
  group('QuestionRepository', () {
    final repo = QuestionRepository();

    test(
      'generates three deterministic local questions for a friend',
      () async {
        final first = await repo.generate(
          providerPreference: 'local',
          friendUid: 'friend-1',
          friendName: '도연',
          friendSign: 'aquarius',
          mySign: 'leo',
          revision: 0,
        );
        final second = await repo.generate(
          providerPreference: 'local',
          friendUid: 'friend-1',
          friendName: '도연',
          friendSign: 'aquarius',
          mySign: 'leo',
          revision: 0,
        );

        expect(first, hasLength(3));
        expect(first.map((item) => item.prompt).toSet().length, 3);
        expect(
          first.every((item) => item.source == QuestionSource.localPreset),
          isTrue,
        );
        expect(
          first.map((item) => item.prompt).toList(),
          second.map((item) => item.prompt).toList(),
        );
      },
    );

    test('can generate a single local question for figma flow', () async {
      final questions = await repo.generate(
        providerPreference: 'local',
        friendUid: 'friend-1',
        friendName: '도연',
        friendSign: 'aquarius',
        mySign: 'leo',
        count: 1,
        revision: 2,
      );

      expect(questions, hasLength(1));
      expect(questions.single.prompt, contains('도연'));
      expect(questions.single.answer, isNotEmpty);
    });

    test('builds a local custom answer from direct user prompt', () async {
      final item = await repo.answerCustom(
        providerPreference: 'local',
        friendUid: 'friend-2',
        friendName: '서연',
        friendSign: 'pisces',
        mySign: 'virgo',
        userPrompt: '서연의 매력 포인트가 궁금해',
      );

      expect(item.source, QuestionSource.localCustom);
      expect(item.prompt, '서연의 매력 포인트가 궁금해');
      expect(item.answer, contains('서연'));
      expect(item.answer, contains('물고기자리'));
    });
  });
}
