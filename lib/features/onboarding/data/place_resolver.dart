// lib/features/onboarding/data/place_resolver.dart
//
// 출생지(주소 문자열) → 위경도 변환 helper.
//
// 동작:
//   - Android / iOS: `geocoding` 플랫폼 채널 사용 (forward geocoding)
//   - Web / 기타: 미지원. 호출자가 입력값 + 폴백 좌표를 그대로 쓰도록 신호를 돌려줌
//
// 설계 메모 (T07, 2026-05-09)
//   1. 호출자가 실패 원인을 구분할 수 있도록 [PlaceResolution] sealed 변형을 둔다.
//   2. 한국어 주소 입력은 "강남구 역삼동" 처럼 광역지명이 빠진 경우가 많으므로,
//      쿼리를 여러 형태로 시도해 hit-rate 를 올린다.
//   3. 기존 [PlaceResolver.resolve] 시그니처는 onboarding 화면이 이미 사용 중이라
//      호환성 wrapper 로 유지한다. 신규 호출자는 [resolveDetailed] 를 쓴다.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';

/// 좌표 변환 성공 시 결과.
class ResolvedPlace {
  const ResolvedPlace({
    required this.latitude,
    required this.longitude,
    required this.placeName,
    required this.source,
  });

  final double latitude;
  final double longitude;
  final String placeName;
  final String source;
}

/// 좌표 변환 실패 사유.
///
/// 화면이 이 값을 보고 사용자 안내 문구를 다르게 보여줄 수 있다.
enum PlaceResolutionFailureKind {
  /// 현재 플랫폼(예: Web)에서 forward geocoding 미지원.
  unsupportedPlatform,

  /// 입력이 비어 있어 변환 시도조차 하지 않음.
  emptyQuery,

  /// 지오코더가 어떤 후보 쿼리에서도 결과를 찾지 못함.
  notFound,

  /// 플랫폼 채널 호출 자체가 실패 (권한/네트워크/플러그인 미초기화 등).
  platformError,
}

/// 결과 타입. success / failure 중 하나.
sealed class PlaceResolution {
  const PlaceResolution();

  bool get isSuccess => this is PlaceResolutionSuccess;
}

class PlaceResolutionSuccess extends PlaceResolution {
  const PlaceResolutionSuccess(this.place);
  final ResolvedPlace place;
}

class PlaceResolutionFailure extends PlaceResolution {
  const PlaceResolutionFailure(this.kind, {this.message});
  final PlaceResolutionFailureKind kind;
  final String? message;
}

class PlaceResolver {
  /// 현재 플랫폼이 forward geocoding 을 지원하는지.
  ///
  /// Web 은 `geocoding` 플러그인이 native 채널만 사용하므로 미지원.
  /// macOS / Linux / Windows 도 본 프로젝트에서는 미지원으로 본다.
  bool get supportsForwardGeocoding =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// 결과 사유를 명확히 알고 싶을 때 호출.
  ///
  /// 예시 입력 / 결과:
  ///   "서울특별시 강남구 역삼동" → success
  ///   "강남구 역삼동"             → success (후보 쿼리에 "대한민국" 부착 후 hit)
  ///   "?? unknown ??"             → failure(notFound)
  ///   ""                          → failure(emptyQuery)
  ///   (Web 환경)                  → failure(unsupportedPlatform)
  Future<PlaceResolution> resolveDetailed(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const PlaceResolutionFailure(
        PlaceResolutionFailureKind.emptyQuery,
      );
    }
    if (!supportsForwardGeocoding) {
      return const PlaceResolutionFailure(
        PlaceResolutionFailureKind.unsupportedPlatform,
      );
    }

    try {
      await setLocaleIdentifier('ko_KR');
    } on PlatformException catch (e) {
      // 일부 환경(예: 일부 iOS 시뮬레이터)에서 locale 지정이 실패할 수 있다.
      // 치명적이지 않으므로 로그만 남기고 진행한다.
      _log('setLocaleIdentifier 실패 (계속 진행): ${e.message}');
    }

    String? lastErrorMessage;
    for (final candidate in candidateQueries(trimmed)) {
      try {
        final locations = await locationFromAddress(candidate);
        if (locations.isEmpty) {
          _log('candidate "$candidate" → 결과 없음');
          continue;
        }
        final best = locations.first;
        _log('candidate "$candidate" → ${best.latitude}, ${best.longitude}');
        return PlaceResolutionSuccess(
          ResolvedPlace(
            latitude: best.latitude,
            longitude: best.longitude,
            placeName: trimmed,
            source: 'platform-geocoding',
          ),
        );
      } on NoResultFoundException {
        _log('candidate "$candidate" → NoResultFoundException');
        continue;
      } on PlatformException catch (e) {
        lastErrorMessage = e.message;
        _log('candidate "$candidate" → PlatformException: ${e.message}');
        continue;
      }
    }

    if (lastErrorMessage != null) {
      return PlaceResolutionFailure(
        PlaceResolutionFailureKind.platformError,
        message: lastErrorMessage,
      );
    }
    return const PlaceResolutionFailure(PlaceResolutionFailureKind.notFound);
  }

  /// 기존 호출자(`onboarding_screen.dart`) 호환용 wrapper.
  ///
  /// 신규 코드는 [resolveDetailed] 를 사용하는 것을 권장한다 (실패 사유 구분 가능).
  Future<ResolvedPlace?> resolve(String query) async {
    final result = await resolveDetailed(query);
    return result is PlaceResolutionSuccess ? result.place : null;
  }

  /// 후보 쿼리 생성기. 단위 테스트에서 직접 검증할 수 있도록 노출한다.
  ///
  /// 한국어 주소는 "광역지명 + 구 + 동" 풀네임이 가장 잘 맞지만,
  /// 사용자는 "강남구 역삼동" 처럼 일부만 적는 경우가 많아
  /// 다음 패턴을 순차 시도한다:
  ///   1) 입력값 그대로
  ///   2) 입력값 + ", 대한민국"
  ///   3) 입력값 + ", South Korea"
  ///   4) 광역지명이 빠졌다고 판단되는 경우 "서울특별시" prefix 시도
  @visibleForTesting
  static List<String> candidateQueries(String trimmed) {
    final queries = <String>[trimmed];
    final lowered = trimmed.toLowerCase();
    final hasCountry = lowered.contains('대한민국') ||
        lowered.contains('한국') ||
        lowered.contains('south korea') ||
        lowered.contains('korea');
    if (!hasCountry) {
      queries.add('$trimmed, 대한민국');
      queries.add('$trimmed, South Korea');
    }
    // "강남구 역삼동" 처럼 광역지명이 없는 경우 서울 prefix 추정 시도.
    // 이건 명시적 추정이라 마지막 fallback 으로만 둔다.
    final looksLikeKoreanSubregion =
        !_hasMajorRegionPrefix(trimmed) && _hasKoreanSubregionToken(trimmed);
    if (looksLikeKoreanSubregion) {
      queries.add('서울특별시 $trimmed');
    }
    return queries;
  }

  static bool _hasMajorRegionPrefix(String trimmed) {
    const majorRegionTokens = <String>[
      '서울', '부산', '인천', '대구', '대전', '광주', '울산', '세종',
      '경기', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주',
    ];
    for (final token in majorRegionTokens) {
      if (trimmed.startsWith(token)) {
        return true;
      }
    }
    return false;
  }

  static bool _hasKoreanSubregionToken(String trimmed) {
    return trimmed.contains('구 ') ||
        trimmed.endsWith('구') ||
        trimmed.contains('동 ') ||
        trimmed.endsWith('동') ||
        trimmed.contains('읍 ') ||
        trimmed.endsWith('읍') ||
        trimmed.contains('면 ') ||
        trimmed.endsWith('면');
  }

  static void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[PlaceResolver] $message');
    }
  }
}
