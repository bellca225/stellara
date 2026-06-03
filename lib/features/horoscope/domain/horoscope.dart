// lib/features/horoscope/domain/horoscope.dart
//
// 오늘의 운세 도메인 모델.
// luckyPlace 필드 추가 (행운 장소)

class Horoscope {
  const Horoscope({
    required this.signSlug,
    required this.signName,
    required this.date,
    required this.summary,
    required this.luckyColor,
    required this.luckyNumber,
    required this.mood,
    this.luckyPlace,
  });

  final String signSlug; // 'aquarius'
  final String signName; // 'Aquarius'
  final DateTime date;

  /// 운세 본문(한 줄~두 줄 요약).
  final String summary;

  /// 행운 색상(영문 스트링 예: 'indigo').
  final String luckyColor;

  /// 행운 숫자. 화면에서 ×2, ×3 배수도 함께 표시.
  final int luckyNumber;

  /// 'calm', 'energetic' 등 — 화면에서 오늘의 감정 상태로 표기.
  final String mood;

  /// 행운 장소. API 미제공 시 null.
  final String? luckyPlace;

  Map<String, dynamic> toJson() => {
        'signSlug': signSlug,
        'signName': signName,
        'date': date.toIso8601String(),
        'summary': summary,
        'luckyColor': luckyColor,
        'luckyNumber': luckyNumber,
        'mood': mood,
        if (luckyPlace != null) 'luckyPlace': luckyPlace,
      };

  factory Horoscope.fromJson(Map<String, dynamic> json) => Horoscope(
        signSlug: json['signSlug'] as String,
        signName: json['signName'] as String,
        date: DateTime.parse(json['date'] as String),
        summary: json['summary'] as String,
        luckyColor: json['luckyColor'] as String,
        luckyNumber: (json['luckyNumber'] as num).toInt(),
        mood: json['mood'] as String,
        luckyPlace: json['luckyPlace'] as String?,
      );
}
