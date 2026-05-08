// test/place_resolver_test.dart
//
// T07 단위 테스트.
// 실제 geocoding 플랫폼 채널은 호출하지 않는다 (네트워크/디바이스 의존 회피).
// 후보 쿼리 생성 로직만 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:stellara/features/onboarding/data/place_resolver.dart';

void main() {
  group('PlaceResolver.candidateQueries', () {
    test('국가 토큰이 없는 입력은 대한민국 / South Korea 후보를 추가한다', () {
      final result = PlaceResolver.candidateQueries('서울특별시');
      expect(result, contains('서울특별시'));
      expect(result, contains('서울특별시, 대한민국'));
      expect(result, contains('서울특별시, South Korea'));
    });

    test('이미 "대한민국" 이 포함된 입력에는 국가 토큰을 다시 붙이지 않는다', () {
      final result = PlaceResolver.candidateQueries('대한민국 서울특별시');
      expect(result.length, 1);
      expect(result.single, '대한민국 서울특별시');
    });

    test('광역지명 prefix 없이 "구/동" 으로 끝나는 입력은 서울 prefix 후보를 추가한다', () {
      final result = PlaceResolver.candidateQueries('강남구 역삼동');
      expect(result, contains('강남구 역삼동'));
      expect(result, contains('서울특별시 강남구 역삼동'));
    });

    test('광역지명 prefix 가 있으면 서울 prefix 추정은 하지 않는다', () {
      final result = PlaceResolver.candidateQueries('부산광역시 해운대구');
      expect(result.any((q) => q.startsWith('서울특별시')), isFalse);
    });

    test('광역지명도 sub-region 토큰도 없는 일반 문자열은 기본 후보 3종만 생성한다', () {
      final result = PlaceResolver.candidateQueries('Tokyo');
      expect(result, [
        'Tokyo',
        'Tokyo, 대한민국',
        'Tokyo, South Korea',
      ]);
    });
  });
}
