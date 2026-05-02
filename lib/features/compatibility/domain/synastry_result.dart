// lib/features/compatibility/domain/synastry_result.dart
//
// 두 사람의 출생 차트 비교 결과(궁합).

class SynastryResult {
  const SynastryResult({
    required this.totalScore,
    required this.emotionScore,
    required this.communicationScore,
    required this.romanceScore,
    required this.summary,
  });

  /// 0~100 (%) 총 점수.
  final int totalScore;
  final int emotionScore;
  final int communicationScore;
  final int romanceScore;

  /// 궁합 요약 한 단락.
  final String summary;
}
