// lib/features/content/application/question_providers.dart
//
// 질문 생성 Provider 모음.
//
// AI 활성화 여부(Env.aiRemoteEnabled)에 따라 자동으로 전략이 전환됨:
//   - AI ON  → AiQuestionRepository (GPT-4o-mini) → 실패 시 로컬 fallback
//   - AI OFF → QuestionRepository (로컬 템플릿)
//
// 기존 localQuestionSetProvider / customQuestionProvider 는 하위 호환 유지.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../auth/application/auth_providers.dart';
import '../../compatibility/domain/synastry_result.dart';
import '../data/ai_question_repository.dart';
import '../data/question_repository.dart';
import '../domain/question_item.dart';

// ── Repository providers ─────────────────────────────────────────────────────

final questionRepositoryProvider = Provider<QuestionRepository>(
  (ref) => QuestionRepository(),
);

final aiQuestionRepositoryProvider = Provider<AiQuestionRepository>(
  (ref) => AiQuestionRepository(
    localFallback: ref.watch(questionRepositoryProvider),
  ),
);

// ── Request typedefs ─────────────────────────────────────────────────────────

/// AI 질문 생성 요청 — NatalChart를 포함한 풍부한 context.
typedef AiQuestionRequest = ({
  String myUid,
  String myNickname,
  NatalChart myChart,
  String friendUid,
  String friendNickname,
  NatalChart friendChart,
  SynastryResult? synastry,
  int revision,
});

/// 로컬 질문 요청 (하위 호환)
typedef LocalQuestionRequest = ({
  String friendUid,
  String friendName,
  String? friendSign,
  String? mySign,
  int revision,
});

/// AI 커스텀 답변 요청
typedef AiCustomAnswerRequest = ({
  String myNickname,
  NatalChart myChart,
  String friendUid,
  String friendNickname,
  NatalChart friendChart,
  SynastryResult? synastry,
  String userPrompt,
});

/// 로컬 커스텀 답변 요청 (하위 호환)
typedef CustomQuestionRequest = ({
  String friendUid,
  String friendName,
  String? friendSign,
  String? mySign,
  String userPrompt,
});

// ── AI Question providers ────────────────────────────────────────────────────

/// 메인 질문 생성 provider — AI ON 시 GPT-4o-mini, OFF 시 로컬 자동 전환.
final aiQuestionSetProvider =
    FutureProvider.family<List<QuestionItem>, AiQuestionRequest>((ref, req) {
      return ref
          .watch(aiQuestionRepositoryProvider)
          .generateAiQuestions(
            myUid: req.myUid,
            myNickname: req.myNickname,
            myChart: req.myChart,
            friendUid: req.friendUid,
            friendNickname: req.friendNickname,
            friendChart: req.friendChart,
            synastry: req.synastry,
            revision: req.revision,
          );
    });

final aiSingleQuestionProvider =
    FutureProvider.family<QuestionItem, AiQuestionRequest>((ref, req) async {
      final questions = await ref
          .watch(aiQuestionRepositoryProvider)
          .generateAiQuestions(
            myUid: req.myUid,
            myNickname: req.myNickname,
            myChart: req.myChart,
            friendUid: req.friendUid,
            friendNickname: req.friendNickname,
            friendChart: req.friendChart,
            synastry: req.synastry,
            count: 1,
            revision: req.revision,
          );
      return questions.first;
    });

/// 커스텀 질문 AI 해설 provider
final aiCustomAnswerProvider =
    FutureProvider.family<QuestionItem, AiCustomAnswerRequest>((ref, req) {
      return ref
          .watch(aiQuestionRepositoryProvider)
          .generateCustomAnswer(
            myNickname: req.myNickname,
            myChart: req.myChart,
            friendUid: req.friendUid,
            friendNickname: req.friendNickname,
            friendChart: req.friendChart,
            synastry: req.synastry,
            userPrompt: req.userPrompt,
          );
    });

// ── 로컬 providers (하위 호환) ───────────────────────────────────────────────

final localQuestionSetProvider =
    FutureProvider.family<List<QuestionItem>, LocalQuestionRequest>((
      ref,
      request,
    ) {
      return ref
          .watch(questionRepositoryProvider)
          .generate(
            providerPreference: 'local',
            friendUid: request.friendUid,
            friendName: request.friendName,
            friendSign: request.friendSign,
            mySign: request.mySign,
            count: 3,
            revision: request.revision,
          );
    });

final localSingleQuestionProvider =
    FutureProvider.family<QuestionItem, LocalQuestionRequest>((
      ref,
      request,
    ) async {
      final questions = await ref
          .watch(questionRepositoryProvider)
          .generate(
            providerPreference: 'local',
            friendUid: request.friendUid,
            friendName: request.friendName,
            friendSign: request.friendSign,
            mySign: request.mySign,
            count: 1,
            revision: request.revision,
          );
      return questions.first;
    });

final customQuestionProvider =
    FutureProvider.family<QuestionItem, CustomQuestionRequest>((ref, request) {
      return ref
          .watch(questionRepositoryProvider)
          .answerCustom(
            providerPreference: 'local',
            friendUid: request.friendUid,
            friendName: request.friendName,
            userPrompt: request.userPrompt,
            friendSign: request.friendSign,
            mySign: request.mySign,
          );
    });

// ── 편의 providers ───────────────────────────────────────────────────────────

final mySunSignProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.sunSign;
});

final myUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

/// 화면에 표시할 내 이름. displayName → nickname → loginId 순 fallback.
final myNicknameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return user.effectiveDisplayName;
});

/// 나의 NatalChart — 화면에서 AI request 구성 시 편하게 사용
final myChartForQuestionProvider = FutureProvider<NatalChart?>((ref) async {
  try {
    return await ref.watch(myNatalChartProvider.future);
  } catch (_) {
    return null;
  }
});
