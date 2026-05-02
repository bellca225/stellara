// lib/features/astrology/data/prokerala_api.dart
//
// Prokerala Astrology API 의 thin wrapper.
//
// 엔드포인트 경로/파라미터 명세는 공식 OpenAPI 스펙
//   https://api.prokerala.com/spec/astrology.v2.yaml
// 을 기준으로 한다. 9주차 시점에는 sandbox 에서 직접 fetch 가 막혀 있어
// 아래 경로/파라미터는 공식 문서에서 자주 보이는 패턴을 기반으로 한 "최선의 추정" 이다.
// → 첫 실호출 시 응답 헤더(credit cost)와 본문을 fixture 로 저장한 뒤,
//   실제 응답 모양과 다르면 모델/파서를 조정한다. (TODO 주석 표시)
//
// 본 클래스는 "어디로 GET/POST 보내고 어떤 응답을 기대하는가" 만 다룬다.
// 응답을 도메인 모델로 바꾸는 일은 *Repository 에 맡긴다 (관심사 분리).

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../domain/birth_info.dart';

class ProkeralaApi {
  ProkeralaApi(this._dio);
  final Dio _dio;

  /// 출생 시각/위치를 Prokerala API 가 기대하는 query string 형식으로 만든다.
  ///
  /// Prokerala 는 ISO 8601 datetime + UTC offset 을 받기 때문에
  /// "+09:00" 같은 offset을 반드시 포함시킨다.
  Map<String, dynamic> _profileQuery(BirthInfo birth) {
    final dt = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(birth.dateTime);
    final offset = birth.utcOffset; // 예: "+09:00"
    return {
      // Prokerala 공식 예제는 두 형태 모두 받음:
      //   profile[datetime]= 또는 datetime=
      //   profile[coordinates]=37.5665,126.9780 또는 coordinates=
      // 호환을 위해 두 가지 모두 보낸다 (서버는 알 수 있는 키만 사용).
      'datetime': '$dt$offset',
      'coordinates': '${birth.latitude},${birth.longitude}',
      'profile[datetime]': '$dt$offset',
      'profile[coordinates]': '${birth.latitude},${birth.longitude}',
      // Western Astrology 는 ayanamsa 가 의미가 없지만, 공통 파라미터로 둠.
      // 0 = Tropical(Western), 1 = Lahiri(Vedic, default).
      'ayanamsa': 0,
      'la': 'en', // 응답 언어. 현재 'en' 만 안전하게 지원.
    };
  }

  // ── Natal Chart (Western) ──────────────────────────────────────
  /// 출생 차트(나탈 차트)의 행성/하우스/어스펙트 데이터를 가져온다.
  ///
  /// 공식 demo: https://api.prokerala.com/demo/natal-chart.php
  /// 응답 예시 키: `data.planet_position`, `data.houses`, `data.aspects` 등
  /// (서버 응답 모양은 호출 후 한 번 더 검증 필요 — TODO 표시)
  Future<Map<String, dynamic>> fetchNatalChart(BirthInfo birth) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/v2/astrology/natal-chart',
      queryParameters: _profileQuery(birth),
    );
    _ensureOk(res);
    return res.data!;
  }

  /// 행성 위치만 따로 받고 싶을 때 (Big 3 — Sun/Moon/Ascendant 추출용).
  Future<Map<String, dynamic>> fetchPlanetPosition(BirthInfo birth) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/v2/astrology/planet-position',
      queryParameters: _profileQuery(birth),
    );
    _ensureOk(res);
    return res.data!;
  }

  // ── Daily Horoscope ────────────────────────────────────────────
  /// 별자리 기반 오늘의 운세.
  ///
  /// [signSlug] 예: 'aquarius', 'aries', 'pisces' …
  /// 공식 문서상 엔드포인트 후보: /v2/horoscope/daily 또는 /v2/astrology/daily-prediction
  /// — 첫 호출 시 200 OK 인 쪽으로 고정한다. 본 코드는 /v2/horoscope/daily 우선.
  Future<Map<String, dynamic>> fetchDailyHoroscope({
    required String signSlug,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(d);
    final res = await _dio.get<Map<String, dynamic>>(
      '/v2/horoscope/daily',
      queryParameters: {
        'sign': signSlug,
        'date': dateStr,
        'la': 'en',
      },
    );
    _ensureOk(res);
    return res.data!;
  }

  // ── Synastry (궁합) ────────────────────────────────────────────
  /// 두 사람의 출생 정보로 궁합 차트를 만든다.
  Future<Map<String, dynamic>> fetchSynastry({
    required BirthInfo me,
    required BirthInfo partner,
  }) async {
    // synastry-chart 는 두 명의 profile 을 동시에 받는다.
    final dt1 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(me.dateTime);
    final dt2 = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(partner.dateTime);
    final res = await _dio.get<Map<String, dynamic>>(
      '/v2/astrology/synastry-chart',
      queryParameters: {
        'profile[datetime]': '$dt1${me.utcOffset}',
        'profile[coordinates]': '${me.latitude},${me.longitude}',
        'partner_profile[datetime]': '$dt2${partner.utcOffset}',
        'partner_profile[coordinates]':
            '${partner.latitude},${partner.longitude}',
        'ayanamsa': 0,
        'la': 'en',
      },
    );
    _ensureOk(res);
    return res.data!;
  }

  void _ensureOk(Response<Map<String, dynamic>> res) {
    if (res.statusCode == null || res.statusCode! >= 400) {
      throw ProkeralaApiException(
        'Prokerala 응답이 비정상입니다 (status=${res.statusCode})',
      );
    }
  }
}

class ProkeralaApiException implements Exception {
  ProkeralaApiException(this.message);
  final String message;
  @override
  String toString() => 'ProkeralaApiException: $message';
}
