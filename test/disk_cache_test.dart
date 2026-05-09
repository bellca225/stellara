// test/disk_cache_test.dart
//
// T13.5 단위 테스트.
// SharedPreferences 의 in-memory 모킹(`setMockInitialValues`)을 사용해
// 디바이스 없이 캐시 동작을 검증한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stellara/core/cache/disk_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiskCache', () {
    late SharedPreferences prefs;
    late DiskCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      cache = DiskCache(prefs);
    });

    test('put 후 get 으로 같은 값을 돌려준다', () async {
      await cache.putJson('key1', {'a': 1, 'b': 'two'});
      final got = cache.getJson('key1');
      expect(got, isNotNull);
      expect(got!['a'], 1);
      expect(got['b'], 'two');
    });

    test('source=fixture 인 put 은 디스크에 저장하지 않는다 (운영 원칙)', () async {
      await cache.putJson('key2', {'x': 1}, source: 'fixture');
      expect(cache.getJson('key2'), isNull);
    });

    test('TTL 이 지난 항목은 null 을 반환하고 자동 삭제된다', () async {
      await cache.putJson(
        'key3',
        {'x': 1},
        ttl: const Duration(seconds: -1), // 이미 만료된 상태로 저장
      );
      expect(cache.getJson('key3'), isNull);
      // 자동 삭제 확인 — 다시 호출해도 여전히 null
      expect(cache.getJson('key3'), isNull);
    });

    test('TTL null 이면 영구 보관 (자동 삭제 없음)', () async {
      await cache.putJson('key4', {'x': 1});
      expect(cache.getJson('key4'), isNotNull);
    });

    test('remove 하면 이후 get 이 null', () async {
      await cache.putJson('key5', {'x': 1});
      await cache.remove('key5');
      expect(cache.getJson('key5'), isNull);
    });

    test('손상된 JSON 은 silent 무시 (예외 안 던짐)', () async {
      await prefs.setString('${DiskCache.prefix}corrupt', 'not-json');
      expect(cache.getJson('corrupt'), isNull);
    });

    test('clearAll 은 prefix 를 가진 키만 삭제한다', () async {
      await prefs.setString('other.unrelated.key', 'keep me');
      await cache.putJson('mine1', {'x': 1});
      await cache.putJson('mine2', {'y': 2});

      await cache.clearAll();

      expect(cache.getJson('mine1'), isNull);
      expect(cache.getJson('mine2'), isNull);
      expect(prefs.getString('other.unrelated.key'), 'keep me');
    });
  });

  group('CacheKeys', () {
    test('natal 키는 chartVersion 을 그대로 prefix 한다', () {
      final key = CacheKeys.natal('1995-02-15T14:30:00_37.5665_126.978_+09:00');
      expect(key, startsWith('natal.'));
      expect(key, contains('1995-02-15T14:30:00'));
    });

    test('daily 키는 sign + yyyyMMdd 형식', () {
      final key = CacheKeys.daily('aquarius', DateTime(2026, 5, 9));
      expect(key, 'daily.aquarius.20260509');
    });

    test('synastry 키는 두 chartVersion 을 __ 로 잇는다', () {
      final key = CacheKeys.synastry('v1', 'v2');
      expect(key, 'synastry.v1__v2');
    });
  });
}
