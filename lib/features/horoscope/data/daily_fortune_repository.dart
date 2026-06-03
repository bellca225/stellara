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
        return Horoscope(
          signSlug: data['signSlug'] as String? ?? signSlug,
          signName: data['signName'] as String? ?? signSlug,
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? date,
          summary: data['summary'] as String? ?? '',
          luckyColor: data['luckyColor'] as String? ?? '-',
          luckyNumber: (data['luckyNumber'] as num?)?.toInt() ?? 0,
          mood: data['mood'] as String? ?? '-',
          luckyPlace:
              data['luckyPlace'] as String? ?? data['lucky_place'] as String?,
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
        'mood': horoscope.mood,
        'luckyPlace': horoscope.luckyPlace,
        'source': source,
        'chartVersion': chartVersion,
        'utcOffset': utcOffset,
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
