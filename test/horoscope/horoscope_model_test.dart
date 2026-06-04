import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/horoscope/domain/horoscope.dart';

void main() {
  test('horoscope reads legacy luckyNumber into three lucky numbers', () {
    final horoscope = Horoscope.fromJson({
      'signSlug': 'gemini',
      'signName': '쌍둥이자리',
      'date': '2026-06-03',
      'summary': '오늘은 대화가 잘 풀리는 날이에요.',
      'luckyColor': '보라색',
      'luckyNumber': 7,
      'mood': '부드럽고 들뜬 감정',
      'luckyPlace': '카페, 서점',
    });

    expect(horoscope.luckyNumbers, [7, 14, 21]);
    expect(horoscope.luckyNumber, 7);
  });

  test('horoscope keeps extended AI fields when serialized', () {
    final horoscope = Horoscope(
      signSlug: 'aquarius',
      signName: '물병자리',
      date: DateTime(2026, 6, 3),
      summary: '오늘은 약간 엉뚱한 선택이 기회가 될 수 있어요.',
      luckyColor: '파란색',
      luckyNumbers: [4, 11, 23],
      mood: '호기심이 강한 날',
      luckyPlace: '전시 공간',
      advice: '생각만 하지 말고 하나는 바로 실행해보세요.',
      caution: '답장을 미루다 흐름을 놓칠 수 있어요.',
      shareText: '엉뚱한 선택 하나가 오늘의 행운 포인트예요.',
      promptVersion: 'daily-horoscope-v2',
      chartVersion: 'chart-1',
      utcOffset: '+09:00',
    );

    final decoded = Horoscope.fromJson(horoscope.toJson());

    expect(decoded.luckyNumbers, [4, 11, 23]);
    expect(decoded.advice, contains('실행'));
    expect(decoded.shareText, contains('행운'));
    expect(decoded.promptVersion, 'daily-horoscope-v2');
  });
}
