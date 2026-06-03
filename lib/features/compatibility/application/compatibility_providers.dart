// lib/features/compatibility/application/compatibility_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/disk_cache.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../users/application/user_providers.dart';
import '../data/compatibility_engine.dart';
import '../data/synastry_cache_repository.dart';
import '../data/synastry_repository.dart';
import '../domain/synastry_result.dart';

final synastryCacheRepositoryProvider = Provider<SynastryCacheRepository>(
  (ref) => SynastryCacheRepository(FirebaseFirestore.instance),
);

final compatibilityEngineProvider = Provider<CompatibilityEngine>(
  (ref) => const CompatibilityEngine(),
);

final synastryRepositoryProvider = Provider<SynastryRepository>(
  (ref) => SynastryRepository(
    ref.watch(prokeralaApiProvider),
    ref.watch(diskCacheProvider),
    ref.watch(synastryCacheRepositoryProvider),
    ref.watch(chartRepositoryProvider),
    ref.watch(compatibilityEngineProvider),
  ),
);

/// 두 사람의 출생정보 + uid 를 묶은 record (Dart 3.0+).
typedef PartnerPair = ({
  BirthInfo me,
  BirthInfo partner,
  String? myUid,
  String? partnerUid,
});

final synastryProvider =
    FutureProvider.family<SynastryResult, PartnerPair>((ref, pair) {
  final repo = ref.watch(synastryRepositoryProvider);
  return repo.compare(
    me: pair.me,
    partner: pair.partner,
    myUid: pair.myUid,
    partnerUid: pair.partnerUid,
  );
});

/// 현재 사용자 + 친구 한 명의 궁합. MATCH-001 화면에서 사용.
/// [friendBirthInfo] 와 [friendUid] 는 친구 프로필에서 읽어온다.
final matchProvider = FutureProvider.family<SynastryResult, ({BirthInfo friendBirth, String friendUid})>(
  (ref, args) {
    final myBirth = ref.watch(currentBirthInfoProvider);
    if (myBirth == null) {
      return ref.watch(currentUserProfileProvider.future).then((_) {
        final loadedBirth = ref.read(currentBirthInfoProvider);
        if (loadedBirth == null) {
          throw StateError('내 출생 정보가 없습니다. 마이페이지에서 입력해주세요.');
        }
        final myUid = ref.read(currentUserIdProvider).valueOrNull;
        return ref.read(synastryRepositoryProvider).compare(
          me: loadedBirth,
          partner: args.friendBirth,
          myUid: myUid,
          partnerUid: args.friendUid,
        );
      });
    }
    final myUidAsync = ref.watch(currentUserIdProvider);
    final myUid = myUidAsync.valueOrNull;
    final repo = ref.watch(synastryRepositoryProvider);
    return repo.compare(
      me: myBirth,
      partner: args.friendBirth,
      myUid: myUid,
      partnerUid: args.friendUid,
    );
  },
);
