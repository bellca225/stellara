import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/horoscope.dart';

class DailyFortuneRepository {
  DailyFortuneRepository(this._firestore);
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('dailyFortunes');

  Future<Horoscope?> get({
    required String uid,
    required String signSlug,
    required DateTime date,
    String? chartVersion,
  }) async {
    try {
      final docIds = <String>[
        _docId(uid, signSlug, date, chartVersion: chartVersion),
        if (chartVersion != null && chartVersion.isNotEmpty)
          _legacyDocId(uid, signSlug, date),
      ];
      for (final docId in docIds) {
        final snap = await _col.doc(docId).get();
        final data = snap.data();
        if (data == null) continue;
        final luckyNumbers = <int>[
          for (final value in (data['luckyNumbers'] as List? ?? const []))
            if (value is num) value.toInt(),
        ];
        final legacyLuckyNumber = (data['luckyNumber'] as num?)?.toInt();
        if (luckyNumbers.isEmpty &&
            legacyLuckyNumber != null &&
            legacyLuckyNumber > 0) {
          luckyNumbers.addAll([
            legacyLuckyNumber,
            legacyLuckyNumber * 2,
            legacyLuckyNumber * 3,
          ]);
        }
        return Horoscope(
          signSlug: data['signSlug'] as String? ?? signSlug,
          signName: data['signName'] as String? ?? signSlug,
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? date,
          summary: data['summary'] as String? ?? '',
          luckyColor: data['luckyColor'] as String? ?? '-',
          luckyNumbers: luckyNumbers,
          mood: data['mood'] as String? ?? '-',
          luckyPlace:
              data['luckyPlace'] as String? ?? data['lucky_place'] as String?,
          advice: data['advice'] as String? ?? '',
          caution: data['caution'] as String? ?? '',
          shareText: data['shareText'] as String? ?? '',
          promptVersion: data['promptVersion'] as String?,
          chartVersion: data['chartVersion'] as String?,
          utcOffset: data['utcOffset'] as String?,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String uid,
    required Horoscope horoscope,
    String source = 'live',
    String? chartVersion,
    String? utcOffset,
    Map<String, dynamic>? birthSnapshot,
    Map<String, dynamic>? analysisSnapshot,
  }) async {
    final docId = _docId(
      uid,
      horoscope.signSlug,
      horoscope.date,
      chartVersion: chartVersion,
    );
    try {
      await _col.doc(docId).set({
        'uid': uid,
        'signSlug': horoscope.signSlug,
        'signName': horoscope.signName,
        'date':
            '${horoscope.date.year.toString().padLeft(4, '0')}-${horoscope.date.month.toString().padLeft(2, '0')}-${horoscope.date.day.toString().padLeft(2, '0')}',
        'summary': horoscope.summary,
        'luckyColor': horoscope.luckyColor,
        'luckyNumber': horoscope.luckyNumber,
        'luckyNumbers': horoscope.luckyNumbers,
        'mood': horoscope.mood,
        'luckyPlace': horoscope.luckyPlace,
        'advice': horoscope.advice,
        'caution': horoscope.caution,
        'shareText': horoscope.shareText,
        'source': source,
        'promptVersion': horoscope.promptVersion,
        'chartVersion': chartVersion ?? horoscope.chartVersion,
        'utcOffset': utcOffset ?? horoscope.utcOffset,
        'birthSnapshot': birthSnapshot,
        'analysisSnapshot': analysisSnapshot,
        'cachedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 운세 캐시 저장 실패는 치명적이지 않음
    }
  }

  String _docId(
    String uid,
    String signSlug,
    DateTime date, {
    String? chartVersion,
  }) {
    if (chartVersion == null || chartVersion.isEmpty) {
      return _legacyDocId(uid, signSlug, date);
    }
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${uid}_${signSlug}_${chartVersion}_$yyyy$mm$dd';
  }

  String _legacyDocId(String uid, String signSlug, DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${uid}_${signSlug}_$yyyy$mm$dd';
  }
}
