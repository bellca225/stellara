// lib/core/cache/disk_cache.dart
//
// SDD 5.6 데이터 캐시 계층 중 **L2 (디스크)** 구현.
// SharedPreferences 기반 generic JSON wrapper 다.
//
// 설계 원칙
//   1. 키마다 TTL 을 줄 수 있다. TTL 이 null 이면 영구 (chartVersion 기반 무효화 사용).
//   2. fixture 결과는 디스크에 저장하지 않는다 (운영 원칙 SDD 5.6.4).
//   3. 직렬화 실패 / 디코딩 실패 시 silent 무시 — 캐시 자체가 깨져도 앱은 동작해야 한다.
//   4. 키 prefix `stellara.cache.v1.` 로 다른 SharedPreferences 사용처와 충돌 회피.
//      schema 가 바뀌면 prefix 의 v1 → v2 로 올려 자동 무효화한다.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 시작 시 `main.dart` 에서 한 번 await 해서 override 로 주입하는 Provider.
///
/// 직접 `read` 하면 [UnimplementedError] 가 난다 — 이는 의도된 가드다.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
    'sharedPreferencesProvider 가 override 되지 않았습니다. '
    'main.dart 에서 await SharedPreferences.getInstance() 결과를 주입하세요.',
  );
});

/// L2 디스크 캐시 진입점 Provider.
final diskCacheProvider = Provider<DiskCache>(
  (ref) => DiskCache(ref.watch(sharedPreferencesProvider)),
);

class DiskCache {
  DiskCache(this._prefs);
  final SharedPreferences _prefs;

  /// 키 prefix. schema 변경 시 v1 → v2 로 올려 자동 무효화.
  @visibleForTesting
  static const String prefix = 'stellara.cache.v1.';

  /// 저장.
  ///
  /// [source] 가 `'fixture'` 이면 의도적으로 저장하지 않는다 (운영 원칙).
  /// [ttl] null = 영구 (chartVersion 기반 명시 무효화로만 삭제).
  Future<void> putJson(
    String key,
    Map<String, dynamic> value, {
    Duration? ttl,
    String source = 'live',
  }) async {
    if (source == 'fixture') {
      _log('skip put (source=fixture) key=$key');
      return;
    }
    final entry = <String, dynamic>{
      'value': value,
      'savedAt': DateTime.now().toIso8601String(),
      'ttlSeconds': ttl?.inSeconds,
      'source': source,
    };
    try {
      await _prefs.setString(prefix + key, jsonEncode(entry));
      _log('put key=$key (source=$source, ttl=${ttl?.inSeconds ?? "∞"}s)');
    } catch (e) {
      _log('put 실패 key=$key err=$e');
    }
  }

  /// 읽기. 만료된 항목은 자동 삭제 + null 반환.
  Map<String, dynamic>? getJson(String key) {
    final raw = _prefs.getString(prefix + key);
    if (raw == null) {
      return null;
    }
    try {
      final entry = jsonDecode(raw) as Map<String, dynamic>;
      final ttlSeconds = entry['ttlSeconds'];
      if (ttlSeconds is int) {
        final savedAt = DateTime.parse(entry['savedAt'] as String);
        final age = DateTime.now().difference(savedAt).inSeconds;
        if (age > ttlSeconds) {
          _log('miss (expired age=${age}s ttl=${ttlSeconds}s) key=$key');
          // fire-and-forget 만료 정리
          _prefs.remove(prefix + key);
          return null;
        }
      }
      _log('hit key=$key');
      return entry['value'] as Map<String, dynamic>;
    } catch (e) {
      _log('decode 실패 key=$key err=$e');
      return null;
    }
  }

  /// 명시적 삭제. chartVersion 변경 등 도메인 무효화 시 사용.
  Future<void> remove(String key) async {
    await _prefs.remove(prefix + key);
    _log('remove key=$key');
  }

  /// 디버그/테스트 용.
  @visibleForTesting
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[DiskCache] $message');
    }
  }
}

/// 도메인별 캐시 키 helper.
///
/// 키 규칙은 SDD 5.6.2 표 그대로.
class CacheKeys {
  const CacheKeys._();

  /// natal chart 키. `BirthInfo.chartVersion` 만 필요.
  static String natal(String chartVersion) => 'natal.$chartVersion';

  /// daily horoscope 키. signSlug + 날짜(yyyyMMdd).
  static String daily(String signSlug, DateTime date) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final ymd = '${date.year}${pad(date.month)}${pad(date.day)}';
    return 'daily.$signSlug.$ymd';
  }

  /// synastry 키.
  /// pairKey + chartPairVersion 조합을 사용해
  /// 사용자 쌍이 같더라도 출생 정보 변경 시 자동 cache miss 되도록 한다.
  static String synastry(String pairKey, String chartPairVersion) =>
      'synastry.$pairKey|$chartPairVersion';
}
