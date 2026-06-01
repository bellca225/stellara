// lib/features/compatibility/data/synastry_cache_repository.dart
//
// synastryCaches/{docId} 컬렉션 wrapper (Firestore L3 캐시).
//
// pairKey = [chartVersion_me, chartVersion_partner] 정렬 후 __ 연결.
// 어느 한 쪽 birthInfo 가 바뀌면 chartVersion 이 달라져 자동 cache miss.
//
// 기존 SynastryRepository 캐시 흐름:
//   L0 fixture → L2 DiskCache → L3 이 파일 (Firestore) → Prokerala API 호출

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/synastry_result.dart';

class SynastryCacheRepository {
  SynastryCacheRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('synastryCaches');

  /// Firestore 에서 궁합 캐시 조회.
  Future<SynastryResult?> get(String meVersion, String partnerVersion) async {
    final docId = _docId(meVersion, partnerVersion);
    try {
      final snap = await _col.doc(docId).get();
      final data = snap.data();
      if (data == null) return null;
      return SynastryResult.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// 궁합 결과를 Firestore 에 저장.
  Future<void> save({
    required String uid1,
    required String uid2,
    required String meVersion,
    required String partnerVersion,
    required SynastryResult result,
  }) async {
    final docId = _docId(meVersion, partnerVersion);
    final sorted = ([uid1, uid2]..sort());
    try {
      await _col.doc(docId).set({
        ...result.toJson(),
        'userIds': sorted,       // firestore.rules 에서 userIds 배열로 권한 체크
        'chartPairVersion': docId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 캐시 저장 실패는 치명적이지 않음 — 무시하고 결과는 그대로 반환
    }
  }

  String _docId(String v1, String v2) =>
      ([v1, v2]..sort()).join('__');
}
