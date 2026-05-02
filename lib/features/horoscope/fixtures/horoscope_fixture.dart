// lib/features/horoscope/fixtures/horoscope_fixture.dart

import '../domain/horoscope.dart';

Horoscope demoHoroscope(String signSlug, [DateTime? date]) {
  final d = date ?? DateTime.now();
  return Horoscope(
    signSlug: signSlug,
    signName: signSlug.isEmpty
        ? '-'
        : '${signSlug[0].toUpperCase()}${signSlug.substring(1)}',
    date: d,
    summary:
        '조용하지만 흐름이 안정적인 하루예요. 말을 서두르기보다 한 번 더 듣는 태도가 뜻밖의 좋은 반응으로 이어질 수 있습니다.',
    luckyColor: 'indigo',
    luckyNumber: 7,
    mood: 'calm',
  );
}
