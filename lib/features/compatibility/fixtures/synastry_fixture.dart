// lib/features/compatibility/fixtures/synastry_fixture.dart

import '../domain/synastry_result.dart';

SynastryResult demoSynastry() {
  return const SynastryResult(
    totalScore: 78,
    emotionScore: 84,
    communicationScore: 71,
    romanceScore: 80,
    summary:
        '서로의 결이 비교적 잘 맞는 편이라 감정적인 온기가 자연스럽게 이어집니다. '
        '함께하는 일상은 편안하게 흘러가기 쉽고, 대화에서는 조금만 더 의식적으로 마음을 확인해 주면 관계가 훨씬 안정적으로 깊어질 수 있습니다.',
  );
}
