// lib/features/compatibility/application/compatibility_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../data/synastry_repository.dart';
import '../domain/synastry_result.dart';

final synastryRepositoryProvider = Provider<SynastryRepository>(
  (ref) => SynastryRepository(ref.watch(prokeralaApiProvider)),
);

/// 두 사람의 출생정보를 묶은 record (Dart 3.0+).
typedef PartnerPair = ({BirthInfo me, BirthInfo partner});

final synastryProvider =
    FutureProvider.family<SynastryResult, PartnerPair>((ref, pair) {
  final repo = ref.watch(synastryRepositoryProvider);
  return repo.compare(me: pair.me, partner: pair.partner);
});
