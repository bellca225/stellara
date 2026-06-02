import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/astrology/domain/birth_info.dart';
import 'package:stellara/features/astrology/fixtures/natal_chart_fixture.dart';

void main() {
  test('fallback natal chart is deterministic for the same birth info', () {
    final birth = BirthInfo(
      nickname: 'tester',
      dateTime: DateTime(1999, 2, 25, 14, 30),
      latitude: 37.5665,
      longitude: 126.9780,
      utcOffset: '+09:00',
      placeName: '서울특별시',
    );

    final first = buildFallbackNatalChart(birth).toJson();
    final second = buildFallbackNatalChart(birth).toJson();

    expect(second, equals(first));
  });

  test('fallback natal chart changes when birth info changes', () {
    final firstBirth = BirthInfo(
      nickname: 'tester',
      dateTime: DateTime(1999, 2, 25, 14, 30),
      latitude: 37.5665,
      longitude: 126.9780,
      utcOffset: '+09:00',
      placeName: '서울특별시',
    );
    final secondBirth = BirthInfo(
      nickname: 'tester',
      dateTime: DateTime(1958, 5, 27, 14, 30),
      latitude: 37.550263,
      longitude: 126.9970831,
      utcOffset: '+09:00',
      placeName: 'Seoul, South Korea',
    );

    final first = buildFallbackNatalChart(firstBirth);
    final second = buildFallbackNatalChart(secondBirth);

    expect(first.toJson(), isNot(equals(second.toJson())));
    expect(first.sunSign, equals('Pisces'));
    expect(second.sunSign, equals('Gemini'));
  });
}
