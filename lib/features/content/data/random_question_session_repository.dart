import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../astrology/domain/natal_chart.dart';
import '../../compatibility/domain/synastry_result.dart';
import '../domain/question_item.dart';
import '../domain/random_question_session.dart';
import 'ai_question_repository.dart';
import 'question_repository.dart';

class RandomQuestionSessionRepository {
  RandomQuestionSessionRepository(
    this._firestore,
    this._aiRepository,
    this._localRepository,
  );

  final FirebaseFirestore _firestore;
  final AiQuestionRepository _aiRepository;
  final QuestionRepository _localRepository;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('randomQuestionSessions');

  static String buildPairKey(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted.first}__${sorted.last}';
  }

  static String buildChartPairVersion(String version1, String version2) {
    final sorted = [version1, version2]..sort();
    return '${sorted.first}__${sorted.last}';
  }

  static String buildDocId({
    required String myUid,
    required String friendUid,
    required String myChartVersion,
    required String friendChartVersion,
  }) {
    final pairKey = buildPairKey(myUid, friendUid);
    final chartPairVersion = buildChartPairVersion(
      myChartVersion,
      friendChartVersion,
    );
    return '${pairKey}__$chartPairVersion';
  }

  Future<RandomQuestionSession?> getLatest({
    required String myUid,
    required String friendUid,
    required String myChartVersion,
    required String friendChartVersion,
  }) async {
    try {
      final docId = buildDocId(
        myUid: myUid,
        friendUid: friendUid,
        myChartVersion: myChartVersion,
        friendChartVersion: friendChartVersion,
      );
      final snap = await _col.doc(docId).get();
      final data = snap.data();
      if (data == null) return null;
      return RandomQuestionSession.fromJson(data, docId: snap.id);
    } catch (_) {
      return null;
    }
  }

  Future<RandomQuestionSession> loadOrGenerateQuestion({
    required String myUid,
    required String myNickname,
    required String myChartVersion,
    required String friendUid,
    required String friendNickname,
    required String friendChartVersion,
    required bool reuseExistingIfAvailable,
    String? mySign,
    String? friendSign,
    NatalChart? myChart,
    NatalChart? friendChart,
    SynastryResult? synastry,
  }) async {
    final existing = await getLatest(
      myUid: myUid,
      friendUid: friendUid,
      myChartVersion: myChartVersion,
      friendChartVersion: friendChartVersion,
    );
    if (reuseExistingIfAvailable && existing != null) {
      return existing;
    }

    if (myChart == null || friendChart == null) {
      final local = await _localRepository.generate(
        providerPreference: 'local',
        friendUid: friendUid,
        friendName: friendNickname,
        friendSign: friendSign,
        mySign: mySign,
        count: 1,
        revision: (existing?.revision ?? 0) + 1,
      );
      return _buildEphemeralSession(
        myUid: myUid,
        friendUid: friendUid,
        friendDisplayName: friendNickname,
        myChartVersion: myChartVersion,
        friendChartVersion: friendChartVersion,
        revision: (existing?.revision ?? 0) + 1,
        question: local.first,
        synastry: synastry,
        myChart: myChart,
        friendChart: friendChart,
      );
    }

    final nextRevision = (existing?.revision ?? 0) + 1;
    final item = await _aiRepository.generateSingleRandomQuestion(
      myUid: myUid,
      myNickname: myNickname,
      myChart: myChart,
      friendUid: friendUid,
      friendNickname: friendNickname,
      friendChart: friendChart,
      synastry: synastry,
      revision: nextRevision,
    );
    final now = DateTime.now();
    final sessionId = 'rq-${now.millisecondsSinceEpoch}-${friendUid.hashCode.abs()}';
    final normalizedQuestion = item.copyWith(
      sessionId: sessionId,
      generatedAt: now,
    );
    final session = RandomQuestionSession(
      docId: buildDocId(
        myUid: myUid,
        friendUid: friendUid,
        myChartVersion: myChartVersion,
        friendChartVersion: friendChartVersion,
      ),
      sessionId: sessionId,
      pairKey: buildPairKey(myUid, friendUid),
      chartPairVersion: buildChartPairVersion(
        myChartVersion,
        friendChartVersion,
      ),
      myUid: myUid,
      friendUid: friendUid,
      friendDisplayName: friendNickname,
      revision: nextRevision,
      question: normalizedQuestion,
      status: normalizedQuestion.hasAnswer
          ? RandomQuestionSessionStatus.answerReady
          : RandomQuestionSessionStatus.questionReady,
      promptVersion: AiQuestionRepository.randomQuestionPromptVersion,
      generatedAt: now,
      updatedAt: now,
      contextSnapshot: _buildContextSnapshot(
        myChart: myChart,
        friendChart: friendChart,
        synastry: synastry,
      ),
    );
    await _persist(session);
    return session;
  }

  Future<RandomQuestionSession> ensureAnswer({
    required RandomQuestionSession session,
    required String myNickname,
    required String mySign,
    required String friendSign,
    NatalChart? myChart,
    NatalChart? friendChart,
    SynastryResult? synastry,
  }) async {
    if (session.hasAnswer) {
      return session.copyWith(status: RandomQuestionSessionStatus.answerReady);
    }

    if (myChart == null || friendChart == null) {
      final fallback = await _localRepository.answerCustom(
        providerPreference: 'local',
        friendUid: session.friendUid,
        friendName: session.friendDisplayName,
        friendSign: friendSign,
        mySign: mySign,
        userPrompt: session.question.prompt,
      );
      final updated = session.copyWith(
        question: session.question.copyWith(
          answer: fallback.answer,
          source: fallback.source,
        ),
        status: RandomQuestionSessionStatus.answerReady,
        updatedAt: DateTime.now(),
        promptVersion:
            '${session.promptVersion}|${AiQuestionRepository.randomAnswerPromptVersion}',
      );
      if (session.docId != null) {
        await _persist(updated);
      }
      return updated;
    }

    // Firestore에서 최신 상태 재확인 (이미 다른 기기에서 답변이 생성됐을 수 있음)
    // permission-denied 등 실패 시 스킵하고 AI 호출로 진행
    if (session.docId != null) {
      try {
        final current = await _col.doc(session.docId).get();
        final data = current.data();
        if (data != null) {
          final latest = RandomQuestionSession.fromJson(data, docId: current.id);
          if (latest.hasAnswer) return latest;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[RandomQuestionSession] ensureAnswer Firestore read 실패 (스킵): $e');
      }
    }

    // generateAnswerForQuestion은 내부적으로 로컬 fallback이 있어 항상 QuestionItem을 반환
    final answerItem = await _aiRepository.generateAnswerForQuestion(
      myNickname: myNickname,
      myChart: myChart,
      friendUid: session.friendUid,
      friendNickname: session.friendDisplayName,
      friendChart: friendChart,
      questionPrompt: session.question.prompt,
      synastry: synastry,
    );
    final updated = session.copyWith(
      question: session.question.copyWith(
        answer: answerItem.answer,
        source: answerItem.source,
      ),
      status: RandomQuestionSessionStatus.answerReady,
      updatedAt: DateTime.now(),
      promptVersion:
          '${session.promptVersion}|${AiQuestionRepository.randomAnswerPromptVersion}',
    );
    // _persist 실패는 비치명 — 답변은 메모리에서 정상 표시됨
    if (session.docId != null) {
      await _persist(updated);
    }
    return updated;
  }

  Future<void> _persist(RandomQuestionSession session) async {
    final docId = session.docId;
    if (docId == null) return;
    try {
      await _col.doc(docId).set(session.toJson());
    } catch (e) {
      // Firestore 저장 실패는 치명적이지 않음 — 세션은 메모리에서 정상 동작 유지.
      // (권한 오류, 네트워크 오류 등)
      if (kDebugMode) debugPrint('[RandomQuestionSession] _persist 실패 (비치명): $e');
    }
  }

  RandomQuestionSession _buildEphemeralSession({
    required String myUid,
    required String friendUid,
    required String friendDisplayName,
    required String myChartVersion,
    required String friendChartVersion,
    required int revision,
    required QuestionItem question,
    NatalChart? myChart,
    NatalChart? friendChart,
    SynastryResult? synastry,
  }) {
    final now = DateTime.now();
    final sessionId =
        'local-rq-${now.millisecondsSinceEpoch}-${friendUid.hashCode.abs()}';
    final normalizedQuestion = question.copyWith(
      sessionId: sessionId,
      generatedAt: now,
    );
    return RandomQuestionSession(
      sessionId: sessionId,
      pairKey: buildPairKey(myUid, friendUid),
      chartPairVersion: buildChartPairVersion(
        myChartVersion,
        friendChartVersion,
      ),
      myUid: myUid,
      friendUid: friendUid,
      friendDisplayName: friendDisplayName,
      revision: revision,
      question: normalizedQuestion,
      status: normalizedQuestion.hasAnswer
          ? RandomQuestionSessionStatus.answerReady
          : RandomQuestionSessionStatus.questionReady,
      promptVersion: 'local-fallback',
      generatedAt: now,
      updatedAt: now,
      contextSnapshot: _buildContextSnapshot(
        myChart: myChart,
        friendChart: friendChart,
        synastry: synastry,
      ),
    );
  }

  Map<String, dynamic> _buildContextSnapshot({
    NatalChart? myChart,
    NatalChart? friendChart,
    SynastryResult? synastry,
  }) {
    Map<String, dynamic>? chartSnapshot(NatalChart? chart) {
      if (chart == null || chart == NatalChart.empty) return null;
      String? planetSign(String name) {
        for (final planet in chart.planets) {
          if (planet.name.toLowerCase() == name.toLowerCase()) {
            return planet.sign;
          }
        }
        return null;
      }

      return {
        'sun': chart.sunSign,
        'moon': chart.moonSign,
        'ascendant': chart.ascendantSign,
        'mercury': planetSign('Mercury'),
        'venus': planetSign('Venus'),
        'mars': planetSign('Mars'),
      };
    }

    return {
      if (chartSnapshot(myChart) != null) 'me': chartSnapshot(myChart),
      if (chartSnapshot(friendChart) != null) 'friend': chartSnapshot(friendChart),
      if (synastry != null)
        'synastry': {
          'totalScore': synastry.totalScore,
          'emotionScore': synastry.emotionScore,
          'communicationScore': synastry.communicationScore,
          'romanceScore': synastry.romanceScore,
          'friendshipScore': synastry.friendshipScore,
        },
    };
  }
}
