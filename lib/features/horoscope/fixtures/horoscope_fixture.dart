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
    luckyColor: '인디고',
    luckyNumbers: const [7, 14, 21],
    mood: '차분함',
    luckyPlace: '카페, 도서관',
    advice: '속도를 조금 늦추면 좋은 흐름을 더 길게 가져갈 수 있어요.',
    caution: '성급한 답장은 작은 오해를 만들 수 있어요.',
    shareText: '조용하지만 기회가 살아 있는 하루예요.',
  );
}
