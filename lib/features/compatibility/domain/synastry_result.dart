// lib/features/compatibility/domain/synastry_result.dart
//
// 두 사람의 출생 차트 비교 결과(궁합).

class SynastryResult {
  const SynastryResult({
    required this.totalScore,
    required this.emotionScore,
    required this.communicationScore,
    required this.romanceScore,
    required this.friendshipScore,
    required this.summary,
    required this.emotionalMatch,
    required this.communicationStyle,
    required this.romanticMatch,
    required this.friendshipMatch,
    required this.strengths,
    required this.challenges,
    required this.source,
    required this.engineVersion,
    this.pairKey,
    this.chartPairVersion,
  });

  /// 0~100 (%) 총 점수.
  final int totalScore;
  final int emotionScore;
  final int communicationScore;
  final int romanceScore;
  final int friendshipScore;

  /// 궁합 요약 한 단락.
  final String summary;
  final String emotionalMatch;
  final String communicationStyle;
  final String romanticMatch;
  final String friendshipMatch;
  final List<String> strengths;
  final List<String> challenges;
  final String source;
  final String engineVersion;
  final String? pairKey;
  final String? chartPairVersion;

  /// 디스크 캐시(L2) 직렬화. `lib/core/cache/disk_cache.dart` 가 사용.
  Map<String, dynamic> toJson() => {
        'totalScore': totalScore,
        'emotionScore': emotionScore,
        'communicationScore': communicationScore,
        'romanceScore': romanceScore,
        'friendshipScore': friendshipScore,
        'summary': summary,
        'emotionalMatch': emotionalMatch,
        'communicationStyle': communicationStyle,
        'romanticMatch': romanticMatch,
        'friendshipMatch': friendshipMatch,
        'strengths': strengths,
        'challenges': challenges,
        'source': source,
        'engineVersion': engineVersion,
        'pairKey': pairKey,
        'chartPairVersion': chartPairVersion,
      };

  factory SynastryResult.fromJson(Map<String, dynamic> json) {
    final emotion = _readInt(json['emotionScore']);
    final communication = _readInt(json['communicationScore']);
    final romance = _readInt(json['romanceScore']);
    final friendship = _readInt(
      json['friendshipScore'],
      fallback: ((emotion + communication + romance) / 3).round(),
    );
    final total = _readInt(
      json['totalScore'],
      fallback: ((emotion + communication + romance + friendship) / 4).round(),
    );

    return SynastryResult(
      totalScore: total,
      emotionScore: emotion,
      communicationScore: communication,
      romanceScore: romance,
      friendshipScore: friendship,
      summary: _readString(json['summary']),
      emotionalMatch: _readString(
        json['emotionalMatch'],
        fallback: _legacyCategoryText('감정', emotion),
      ),
      communicationStyle: _readString(
        json['communicationStyle'],
        fallback: _legacyCategoryText('대화', communication),
      ),
      romanticMatch: _readString(
        json['romanticMatch'],
        fallback: _legacyCategoryText('연애', romance),
      ),
      friendshipMatch: _readString(
        json['friendshipMatch'],
        fallback: _legacyCategoryText('우정', friendship),
      ),
      strengths: _readStringList(json['strengths']),
      challenges: _readStringList(json['challenges']),
      source: _readString(json['source'], fallback: 'legacy-cache'),
      engineVersion: _readString(json['engineVersion'], fallback: 'compat.v1'),
      pairKey: _readNullableString(json['pairKey']),
      chartPairVersion: _readNullableString(json['chartPairVersion']),
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  static String? _readNullableString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Object?>()
        .map((e) => e?.toString() ?? '')
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  static String _legacyCategoryText(String category, int score) {
    switch (category) {
      case '감정':
        if (score >= 80) return '서로의 감정을 잘 이해하고 공감합니다';
        if (score >= 60) return '감정적 교류가 자연스럽게 이루어집니다';
        return '감정 표현에 서로 노력이 필요해요';
      case '대화':
        if (score >= 80) return '대화가 끊이지 않고 자연스럽게 이어집니다';
        if (score >= 60) return '대화 흐름이 비교적 잘 맞아요';
        return '대화 방식의 차이를 줄여나가면 좋아요';
      case '연애':
        if (score >= 80) return '로맨틱한 분위기를 만들 수 있습니다';
        if (score >= 60) return '연애 감각이 잘 맞는 편이에요';
        return '서로의 방식을 이해하면 더 가까워질 수 있어요';
      case '우정':
        if (score >= 80) return '함께 있을 때 텐션이 잘 맞는 편이에요';
        if (score >= 60) return '친구로서 꽤 편안한 합을 만들 수 있어요';
        return '친해지기까지 시간이 조금 필요할 수 있어요';
      default:
        return '';
    }
  }
}
