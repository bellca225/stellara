// lib/features/compatibility/data/synastry_cache_repository.dart
//
// synastryCaches/{docId} 컬렉션 wrapper (Firestore L3 캐시).
//
// docId = {pairKey}|{chartPairVersion}
//   - pairKey: uid 두 개를 정렬 후 __ 연결
//   - chartPairVersion: chartVersion 두 개를 정렬 후 __ 연결
// 어느 한 쪽 birthInfo 가 바뀌면 chartVersion 이 달라져 자동 cache miss.
//
// 기존 SynastryRepository 캐시 흐름:
//   L2 DiskCache → L3 이 파일 (Firestore) → 로컬 compatibility engine 계산

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../astrology/domain/birth_info.dart';
import '../../astrology/domain/natal_chart.dart';
import '../domain/synastry_result.dart';

class SynastryCacheRepository {
  SynastryCacheRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('synastryCaches');

  /// Firestore 에서 궁합 캐시 조회.
  Future<SynastryResult?> get({
    required String uid1,
    required String uid2,
    required String meVersion,
    required String partnerVersion,
    required String expectedEngineVersion,
  }) async {
    final pairKey = buildPairKey(uid1, uid2);
    final chartPairVersion = buildChartPairVersion(meVersion, partnerVersion);
    final docId = buildDocId(pairKey, chartPairVersion);
    try {
      final snap = await _col.doc(docId).get();
      final data = snap.data();
      if (data == null) return null;
      if (data['engineVersion'] != expectedEngineVersion) return null;
      if (data['pairKey'] != pairKey) return null;
      if (data['chartPairVersion'] != chartPairVersion) return null;
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
    required BirthInfo meBirth,
    required BirthInfo partnerBirth,
    required NatalChart meChart,
    required NatalChart partnerChart,
    required SynastryResult result,
  }) async {
    final pairKey = buildPairKey(uid1, uid2);
    final chartPairVersion = buildChartPairVersion(meVersion, partnerVersion);
    final docId = buildDocId(pairKey, chartPairVersion);
    final sorted = ([uid1, uid2]..sort());
    try {
      await _col.doc(docId).set({
        ...result.toJson(),
        'userIds': sorted,
        'uid1': sorted[0],
        'uid2': sorted[1],
        'pairKey': pairKey,
        'chartPairVersion': chartPairVersion,
        'analysisSnapshot1': _buildSnapshot(
          uid: uid1,
          chartVersion: meVersion,
          birth: meBirth,
          chart: meChart,
        ),
        'analysisSnapshot2': _buildSnapshot(
          uid: uid2,
          chartVersion: partnerVersion,
          birth: partnerBirth,
          chart: partnerChart,
        ),
        'generatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 캐시 저장 실패는 치명적이지 않음 — 무시하고 결과는 그대로 반환
    }
  }

  static String buildPairKey(String uid1, String uid2) =>
      ([uid1, uid2]..sort()).join('__');

  static String buildChartPairVersion(String version1, String version2) =>
      ([version1, version2]..sort()).join('__');

  static String buildDocId(String pairKey, String chartPairVersion) =>
      '$pairKey|$chartPairVersion';

  Map<String, dynamic> _buildSnapshot({
    required String uid,
    required String chartVersion,
    required BirthInfo birth,
    required NatalChart chart,
  }) {
    String pad(int n) => n.toString().padLeft(2, '0');
    final dt = birth.dateTime;
    return {
      'uid': uid,
      'chartVersion': chartVersion,
      'birthDate': '${dt.year}-${pad(dt.month)}-${pad(dt.day)}',
      'birthTime': '${pad(dt.hour)}:${pad(dt.minute)}',
      'birthPlace': birth.placeName ?? '',
      'latitude': birth.latitude,
      'longitude': birth.longitude,
      'timezone': birth.utcOffset,
      'sunSign': chart.sunSign,
      'moonSign': chart.moonSign,
      'ascendantSign': chart.ascendantSign,
    };
  }
}
