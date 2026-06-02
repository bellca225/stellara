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
  return HoroscopeRepository(
    ref.watch(prokeralaApiProvider),
    ref.watch(diskCacheProvider),
    ref.watch(dailyFortuneRepositoryProvider),
    uid: uid,
  );
});

/// 사용자가 선택한 별자리 (TODAY-001 화면 위쪽 picker).
/// 초기값: 로그인 사용자의 태양 별자리 → 없으면 'aquarius' fallback.
final selectedSignSlugProvider = StateProvider<String>((ref) {
  final sunSign = ref.watch(currentUserProvider)?.sunSign;
  if (sunSign != null && sunSign.isNotEmpty && sunSign != '-') {
    return sunSign.toLowerCase();
  }
  return 'aquarius';
});

/// 오늘 날짜 + 별자리 → 운세 fetch.
final todayHoroscopeProvider = FutureProvider<Horoscope>((ref) async {
  final slug = ref.watch(selectedSignSlugProvider);
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getDaily(signSlug: slug);
});
