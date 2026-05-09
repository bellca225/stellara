// test/user_profile_test.dart
//
// T09 단위 테스트.
// Firestore 실호출 없이 toFirestore / fromFirestore round-trip 만 검증.

import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/features/astrology/domain/birth_info.dart';
import 'package:stellara/features/users/domain/user_profile.dart';

void main() {
  group('UserProfile.toFirestore / fromFirestore', () {
    test('birthInfo 가 있는 사용자의 round-trip 이 안전하다', () {
      final original = UserProfile(
        uid: 'demo-una',
        authProvider: 'anonymous',
        nickname: '물병자리의 꿈',
        profileCompleted: true,
        friendCode: 'AQU2024',
        birthInfo: BirthInfo(
          nickname: '물병자리의 꿈',
          dateTime: DateTime(1995, 2, 15, 14, 30),
          latitude: 37.5665,
          longitude: 126.978,
          utcOffset: '+09:00',
          placeName: '서울특별시',
        ),
        favoriteIds: const ['demo-whale', 'demo-fox'],
        activeChartVersion:
            '1995-02-15T14:30:00_37.5665_126.978_+09:00',
        createdAt: DateTime.utc(2026, 5, 9, 10, 0),
        updatedAt: DateTime.utc(2026, 5, 9, 10, 0),
      );

      final json = original.toFirestore();
      final restored = UserProfile.fromFirestore('demo-una', json);

      expect(restored.uid, original.uid);
      expect(restored.authProvider, original.authProvider);
      expect(restored.nickname, original.nickname);
      expect(restored.profileCompleted, original.profileCompleted);
      expect(restored.friendCode, original.friendCode);
      expect(restored.favoriteIds, original.favoriteIds);
      expect(restored.activeChartVersion, original.activeChartVersion);
      expect(restored.birthInfo, isNotNull);
      expect(restored.birthInfo!.nickname, '물병자리의 꿈');
      expect(restored.birthInfo!.dateTime, DateTime(1995, 2, 15, 14, 30));
      expect(restored.birthInfo!.latitude, 37.5665);
      expect(restored.birthInfo!.longitude, 126.978);
      expect(restored.birthInfo!.utcOffset, '+09:00');
      expect(restored.birthInfo!.placeName, '서울특별시');
    });

    test('birthInfo 가 없는 신규 사용자도 round-trip 이 안전하다', () {
      final original = UserProfile(
        uid: 'new-user',
        authProvider: 'anonymous',
        nickname: '익명의 행성',
        profileCompleted: false,
        createdAt: DateTime.utc(2026, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 9),
      );

      final restored = UserProfile.fromFirestore(
        'new-user',
        original.toFirestore(),
      );

      expect(restored.birthInfo, isNull);
      expect(restored.profileCompleted, false);
      expect(restored.favoriteIds, isEmpty);
      expect(restored.friendCode, isNull);
      expect(restored.activeChartVersion, isNull);
    });

    test('손상된 birthInfo 는 null 로 fallback', () {
      final restored = UserProfile.fromFirestore(
        'bad-data',
        {
          'authProvider': 'anonymous',
          'nickname': 'x',
          'profileCompleted': false,
          'birthInfo': {
            // dateTimeLocal 누락
            'latitude': 37.5,
            'longitude': 126.9,
            'utcOffset': '+09:00',
          },
          'favoriteIds': <dynamic>[],
          'createdAt': '2026-05-09T00:00:00Z',
          'updatedAt': '2026-05-09T00:00:00Z',
        },
      );

      expect(restored.birthInfo, isNull);
      expect(restored.uid, 'bad-data');
    });

    test('잘못된 createdAt/updatedAt 은 현재 시각으로 fallback', () {
      final before = DateTime.now().toUtc();
      final restored = UserProfile.fromFirestore(
        'no-dates',
        {
          'authProvider': 'anonymous',
          'nickname': 'x',
          'profileCompleted': false,
          // createdAt / updatedAt 누락
        },
      );
      final after = DateTime.now().toUtc();

      expect(
        restored.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(
        restored.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
