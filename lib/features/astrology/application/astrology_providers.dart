// lib/features/astrology/application/astrology_providers.dart
//
// Riverpod Provider 구성. 9주차에는 코드 생성기(@riverpod)는 도입하되 코드 생성 결과는
// 작게 유지하기 위해 NotifierProvider 만 직접 작성하는 것이 아니라
// 일반 Provider/FutureProvider 를 직접 선언한다.
//
// 이렇게 한 이유
// - 9주차에 build_runner 를 한 번 돌리는 것만으로도 충분한 학습 부담.
// - 추후 더 복잡한 Notifier가 필요해지면 그때 @riverpod 으로 옮긴다.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/dio_client.dart';
import '../data/astrology_repository.dart';
import '../data/prokerala_api.dart';
import '../data/prokerala_token_repository.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';

// ── 토큰 저장소 ──────────────────────────────────────────────────
final prokeralaTokenRepoProvider =
    Provider<ProkeralaTokenRepository>((ref) => ProkeralaTokenRepository());

// ── Dio (인증/레이트리밋 인터셉터 포함) ───────────────────────────
final prokeralaDioProvider = Provider<Dio>((ref) {
  final tokenRepo = ref.watch(prokeralaTokenRepoProvider);
  return DioClient.create(
    tokenProvider: ({bool forceRefresh = false}) =>
        tokenRepo.getToken(forceRefresh: forceRefresh),
  );
});

// ── 저수준 API 래퍼 ──────────────────────────────────────────────
final prokeralaApiProvider = Provider<ProkeralaApi>(
  (ref) => ProkeralaApi(ref.watch(prokeralaDioProvider)),
);

// ── 도메인 Repository ───────────────────────────────────────────
final astrologyRepositoryProvider = Provider<AstrologyRepository>(
  (ref) => AstrologyRepository(ref.watch(prokeralaApiProvider)),
);

// ── "현재 사용자의 출생 정보" — 10주차에 Firestore 와 연결 ────────
//
// 9주차에는 OnboardingScreen 에서 setState 대신 이 Provider 에 값을 써넣고,
// 다른 화면들은 ref.watch(currentBirthInfoProvider) 로 읽는다.
final currentBirthInfoProvider = StateProvider<BirthInfo>((ref) {
  return BirthInfo.demo();
});

// ── 차트 호출 ───────────────────────────────────────────────────
//
// .family 로 BirthInfo 마다 별도의 캐시를 가지게 한다.
// (다른 친구의 출생정보로도 차트를 뽑을 수 있도록.)
final natalChartProvider =
    FutureProvider.family<NatalChart, BirthInfo>((ref, birth) {
  final repo = ref.watch(astrologyRepositoryProvider);
  return repo.getNatalChart(birth);
});

/// "현재 로그인 사용자의 차트" — 화면에서 가장 자주 쓰는 단축 Provider.
final myNatalChartProvider = FutureProvider<NatalChart>((ref) {
  final birth = ref.watch(currentBirthInfoProvider);
  return ref.watch(natalChartProvider(birth).future);
});
