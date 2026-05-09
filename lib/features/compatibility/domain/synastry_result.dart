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

  /// 디스크 캐시(L2) 직렬화. `lib/core/cache/disk_cache.dart` 가 사용.
  Map<String, dynamic> toJson() => {
        'totalScore': totalScore,
        'emotionScore': emotionScore,
        'communicationScore': communicationScore,
        'romanceScore': romanceScore,
        'summary': summary,
      };

  factory SynastryResult.fromJson(Map<String, dynamic> json) => SynastryResult(
        totalScore: (json['totalScore'] as num).toInt(),
        emotionScore: (json['emotionScore'] as num).toInt(),
        communicationScore: (json['communicationScore'] as num).toInt(),
        romanceScore: (json['romanceScore'] as num).toInt(),
        summary: json['summary'] as String,
      );
}
