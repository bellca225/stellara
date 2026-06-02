// lib/features/content/presentation/random_question_screen.dart
//
// CONTENT-001 — 랜덤 질문 화면.
//
// AI ON (Env.aiRemoteEnabled=true):
//   친구 선택 → 양쪽 차트 로드 완료 후 → GPT-4o-mini → 질문 3개 + 해설
//   (차트 로드 중에는 로컬 질문을 먼저 보여주지 않고 로딩 상태 유지 → race condition 방지)
//
// AI OFF (기본):
//   친구 선택 → 차트 로딩 없이 → 로컬 템플릿 → 질문 3개 + 해설
//   (Prokerala/Synastry API 호출 없음 → credit 절약)
//
// 디자인/CSS: 도연 담당. UI 구조 변경 금지.

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
import '../domain/question_item.dart';

class RandomQuestionScreen extends ConsumerStatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  ConsumerState<RandomQuestionScreen> createState() =>
      _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends ConsumerState<RandomQuestionScreen> {
  final _customQuestionCtrl = TextEditingController();

  String? _selectedFriendUid;
  String? _submittedPrompt;
  int _revision = 0;

  @override
  void dispose() {
    _customQuestionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final myUid = ref.watch(myUidProvider);
    final myNickname = ref.watch(myNicknameProvider) ?? '나';

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

                // ── 친구 차트 로딩 (AI ON일 때만) ──────────────────
                final friendProfileAsync = aiEnabled
                    ? ref.watch(userProfileByIdProvider(selectedFriend.uid))
                    : const AsyncValue<UserProfile?>.data(null);
                final friendBirth = friendProfileAsync.valueOrNull?.birthInfo;

                final friendChartAsync = (aiEnabled && friendBirth != null)
                    ? ref.watch(natalChartProvider(friendBirth))
                    : const AsyncValue<NatalChart>.data(NatalChart.empty);
                final friendChart = friendChartAsync.valueOrNull;
                final isFriendChartLoading = aiEnabled &&
                    (friendProfileAsync.isLoading || friendChartAsync.isLoading);

                // ── Synastry (AI ON + 실제 birth 있을 때만, fixture 제외) ──
                final myBirth =
                    aiEnabled ? ref.watch(currentBirthInfoProvider) : null;
                SynastryResult? synastry;
                if (!Env.shouldUseFixtureForProkerala &&
                    myBirth != null &&
                    friendBirth != null) {
                  synastry = ref
                      .watch(matchProvider((
                        friendBirth: friendBirth,
                        friendUid: selectedFriend.uid,
                      )))
                      .valueOrNull;
                }

                // ── canUseAi: 모든 데이터가 준비됐을 때만 AI 호출 ──
                final myChart = myChartAsync.valueOrNull;
                final canUseAi =
                    aiEnabled &&
                    myChart != null &&
                    myChart != NatalChart.empty &&
                    friendChart != null &&
                    friendChart != NatalChart.empty &&
                    myUid != null;

                // ── 질문 provider 결정 ────────────────────────────
                // AI ON + 차트 아직 로딩 중 → 로딩 상태 (로컬 질문 먼저 보여주지 않음)
                // AI ON + 차트 준비 → AI 질문
                // AI OFF → 항상 로컬
                final AsyncValue<List<QuestionItem>> questionsAsync;
                if (!aiEnabled) {
                  questionsAsync = ref.watch(localQuestionSetProvider((
                    friendUid: selectedFriend.uid,
                    friendName: selectedFriend.nickname,
                    friendSign: selectedFriend.sunSign,
                    mySign: ref.watch(mySunSignProvider),
                    revision: _revision,
                  )));
                } else if (!canUseAi) {
                  // AI ON이지만 차트 로딩 중 → 로딩 유지 (race condition 방지)
                  questionsAsync = const AsyncValue.loading();
                } else {
                  questionsAsync = ref.watch(aiQuestionSetProvider((
                    myUid: myUid!,
                    myNickname: myNickname,
                    myChart: myChart!,
                    friendUid: selectedFriend.uid,
                    friendNickname: selectedFriend.nickname,
                    friendChart: friendChart!,
                    synastry: synastry,
                    revision: _revision,
                  )));
                }

                // ── 커스텀 질문 답변 provider ─────────────────────
                final customAnswerAsync = _submittedPrompt == null
                    ? null
                    : canUseAi
                        ? ref.watch(aiCustomAnswerProvider((
                            myNickname: myNickname,
                            myChart: myChart!,
                            friendUid: selectedFriend.uid,
                            friendNickname: selectedFriend.nickname,
                            friendChart: friendChart!,
                            synastry: synastry,
                            userPrompt: _submittedPrompt!,
                          )))
                        : ref.watch(customQuestionProvider((
                            friendUid: selectedFriend.uid,
                            friendName: selectedFriend.nickname,
                            friendSign: selectedFriend.sunSign,
                            mySign: ref.watch(mySunSignProvider),
                            userPrompt: _submittedPrompt!,
                          )));

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
                            key: ValueKey(selectedFriend.uid),
                            // value 파라미터 사용 (initialValue는 TextFormField용)
                            value: selectedFriend.uid,
                            dropdownColor: const Color(0xFF0D1B3E),
                            iconEnabledColor: AppColors.inkMuted,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.people_alt_outlined),
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
                              if (value == null) return;
                              setState(() {
                                _selectedFriendUid = value;
                                _submittedPrompt = null;
                                _revision = 0;
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
                          // 친구 출생정보 없음 안내
                          if (aiEnabled &&
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
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 질문 세트 ────────────────────────────────────
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(
                            canUseAi ? '✨ AI 점성술 질문' : '점성술 질문',
                            trailing: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _revision += 1;
                                  _submittedPrompt = null;
                                });
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('새 질문'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          questionsAsync.when(
                            loading: () => const _QuestionLoadingList(),
                            error: (error, _) => Text('질문 생성 실패: $error'),
                            data: (questions) => Column(
                              children: [
                                for (var i = 0; i < questions.length; i++) ...[
                                  _QuestionCard(
                                    item: questions[i],
                                    indexLabel: 'Q${i + 1}',
                                  ),
                                  if (i != questions.length - 1)
                                    const SizedBox(height: AppSpacing.md),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── 직접 질문 입력 ────────────────────────────────
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle('직접 질문하기'),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _customQuestionCtrl,
                            minLines: 2,
                            maxLines: 4,
                            // Android 한글 입력 + 줄바꿈 정상 처리
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText:
                                  '${selectedFriend.nickname}에 대해 궁금한 것을 입력해보세요.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final prompt =
                                    _customQuestionCtrl.text.trim();
                                if (prompt.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('질문을 입력해주세요.'),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _submittedPrompt = prompt);
                              },
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('답변 생성하기'),
                            ),
                          ),
                          if (customAnswerAsync != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            customAnswerAsync.when(
                              loading: () => const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              ),
                              error: (error, _) =>
                                  Text('질문 해석 실패: $error'),
                              data: (item) => _QuestionCard(
                                item: item,
                                indexLabel: 'MY',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Friend _resolveSelectedFriend(List<Friend> friends) {
    final uid = _selectedFriendUid;
    if (uid != null) {
      for (final f in friends) {
        if (f.uid == uid) return f;
      }
    }
    return friends.first;
  }
}

// ── 서브 위젯 ──────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.item, required this.indexLabel});

  final QuestionItem item;
  final String indexLabel;

  @override
  Widget build(BuildContext context) {
    final label = item.isAiGenerated
        ? 'AI 점성술'
        : item.isCustom
            ? '직접 질문'
            : '점성술 질문';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.glassBorder),
      ),
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
                  '$indexLabel · $label',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () async {
                  final text =
                      '✨ 점성술 질문\n\n${item.prompt}\n\n${item.answer}\n\n#Stellara #점성술';
                  try {
                    await Share.share(text, subject: item.prompt);
                  } catch (_) {
                    // Web Share API 미지원 등
                  }
                },
                icon: const Icon(Icons.share_outlined, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.prompt,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppColors.primaryLight,
              ),
              const SizedBox(width: 4),
              const Text(
                '점성술 답변',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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

class _QuestionLoadingList extends StatelessWidget {
  const _QuestionLoadingList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _QuestionLoadingCard(),
        SizedBox(height: AppSpacing.md),
        _QuestionLoadingCard(),
        SizedBox(height: AppSpacing.md),
        _QuestionLoadingCard(),
      ],
    );
  }
}

class _QuestionLoadingCard extends StatelessWidget {
  const _QuestionLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 88, height: 20, radius: 999),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 18),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: double.infinity, height: 18),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: double.infinity, height: 14),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: double.infinity, height: 14),
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
