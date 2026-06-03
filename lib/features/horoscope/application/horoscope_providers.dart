// lib/features/horoscope/application/horoscope_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/disk_cache.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../auth/application/auth_providers.dart';
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
    ref.watch(prokeralaApiProvider),
    ref.watch(diskCacheProvider),
    ref.watch(dailyFortuneRepositoryProvider),
    uid: uid,
    chartVersion:
        profile?.activeChartVersion ?? profile?.birthInfo?.chartVersion,
    utcOffset: profile?.birthInfo?.utcOffset,
  );
});

final todayHoroscopeProvider = FutureProvider<Horoscope>((ref) async {
  final repo = ref.watch(horoscopeRepositoryProvider);
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  final user = ref.watch(currentUserProvider);

  String? signSlug = profile?.sunSign ?? user?.sunSign;
  if (signSlug == null || signSlug.trim().isEmpty || signSlug.trim() == '-') {
    final chart = await ref.watch(myNatalChartProvider.future);
    signSlug = chart.sunSign;
  }

  final normalized = signSlug.trim().toLowerCase();
  if (normalized.isEmpty || normalized == '-') {
    throw StateError('오늘의 운세를 생성할 별자리 정보를 찾지 못했어요.');
  }

  return repo.getDaily(signSlug: normalized);
});
