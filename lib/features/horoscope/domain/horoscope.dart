// lib/features/horoscope/domain/horoscope.dart
//
// 오늘의 운세 도메인 모델.

class Horoscope {
  const Horoscope({
    required this.signSlug,
    required this.signName,
    required this.date,
    required this.summary,
    required this.luckyColor,
    required this.luckyNumber,
    required this.mood,
  });

  final String signSlug; // 'aquarius'
  final String signName; // 'Aquarius'
  final DateTime date;

  /// 운세 본문(한 줄~두 줄 요약).
  final String summary;

  /// 행운 색상(영문/숫자 스트링 예: 'Indigo').
  final String luckyColor;

  /// 행운 숫자.
  final int luckyNumber;

  /// 'Calm', 'Energetic' 등 — 화면에서 chip 으로 표기.
  final String mood;

  /// 디스크 캐시(L2) 직렬화. `lib/core/cache/disk_cache.dart` 가 사용.
  Map<String, dynamic> toJson() => {
        'signSlug': signSlug,
        'signName': signName,
        'date': date.toIso8601String(),
        'summary': summary,
        'luckyColor': luckyColor,
        'luckyNumber': luckyNumber,
        'mood': mood,
      };

  factory Horoscope.fromJson(Map<String, dynamic> json) => Horoscope(
        signSlug: json['signSlug'] as String,
        signName: json['signName'] as String,
        date: DateTime.parse(json['date'] as String),
        summary: json['summary'] as String,
        luckyColor: json['luckyColor'] as String,
        luckyNumber: (json['luckyNumber'] as num).toInt(),
        mood: json['mood'] as String,
      );
}
