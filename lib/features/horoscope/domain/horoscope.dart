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
    required this.luckyNumbers,
    required this.mood,
    this.luckyPlace,
    this.advice = '',
    this.caution = '',
    this.shareText = '',
    this.promptVersion,
    this.chartVersion,
    this.utcOffset,
  });

  final String signSlug; // 'aquarius'
  final String signName; // 'Aquarius'
  final DateTime date;

  /// 운세 본문(한 줄~두 줄 요약).
  final String summary;

  /// 행운 색상. AI 생성 시에는 한국어 색상명 자체를 저장한다.
  final String luckyColor;

  /// 행운 숫자 3개.
  final List<int> luckyNumbers;

  /// 하위 호환용 첫 번째 숫자.
  int get luckyNumber => luckyNumbers.isEmpty ? 0 : luckyNumbers.first;

  /// 오늘의 감정 상태. AI 생성 시에는 한국어 문구 자체를 저장한다.
  final String mood;

  /// 행운 장소. API 미제공 시 null.
  final String? luckyPlace;

  final String advice;
  final String caution;
  final String shareText;
  final String? promptVersion;
  final String? chartVersion;
  final String? utcOffset;

  Map<String, dynamic> toJson() => {
        'signSlug': signSlug,
        'signName': signName,
        'date': date.toIso8601String(),
        'summary': summary,
        'luckyColor': luckyColor,
        'luckyNumbers': luckyNumbers,
        'luckyNumber': luckyNumber,
        'mood': mood,
        if (luckyPlace != null) 'luckyPlace': luckyPlace,
        'advice': advice,
        'caution': caution,
        'shareText': shareText,
        if (promptVersion != null) 'promptVersion': promptVersion,
        if (chartVersion != null) 'chartVersion': chartVersion,
        if (utcOffset != null) 'utcOffset': utcOffset,
      };

  factory Horoscope.fromJson(Map<String, dynamic> json) {
    final numbers = <int>[
      for (final value in (json['luckyNumbers'] as List? ?? const []))
        if (value is num) value.toInt(),
    ];
    final legacy = (json['luckyNumber'] as num?)?.toInt();
    if (numbers.isEmpty && legacy != null && legacy > 0) {
      numbers.addAll([legacy, legacy * 2, legacy * 3]);
    }

    return Horoscope(
      signSlug: json['signSlug'] as String,
      signName: json['signName'] as String,
      date: DateTime.parse(json['date'] as String),
      summary: json['summary'] as String,
      luckyColor: json['luckyColor'] as String,
      luckyNumbers: numbers,
      mood: json['mood'] as String,
      luckyPlace: json['luckyPlace'] as String?,
      advice: json['advice'] as String? ?? '',
      caution: json['caution'] as String? ?? '',
      shareText: json['shareText'] as String? ?? '',
      promptVersion: json['promptVersion'] as String?,
      chartVersion: json['chartVersion'] as String?,
      utcOffset: json['utcOffset'] as String?,
    );
  }
}
