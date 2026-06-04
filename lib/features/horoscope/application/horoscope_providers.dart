// lib/features/horoscope/application/horoscope_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/disk_cache.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../content/application/question_providers.dart';
import '../../users/application/user_providers.dart';
import '../data/daily_fortune_repository.dart';
import '../data/horoscope_repository.dart';
import '../domain/horoscope.dart';

final dailyFortuneRepositoryProvider = Provider<DailyFortuneRepository>(
  (ref) => DailyFortuneRepository(FirebaseFirestore.instance),
);

final horoscopeRepositoryProvider = Provider<HoroscopeRepository>((ref) {
  final uidAsync = ref.watch(currentUserIdProvider);
  final uid = uidAsync.valueOrNull;
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  return HoroscopeRepository(
    ref.watch(diskCacheProvider),
    ref.watch(dailyFortuneRepositoryProvider),
    ref.watch(aiQuestionRepositoryProvider),
    uid: uid,
    chartVersion:
        profile?.activeChartVersion ?? profile?.birthInfo?.chartVersion,
    utcOffset: profile?.birthInfo?.utcOffset,
  );
});

final todayHoroscopeProvider = FutureProvider<Horoscope>((ref) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  final profile = await ref.watch(currentUserProfileProvider.future);
  final user = ref.watch(currentUserProvider);
  final birthInfo = profile?.birthInfo;
  if (birthInfo == null) {
    throw StateError('출생 정보가 없어 오늘의 운세를 생성할 수 없어요.');
  }

  final chart = await ref.watch(myNatalChartProvider.future);
  final signSlug = (profile?.sunSign ?? user?.sunSign ?? chart.sunSign)
      .trim()
      .toLowerCase();
  if (signSlug.isEmpty || signSlug == '-') {
    throw StateError('오늘의 운세를 생성할 별자리 정보를 찾지 못했어요.');
  }

  return repo.getDaily(
    signSlug: signSlug,
    birthInfo: birthInfo,
    chart: chart,
    nickname:
        profile?.effectiveDisplayName ??
        user?.effectiveDisplayName ??
        '별자리',
  );
});
