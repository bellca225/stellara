// lib/core/http/dio_client.dart
//
// Prokerala API 전용 Dio 인스턴스를 생성한다.
//
// 책임 분리
// - DioClient        : Dio 인스턴스 자체를 만들고 인터셉터를 붙인다.
// - _AuthInterceptor : 모든 요청에 Bearer 토큰을 자동 주입하고,
//                      401(만료)이면 토큰을 다시 받아 1회 재시도한다.
// - _RateLimitInterceptor : 429 응답 시 Retry-After 만큼 기다렸다가 재시도.
// - _LoggingInterceptor   : credit 잔여량(X-RateLimit-* 헤더)을 콘솔에 찍어
//                            "이번 호출에 몇 credit 썼는지" 추적하기 쉽게 한다.
//
// 토큰 저장소(ProkeralaTokenRepository)는 features/astrology/data 에 두고,
// 여기서는 추상적인 함수형 콜백으로만 받는다 (의존 방향: core ← feature).

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../env/env.dart';
import '../ui/app_alerts.dart';

/// 토큰을 비동기로 발급/갱신해 주는 함수 시그니처.
///
/// `forceRefresh` 가 true 이면 캐시 무시하고 새로 발급하라는 신호.
typedef TokenProvider = Future<String> Function({bool forceRefresh});

class DioClient {
  /// Prokerala API 호출용 Dio 인스턴스를 만든다.
  ///
  /// [tokenProvider] : 토큰을 어디에서 가져올지 주입받는다.
  ///                   테스트 시 fake로 교체하기 쉽도록 함수형으로 받는 것.
  static Dio create({required TokenProvider tokenProvider}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.prokeralaBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        // Prokerala API 는 JSON 응답을 주고, 우리도 JSON 만 보낸다.
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(dio: dio, tokenProvider: tokenProvider));
    dio.interceptors.add(_RateLimitInterceptor(dio: dio));
    if (kDebugMode) {
      dio.interceptors.add(_LoggingInterceptor());
    }
    return dio;
  }
}

// ─────────────────────────────────────────────────────────────────
// 인터셉터들
// ─────────────────────────────────────────────────────────────────

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.dio, required this.tokenProvider});
  final Dio dio;
  final TokenProvider tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // /token 엔드포인트 자체에는 Bearer 를 붙이면 안 된다.
    if (options.path.contains('/token')) {
      return handler.next(options);
    }
    try {
      final token = await tokenProvider(forceRefresh: false);
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (e, st) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          message: '토큰 발급 실패: $e',
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final isAuthIssue = status == 401 || status == 403;
    final alreadyRetried = err.requestOptions.extra['__authRetried'] == true;
    if (isAuthIssue && !alreadyRetried) {
      try {
        // 토큰을 강제로 새로 받아 한 번 더 시도.
        final fresh = await tokenProvider(forceRefresh: true);
        final req = err.requestOptions
          ..headers['Authorization'] = 'Bearer $fresh'
          ..extra['__authRetried'] = true;
        final res = await dio.fetch(req);
        return handler.resolve(res);
      } catch (_) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

class _RateLimitInterceptor extends Interceptor {
  _RateLimitInterceptor({required this.dio});
  final Dio dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['__rateRetried'] == true;
    if (status == 429 && !alreadyRetried) {
      AppAlerts.showTokenExhaustedDialog();
      // Retry-After 헤더가 있으면 그 시간만큼, 없으면 1.5초 대기.
      final retryAfter = err.response?.headers.value('retry-after');
      final waitSeconds = int.tryParse(retryAfter ?? '') ?? 2;
      await Future<void>.delayed(Duration(seconds: waitSeconds));
      final req = err.requestOptions..extra['__rateRetried'] = true;
      try {
        final res = await dio.fetch(req);
        return handler.resolve(res);
      } catch (_) {
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Prokerala 가 보내주는 credit 관련 헤더(예시: X-RateLimit-Limit, X-RateLimit-Remaining,
    // X-RateLimit-Reset, X-RateLimit-Cost). 헤더명은 실호출 시 한 번 확인 후 정확히
    // 매핑하는 것이 안전하다 (현재 sandbox에선 직접 fetch가 막혀 있어 추정).
    final headers = response.headers;
    final remaining = headers.value('x-ratelimit-remaining') ??
        headers.value('x-credit-remaining');
    final cost = headers.value('x-ratelimit-cost') ??
        headers.value('x-credit-cost');
    final path = response.requestOptions.path;
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[Prokerala] $path → status=${response.statusCode} '
        'cost=${cost ?? '?'} remaining=${remaining ?? '?'}',
      );
    }
    if (int.tryParse(remaining ?? '') == 0) {
      AppAlerts.showTokenExhaustedDialog();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 429) {
      AppAlerts.showTokenExhaustedDialog();
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[Prokerala] ERROR ${err.requestOptions.path} '
        '→ status=${err.response?.statusCode} body=${err.response?.data}',
      );
    }
    handler.next(err);
  }
}
