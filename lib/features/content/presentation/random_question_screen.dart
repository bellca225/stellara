// lib/features/content/presentation/random_question_screen.dart
//
// CONTENT-001 — 랜덤 질문 화면.
//
// Figma 흐름 기준:
//   1) 친구 선택
//   2) "새 질문" 눌러 질문 1개 생성
//   3) "답변 생성하기" 눌러 점성술 답변 노출
//   4) 질문/답변을 공유
//
// 구현 메모:
//   - AI ON이면 저장된 natal chart + synastry context 기반으로 질문/답변을 생성한다.
//   - 질문과 답변은 분리 호출하고, Firestore 최신 세션 캐시를 먼저 재사용한다.
//   - AI OFF 또는 차트/네트워크 이슈 시 로컬 질문 fallback으로 안전하게 동작한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/env/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/domain/synastry_result.dart';
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friend_screen.dart';
import '../../users/application/user_providers.dart';
import '../../users/domain/user_profile.dart';
import '../application/question_providers.dart';
import '../data/ai_question_repository.dart';
import '../domain/question_item.dart';
import '../domain/random_question_session.dart';

class RandomQuestionScreen extends ConsumerStatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  ConsumerState<RandomQuestionScreen> createState() =>
      _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends ConsumerState<RandomQuestionScreen> {
  String? _selectedFriendUid;
  bool _hasRequestedQuestion = false;
  bool _showAnswer = false;
  bool _isGeneratingQuestion = false;
  bool _isGeneratingAnswer = false;
  RandomQuestionSession? _session;

  Future<void> _requestNewQuestion(
    BuildContext context, {
    required Friend selectedFriend,
    required String? myUid,
    required String myNickname,
    required String? mySign,
    required NatalChart? myChart,
    required String friendChartVersion,
    required NatalChart? friendChart,
    required SynastryResult? synastry,
  }) async {
    if (_isGeneratingQuestion) return;
    if (_selectedFriendUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 친구를 선택해주세요.')));
      return;
    }
    if (myUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인 정보를 다시 확인해주세요.')));
      return;
    }

    setState(() {
      _isGeneratingQuestion = true;
      _showAnswer = false;
    });

    try {
      final myChartVersion =
          ref.read(currentBirthInfoProvider)?.chartVersion ?? 'missing-my-chart';
      final session = await ref
          .read(randomQuestionSessionRepositoryProvider)
          .loadOrGenerateQuestion(
            myUid: myUid,
            myNickname: myNickname,
            myChartVersion: myChartVersion,
            friendUid: selectedFriend.uid,
            friendNickname: selectedFriend.nickname,
            friendChartVersion: friendChartVersion,
            reuseExistingIfAvailable: !_hasRequestedQuestion,
            mySign: mySign,
            friendSign: selectedFriend.sunSign,
            myChart: myChart,
            friendChart: friendChart,
            synastry: synastry,
          );
      if (!mounted) return;
      setState(() {
        _session = session;
        _hasRequestedQuestion = true;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is AiQuotaExceededException
          ? 'AI 사용량이 초과되어 기본 결과를 보여드릴게요.'
          : '질문을 생성하지 못했어요.';
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingQuestion = false);
      }
    }
  }

  Future<void> _requestAnswer(
    BuildContext context, {
    required String myNickname,
    required String? mySign,
    required String friendSign,
    required NatalChart? myChart,
    required NatalChart? friendChart,
    required SynastryResult? synastry,
  }) async {
    final session = _session;
    if (session == null || _isGeneratingAnswer) return;

    if (session.hasAnswer) {
      setState(() => _showAnswer = true);
      return;
    }

    setState(() => _isGeneratingAnswer = true);

    try {
      final updated = await ref
          .read(randomQuestionSessionRepositoryProvider)
          .ensureAnswer(
            session: session,
            myNickname: myNickname,
            mySign: mySign ?? '-',
            friendSign: friendSign,
            myChart: myChart,
            friendChart: friendChart,
            synastry: synastry,
          );
      if (!mounted) return;
      setState(() {
        _session = updated;
        _showAnswer = true;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e is AiQuotaExceededException
          ? 'AI 사용량이 초과되어 기본 결과를 보여드릴게요.'
          : '답변을 생성하지 못했어요.';
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAnswer = false);
      }
    }
  }

  Future<void> _shareQuestion(BuildContext context, QuestionItem? item) async {
    if (item == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 질문을 생성해주세요.')));
      return;
    }
    final text = _showAnswer
        ? '✨ 랜덤 질문\n\n${item.prompt}\n\n점성술 답변\n${item.answer}\n\n#Stellara #랜덤질문'
        : '✨ 랜덤 질문\n\n${item.prompt}\n\n답변은 Stellara에서 확인해보세요!\n#Stellara #랜덤질문';
    try {
      await Share.share(text, subject: item.prompt);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final myUid = ref.watch(myUidProvider);
    final myNickname = ref.watch(myNicknameProvider) ?? '나';
    final mySign = ref.watch(mySunSignProvider);

    // ── AI ON일 때만 차트 로딩 — AI OFF면 Prokerala 호출 없음 ──────
    final aiEnabled = Env.aiRemoteEnabled;
    final myChartAsync = aiEnabled
        ? ref.watch(myChartForQuestionProvider)
        : const AsyncValue<NatalChart?>.data(null);

    return StarBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const SizedBox(height: 8),
            const ScreenCodeChip(code: 'CONTENT-001', label: '랜덤 질문'),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              '랜덤 질문',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              '친구를 선택하고 점성술 질문을 받아보세요',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            friendsAsync.when(
              loading: () => const Panel(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (error, _) =>
                  Panel(child: Text('친구 목록을 불러오지 못했어요: $error')),
              data: (friends) {
                if (friends.isEmpty) {
                  return Panel(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '아직 친구가 없어요.\n친구를 추가하면 별자리 질문을 받을 수 있어요!',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const FriendScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.person_add_outlined),
                              label: const Text('친구 추가하러 가기'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final selectedFriend = _resolveSelectedFriend(friends);
                final hasSelectedFriend = selectedFriend != null;

                // ── 친구 차트 로딩 (AI ON일 때만) ──────────────────
                final friendProfileAsync = (aiEnabled && hasSelectedFriend)
                    ? ref.watch(userProfileByIdProvider(selectedFriend.uid))
                    : const AsyncValue<UserProfile?>.data(null);
                final friendBirth = friendProfileAsync.valueOrNull?.birthInfo;

                final friendChartAsync =
                    (aiEnabled && hasSelectedFriend && friendBirth != null)
                    ? ref.watch(
                        friendStoredChartForQuestionProvider((
                          uid: selectedFriend.uid,
                          birth: friendBirth,
                        )),
                      )
                    : const AsyncValue<NatalChart?>.data(null);
                final friendChart = friendChartAsync.valueOrNull;
                final isFriendChartLoading =
                    aiEnabled &&
                    hasSelectedFriend &&
                    (friendProfileAsync.isLoading ||
                        friendChartAsync.isLoading);

                // ── Synastry (AI ON + 실제 birth 있을 때만, fixture 제외) ──
                final myBirth = aiEnabled
                    ? ref.watch(currentBirthInfoProvider)
                    : null;
                SynastryResult? synastry;
                if (hasSelectedFriend &&
                    !Env.shouldUseFixtureForProkerala &&
                    myBirth != null &&
                    friendBirth != null) {
                  synastry = ref
                      .watch(
                        matchProvider((
                          friendBirth: friendBirth,
                          friendUid: selectedFriend.uid,
                        )),
                      )
                      .valueOrNull;
                }

                // ── canUseAi: 모든 데이터가 준비됐을 때만 AI 호출 ──
                final myChart = myChartAsync.valueOrNull;
                final canUseAi =
                    aiEnabled &&
                    myChart != null &&
                    myChart != NatalChart.empty &&
                    friendChart != null &&
                    myUid != null;
                final generatedQuestion = _session?.question;
                final isQuestionLoading =
                    _isGeneratingQuestion ||
                    (_hasRequestedQuestion &&
                        _session == null &&
                        (myChartAsync.isLoading || isFriendChartLoading));

                return Column(
                  children: [
                    // ── 친구 선택 드롭다운 ──────────────────────────
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('친구 선택'),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedFriendUid,
                            dropdownColor: const Color(0xFF0D1B3E),
                            iconEnabledColor: AppColors.inkMuted,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.people_alt_outlined),
                              hintText: '친구 선택',
                            ),
                            items: [
                              for (final friend in friends)
                                DropdownMenuItem(
                                  value: friend.uid,
                                  child: Text(
                                    '${friend.nickname} · ${_signLabel(friend.sunSign)}',
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedFriendUid = value;
                                _hasRequestedQuestion = false;
                                _showAnswer = false;
                                _session = null;
                              });
                            },
                          ),
                          // 친구 차트 로딩 중 피드백
                          if (isFriendChartLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '친구 별자리 차트 불러오는 중...',
                                    style: TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // 친구 출생정보 없음 안내 — 친구를 선택했고 프로필 로드가 끝난 뒤에만 표시
                          if (aiEnabled &&
                              hasSelectedFriend &&
                              !isFriendChartLoading &&
                              friendProfileAsync.hasValue &&
                              friendBirth == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '이 친구는 아직 출생 정보를 입력하지 않았어요.\n로컬 질문으로 대체됩니다.',
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (aiEnabled &&
                              hasSelectedFriend &&
                              !isFriendChartLoading &&
                              friendBirth != null &&
                              friendChart == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                '이 친구의 저장된 점성술 분석이 아직 없어요.\n로컬 질문으로 대체됩니다.',
                                style: TextStyle(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                isQuestionLoading ||
                                    _isGeneratingAnswer ||
                                    !hasSelectedFriend
                                ? null
                                : () => _requestNewQuestion(
                                    context,
                                    selectedFriend: selectedFriend,
                                    myUid: myUid,
                                    myNickname: myNickname,
                                    mySign: mySign,
                                    myChart: myChart,
                                    friendChartVersion:
                                        friendBirth?.chartVersion ??
                                        'missing-friend-chart',
                                    friendChart: canUseAi ? friendChart : null,
                                    synastry: synastry,
                                  ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('새 질문'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: generatedQuestion == null
                                ? null
                                : () => _shareQuestion(
                                    context,
                                    generatedQuestion,
                                  ),
                            icon: const Icon(Icons.share_outlined, size: 18),
                            label: const Text('공유하기'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    if (!hasSelectedFriend)
                      const Panel(
                        child: Text(
                          '친구를 선택하고 "새 질문" 버튼을 눌러 시작하세요',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (!_hasRequestedQuestion)
                      const Panel(
                        child: Text(
                          '친구를 선택하고 "새 질문" 버튼을 눌러 시작하세요',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else if (isQuestionLoading)
                      const _SingleQuestionLoadingCard()
                    else if (generatedQuestion == null)
                      const Panel(
                        child: Text(
                          '질문을 준비하지 못했어요. 다시 시도해주세요.',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 16,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      _QuestionPromptCard(
                        item: generatedQuestion,
                        onRevealAnswer: () => _requestAnswer(
                          context,
                          myNickname: myNickname,
                          mySign: mySign,
                          friendSign: selectedFriend.sunSign,
                          myChart: canUseAi ? myChart : null,
                          friendChart: canUseAi ? friendChart : null,
                          synastry: synastry,
                        ),
                        showAnswerButton: !_showAnswer,
                        isLoadingAnswer: _isGeneratingAnswer,
                      ),
                      if (_showAnswer) ...[
                        const SizedBox(height: AppSpacing.md),
                        _QuestionAnswerCard(item: generatedQuestion),
                      ],
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Friend? _resolveSelectedFriend(List<Friend> friends) {
    final uid = _selectedFriendUid;
    if (uid == null) return null;
    for (final f in friends) {
      if (f.uid == uid) return f;
    }
    return null;
  }
}

// ── 서브 위젯 ──────────────────────────────────────────────────────────────────

class _QuestionPromptCard extends StatelessWidget {
  const _QuestionPromptCard({
    required this.item,
    required this.onRevealAnswer,
    required this.showAnswerButton,
    required this.isLoadingAnswer,
  });

  final QuestionItem item;
  final VoidCallback onRevealAnswer;
  final bool showAnswerButton;
  final bool isLoadingAnswer;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.prompt,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (showAnswerButton) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoadingAnswer ? null : onRevealAnswer,
                icon: isLoadingAnswer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  isLoadingAnswer ? '답변 생성 중...' : '답변 생성하기',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionAnswerCard extends StatelessWidget {
  const _QuestionAnswerCard({required this.item});

  final QuestionItem item;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
                child: Text(
                  item.isAiGenerated ? 'AI 점성술 답변' : '점성술 답변',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.answer,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 14,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleQuestionLoadingCard extends StatelessWidget {
  const _SingleQuestionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: double.infinity, height: 22),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 22),
          SizedBox(height: AppSpacing.lg),
          SkeletonBox(width: double.infinity, height: 48, radius: 999),
        ],
      ),
    );
  }
}

String _signLabel(String sign) {
  final normalized = sign.trim().toLowerCase();
  if (normalized.isEmpty || normalized == '-') return '별자리 미확인';
  return zodiacNameKo(sign);
}
