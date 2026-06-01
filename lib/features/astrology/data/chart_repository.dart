// lib/features/astrology/data/chart_repository.dart
//
// charts/{uid} 컬렉션 클라이언트 wrapper.
//
// 역할:
//   - 나탈 차트를 Firestore L3 캐시에 저장 (디스크 L2 미스 후 Firestore 조회)
//   - 저장 시 users/{uid}.sunSign + activeChartVersion 동기화 (runTransaction)
//
// 호출 순서 (AstrologyRepository 에서 사용):
//   1. DiskCache (L2) hit → 바로 반환
//   2. ChartRepository.get(uid, chartVersion) (L3) hit → 디스크에 저장 후 반환
//   3. ProkeralaApi 호출 → ChartRepository.save() → 디스크 저장 후 반환

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/natal_chart.dart';

class ChartRepository {
  ChartRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _charts =>
      _firestore.collection('charts');

  /// Firestore 에서 차트 조회. chartVersion 이 일치해야 유효한 캐시로 인정.
  Future<NatalChart?> get(String uid, String chartVersion) async {
    try {
      final snap = await _charts.doc(uid).get();
      final data = snap.data();
      if (data == null) return null;
      if (data['chartVersion'] != chartVersion) return null; // stale
      return NatalChart.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  /// 차트 저장 + users/{uid}.sunSign / activeChartVersion 동기화.
  /// runTransaction 으로 두 컬렉션을 원자적으로 갱신.
  Future<void> save({
    required String uid,
    required String chartVersion,
    required NatalChart chart,
  }) async {
    final now = FieldValue.serverTimestamp();
    final chartData = {
      'uid': uid,
      'chartVersion': chartVersion,
      'sunSign': chart.sunSign,
      'moonSign': chart.moonSign,
      'ascendantSign': chart.ascendantSign,
      'planets': chart.planets.map((p) => p.toJson()).toList(),
      'houses': chart.houses.map((h) => h.toJson()).toList(),
      'aspects': chart.aspects.map((a) => a.toJson()).toList(),
      'chartSummary': _buildSummary(chart),
      'updatedAt': now,
    };

    await _firestore.runTransaction((txn) async {
      final chartRef = _charts.doc(uid);
      final userRef = _firestore.collection('users').doc(uid);

      final chartSnap = await txn.get(chartRef);
      if (!chartSnap.exists) {
        // 신규 생성
        txn.set(chartRef, {...chartData, 'createdAt': now});
      } else {
        txn.update(chartRef, chartData);
      }

      // users 문서에 sunSign + activeChartVersion 동기화
      txn.update(userRef, {
        'sunSign': chart.sunSign,
        'activeChartVersion': chartVersion,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  /// AI 프롬프트용 압축 요약 생성. chartSummary 필드에 저장.
  String _buildSummary(NatalChart chart) {
    final sb = StringBuffer();
    sb.write('태양 ${chart.sunSign}, 달 ${chart.moonSign}, 어센던트 ${chart.ascendantSign}. ');
    // 주요 행성 3개만 추가
    final notable = chart.planets
        .where((p) => ['Mercury', 'Venus', 'Mars', 'Jupiter'].contains(p.name))
        .take(3);
    for (final p in notable) {
      sb.write('${p.name} ${p.sign}. ');
    }
    return sb.toString().trim();
  }
}
