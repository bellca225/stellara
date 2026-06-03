// lib/features/compatibility/fixtures/synastry_fixture.dart

import '../domain/synastry_result.dart';

SynastryResult demoSynastry() {
  return const SynastryResult(
    totalScore: 78,
    emotionScore: 84,
    communicationScore: 71,
    romanceScore: 80,
    friendshipScore: 76,
    summary:
        '서로의 결이 비교적 잘 맞는 편이라 감정적인 온기가 자연스럽게 이어집니다. '
        '함께하는 일상은 편안하게 흘러가기 쉽고, 대화에서는 조금만 더 의식적으로 마음을 확인해 주면 관계가 훨씬 안정적으로 깊어질 수 있습니다.',
    emotionalMatch: '서로의 감정을 잘 이해하고 공감합니다.',
    communicationStyle: '대화 흐름이 비교적 잘 맞아요.',
    romanticMatch: '로맨틱한 분위기를 만들 수 있습니다.',
    friendshipMatch: '함께 있을 때 텐션이 잘 맞는 편이에요.',
    strengths: <String>[
      '감정적인 온기가 자연스럽게 이어지는 편이에요.',
      '대화가 비교적 부드럽게 이어질 가능성이 높아요.',
    ],
    challenges: <String>[
      '속도 차이가 날 때는 표현을 한 번 더 확인해주는 것이 좋아요.',
    ],
    source: 'fixture',
    engineVersion: 'compat.fixture',
  );
}
