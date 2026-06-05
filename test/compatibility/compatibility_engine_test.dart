import 'package:flutter_test/flutter_test.dart';
import 'package:stellara/features/astrology/domain/birth_info.dart';
import 'package:stellara/features/astrology/fixtures/natal_chart_fixture.dart';
import 'package:stellara/features/compatibility/data/compatibility_engine.dart';
import 'package:stellara/features/compatibility/domain/synastry_result.dart';

void main() {
  group('CompatibilityEngine', () {
    const engine = CompatibilityEngine();

    BirthInfo birth({
      required String nickname,
      required DateTime dateTime,
      required double lat,
      required double lng,
    }) {
      return BirthInfo(
        nickname: nickname,
        dateTime: dateTime,
        latitude: lat,
        longitude: lng,
        utcOffset: '+09:00',
        placeName: '서울',
      );
    }

    test('rich compatibility result is generated from natal charts', () {
      final meBirth = birth(
        nickname: '나',
        dateTime: DateTime(1999, 2, 25, 14, 30),
        lat: 37.5665,
        lng: 126.9780,
      );
      final partnerBirth = birth(
        nickname: '친구',
        dateTime: DateTime(2000, 7, 11, 9, 15),
        lat: 35.1796,
        lng: 129.0756,
      );

      final result = engine.evaluate(
        pairKey: 'me__friend',
        chartPairVersion: 'v1__v2',
        me: buildFallbackNatalChart(meBirth),
        partner: buildFallbackNatalChart(partnerBirth),
        source: 'local-engine',
      );

      expect(result.totalScore, inInclusiveRange(0, 100));
      expect(result.friendshipScore, inInclusiveRange(0, 100));
      expect(result.emotionalMatch, isNotEmpty);
      expect(result.communicationStyle, isNotEmpty);
      expect(result.romanticMatch, isNotEmpty);
      expect(result.friendshipMatch, isNotEmpty);
      expect(result.summary, contains('우정 결:'));
      expect(result.engineVersion, CompatibilityEngine.engineVersion);
      expect(result.pairKey, 'me__friend');
      expect(result.chartPairVersion, 'v1__v2');
    });

    test('different partner chart changes compatibility output', () {
      final meBirth = birth(
        nickname: '나',
        dateTime: DateTime(1999, 2, 25, 14, 30),
        lat: 37.5665,
        lng: 126.9780,
      );
      final partnerABirth = birth(
        nickname: '친구A',
        dateTime: DateTime(2000, 7, 11, 9, 15),
        lat: 35.1796,
        lng: 129.0756,
      );
      final partnerBBirth = birth(
        nickname: '친구B',
        dateTime: DateTime(1997, 11, 2, 22, 5),
        lat: 33.4996,
        lng: 126.5312,
      );

      final resultA = engine.evaluate(
        pairKey: 'me__friendA',
        chartPairVersion: 'v1__v2',
        me: buildFallbackNatalChart(meBirth),
        partner: buildFallbackNatalChart(partnerABirth),
        source: 'local-engine',
      );
      final resultB = engine.evaluate(
        pairKey: 'me__friendB',
        chartPairVersion: 'v1__v3',
        me: buildFallbackNatalChart(meBirth),
        partner: buildFallbackNatalChart(partnerBBirth),
        source: 'local-engine',
      );

      final sameScores = resultA.totalScore == resultB.totalScore &&
          resultA.emotionScore == resultB.emotionScore &&
          resultA.communicationScore == resultB.communicationScore &&
          resultA.romanceScore == resultB.romanceScore &&
          resultA.friendshipScore == resultB.friendshipScore;

      expect(sameScores, isFalse);
    });
  });

  group('SynastryResult legacy parsing', () {
    test('old cache shape is still readable', () {
      final result = SynastryResult.fromJson({
        'totalScore': 70,
        'emotionScore': 72,
        'communicationScore': 68,
        'romanceScore': 71,
        'summary': 'legacy summary',
      });

      expect(result.totalScore, 70);
      expect(result.friendshipScore, 70);
      expect(result.source, 'legacy-cache');
      expect(result.emotionalMatch, isNotEmpty);
      expect(result.engineVersion, 'compat.v1');
    });
  });
}
