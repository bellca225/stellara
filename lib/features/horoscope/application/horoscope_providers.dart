// lib/features/horoscope/application/horoscope_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../astrology/application/astrology_providers.dart';
import '../data/horoscope_repository.dart';
import '../domain/horoscope.dart';

final horoscopeRepositoryProvider = Provider<HoroscopeRepository>(
  (ref) => HoroscopeRepository(ref.watch(prokeralaApiProvider)),
);

/// 사용자가 선택한 별자리 (TODAY-001 화면 위쪽 picker).
final selectedSignSlugProvider = StateProvider<String>((ref) => 'aquarius');

/// 오늘 날짜 + 별자리 → 운세 fetch.
final todayHoroscopeProvider = FutureProvider<Horoscope>((ref) async {
  final slug = ref.watch(selectedSignSlugProvider);
  final repo = ref.watch(horoscopeRepositoryProvider);
  return repo.getDaily(signSlug: slug);
});
