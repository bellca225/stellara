// lib/features/astrology/data/prokerala_token_repository.dart
//
// Prokerala OAuth2 (client_credentials) 토큰 발급/캐싱 책임.
//
// 흐름
//   POST {token_url}
//     grant_type=client_credentials
//     client_id={...}
//     client_secret={...}
//   ↓
//   { access_token, expires_in, token_type }
//
// 캐싱 전략
// - 메모리에만 저장한다(앱이 재시작되면 다시 발급).
// - 만료 60초 전부터 "곧 만료"로 보고 자동 재발급.
// - 동시에 여러 Provider가 토큰을 요구할 수 있으므로 in-flight Future 를
//   하나로 묶어 race condition 으로 토큰을 두 번 발급하지 않는다.
//
// 보안
// - client_secret 은 .env에서만 읽고, 절대 로그/응답에 찍지 않는다.
// - 9주차에는 Flutter에서 직접 호출(승인된 결정). 추후 백엔드 분리 시
//   이 클래스만 통째로 BackendTokenRepository 로 교체 가능.

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/env/env.dart';

/// 발급된 토큰을 만료 시각과 함께 보관.
class _CachedToken {
  _CachedToken({required this.value, required this.expiresAt});
  final String value;
  final DateTime expiresAt;

  bool get isExpiringSoon =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));
}

class ProkeralaTokenRepository {
  ProkeralaTokenRepository({
    Dio? tokenDio,
    List<ProkeralaCredential>? credentials,
  })
      : _tokenDio = tokenDio ?? Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _credentials = credentials ?? Env.prokeralaCredentials;

  /// 토큰 발급 자체는 우리 메인 dio 와 별개의 dio 로 한다.
  /// 메인 dio 의 AuthInterceptor 가 자기 자신을 호출하는 무한루프를 막기 위해.
  final Dio _tokenDio;
  final List<ProkeralaCredential> _credentials;

  _CachedToken? _cached;
  Future<String>? _inFlight;
  int _activeCredentialIndex = 0;

  String get activeCredentialLabel {
    if (_credentials.isEmpty) {
      return 'none';
    }
    return _credentials[_activeCredentialIndex].label;
  }

  /// 토큰을 가져온다.
  ///
  /// [forceRefresh] 가 true 이면 캐시를 무시하고 새로 발급한다.
  /// (401 응답 시 AuthInterceptor 가 호출.)
  Future<String> getToken({bool forceRefresh = false}) {
    final cached = _cached;
    if (!forceRefresh && cached != null && !cached.isExpiringSoon) {
      return Future.value(cached.value);
    }
    // 이미 발급 중인 호출이 있다면 그 future 를 그대로 돌려준다.
    final inFlight = _inFlight;
    if (inFlight != null && !forceRefresh) {
      return inFlight;
    }
    final future = _issueToken().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<bool> rotateToNextCredential() async {
    if (_activeCredentialIndex >= _credentials.length - 1) {
      return false;
    }

    _activeCredentialIndex += 1;
    clear();

    if (kDebugMode) {
      // ignore: avoid_print
      print(
        '[ProkeralaTokenRepository] backup credential로 전환: '
        '$activeCredentialLabel',
      );
    }
    return true;
  }

  Future<String> _issueToken() async {
    if (_credentials.isEmpty) {
      throw ProkeralaAuthException(
        '사용 가능한 Prokerala credential 이 없습니다. '
        '.env 또는 backup credential 설정을 확인해주세요.',
      );
    }

    Object? lastError;
    for (var index = _activeCredentialIndex; index < _credentials.length; index++) {
      final credential = _credentials[index];
      try {
        final token = await _issueTokenForCredential(credential);
        _activeCredentialIndex = index;
        return token;
      } catch (e) {
        lastError = e;
        if (kDebugMode) {
          // ignore: avoid_print
          print(
            '[ProkeralaTokenRepository] credential(${credential.label}) '
            '토큰 발급 실패: $e',
          );
        }
      }
    }

    throw lastError is Exception
        ? lastError
        : ProkeralaAuthException('모든 Prokerala credential 로 토큰 발급 실패');
  }

  Future<String> _issueTokenForCredential(ProkeralaCredential credential) async {
    final response = await _tokenDio.post<Map<String, dynamic>>(
      Env.prokeralaTokenUrl,
      data: {
        'grant_type': 'client_credentials',
        'client_id': credential.clientId,
        'client_secret': credential.clientSecret,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        // 토큰 호출은 4xx 도 통째로 보고 받고 싶으니 validateStatus 를 풀어준다.
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    final data = response.data ?? const <String, dynamic>{};
    final accessToken = data['access_token'] as String?;
    final expiresIn = data['expires_in'];
    if (response.statusCode != 200 || accessToken == null) {
      throw ProkeralaAuthException(
        '토큰 발급 실패 (status=${response.statusCode}, body=$data)',
      );
    }
    final ttlSeconds = (expiresIn is int) ? expiresIn : 3600;
    _cached = _CachedToken(
      value: accessToken,
      expiresAt: DateTime.now().add(Duration(seconds: ttlSeconds)),
    );
    return accessToken;
  }

  /// 테스트/로그아웃 시 캐시 무효화.
  void clear() {
    _cached = null;
    _inFlight = null;
  }
}

class ProkeralaAuthException implements Exception {
  ProkeralaAuthException(this.message);
  final String message;
  @override
  String toString() => 'ProkeralaAuthException: $message';
}
