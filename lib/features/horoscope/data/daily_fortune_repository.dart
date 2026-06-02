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
  }) async {
    final docId = _docId(uid, signSlug, date);
    try {
      final snap = await _col.doc(docId).get();
      final data = snap.data();
      if (data == null) return null;
      return Horoscope(
        signSlug: data['signSlug'] as String? ?? signSlug,
        signName: data['signName'] as String? ?? signSlug,
        date: DateTime.tryParse(data['date'] as String? ?? '') ?? date,
        summary: data['summary'] as String? ?? '',
        luckyColor: data['luckyColor'] as String? ?? '-',
        luckyNumber: (data['luckyNumber'] as num?)?.toInt() ?? 0,
        mood: data['mood'] as String? ?? '-',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required String uid,
    required Horoscope horoscope,
    String source = 'live',
  }) async {
    final docId = _docId(uid, horoscope.signSlug, horoscope.date);
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
        'source': source,
        'cachedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // 운세 캐시 저장 실패는 치명적이지 않음
    }
  }

  String _docId(String uid, String signSlug, DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${uid}_${signSlug}_$yyyy$mm$dd';
  }
}
