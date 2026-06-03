// lib/features/compatibility/presentation/match_screen.dart
//
// 궁합 결과 화면 — Figma 궁합결과 구조 기준
//
// AppBar: ← | 궁합 결과 | [공유]
// 메인 카드: 하트 + 이름 + 총점 + 별자리
// 세부 분석: 감정/대화/연애 카드 (점수 + 바 + 설명)
// 궁합 요약 카드
// SNS 공유 버튼

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
import '../../users/application/user_providers.dart';
import '../application/compatibility_providers.dart';
import '../domain/synastry_result.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, this.initialFriendUid});

  final String? initialFriendUid;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _selectedFriendUid;

  @override
  void initState() {
    super.initState();
    _selectedFriendUid = widget.initialFriendUid;
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final friends = friendsAsync.valueOrNull ?? const <Friend>[];
    final selectedUid = _selectedFriendUid ??
        widget.initialFriendUid ??
        (friends.isNotEmpty ? friends.first.uid : null);

    final selectedFriend = friends.cast<Friend?>().firstWhere(
          (f) => f?.uid == selectedUid,
          orElse: () => null,
        );
    final friendName = selectedFriend?.nickname;

    return Scaffold(
      appBar: AppBar(
        title: const Text('궁합 결과'),
        centerTitle: false,
        actions: [
          if (selectedFriend != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => _share(friendName),
              tooltip: '공유',
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── 친구 선택 (initialFriendUid 없을 때만 표시) ─────────
            if (widget.initialFriendUid == null) ...[
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '궁합 볼 친구 선택',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    friendsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('친구 목록을 불러오지 못했어요: $e'),
                      data: (list) => list.isEmpty
                          ? const Text('아직 친구가 없어요.\n친구를 추가한 뒤 궁합을 볼 수 있어요.')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final f in list)
                                  ChoiceChip(
                                    label: Text(f.nickname),
                                    selected: f.uid == selectedUid,
                                    onSelected: (_) => setState(
                                        () => _selectedFriendUid = f.uid),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── 결과 영역 ────────────────────────────────────────────
            if (selectedUid == null)
              const Panel(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('궁합을 볼 친구를 선택해주세요.'),
                  ),
                ),
              )
            else
              _MatchResultBody(
                friendUid: selectedUid,
                friendName: friendName,
                onShare: () => _share(friendName),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(String? name) async {
    // 결과를 가져와 공유 (provider read)
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final myName = profile?.effectiveDisplayName ?? '나';
    final text = '✨ Stellara 궁합 결과\n'
        '$myName와 ${name ?? '친구'}의 궁합을 확인해보세요!\n\n'
        '#Stellara #점성술 #궁합';
    try {
      await Share.share(text, subject: '궁합 결과 공유');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')),
        );
      }
    }
  }
}

// ── 결과 본문 (친구 선택 완료 후) ──────────────────────────────────

class _MatchResultBody extends ConsumerWidget {
  const _MatchResultBody({
    required this.friendUid,
    required this.onShare,
    this.friendName,
  });

  final String friendUid;
  final String? friendName;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendProfileAsync = ref.watch(userProfileByIdProvider(friendUid));

    return friendProfileAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) =>
          Panel(child: Text('친구 정보를 불러오지 못했어요: $e')),
      data: (friendProfile) {
        final friendBirth = friendProfile?.birthInfo;
        if (friendBirth == null) {
          return const Panel(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('친구의 출생 정보가 아직 없어 궁합을 계산할 수 없어요.'),
            ),
          );
        }

        final resultAsync = ref.watch(
          matchProvider((
            friendBirth: friendBirth,
            friendUid: friendUid,
          )),
        );

        return resultAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) =>
              Panel(child: Text('궁합 계산 실패: $e')),
          data: (result) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 메인 결과 카드 ───────────────────────────────────
              _MainResultCard(
                result: result,
                friendName: friendName,
                friendZodiac: friendProfile?.sunSign ?? '-',
              ),
              const SizedBox(height: 20),

              // ── 세부 분석 ────────────────────────────────────────
              const Text(
                '세부 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _DetailCard(
                label: '감정',
                score: result.emotionScore,
                description: result.emotionalMatch,
              ),
              const SizedBox(height: 10),
              _DetailCard(
                label: '대화',
                score: result.communicationScore,
                description: result.communicationStyle,
              ),
              const SizedBox(height: 10),
              _DetailCard(
                label: '연애',
                score: result.romanceScore,
                description: result.romanticMatch,
              ),
              const SizedBox(height: 16),

              // ── 궁합 요약 카드 ──────────────────────────────────
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '궁합 요약',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                            height: 1.6,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── SNS 공유 버튼 ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('SNS에 공유하기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── 메인 점수 카드 ─────────────────────────────────────────────────

class _MainResultCard extends StatelessWidget {
  const _MainResultCard({
    required this.result,
    required this.friendZodiac,
    this.friendName,
  });

  final SynastryResult result;
  final String? friendName;
  final String friendZodiac;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          const Icon(Icons.favorite_outline_rounded,
              size: 32, color: AppColors.primaryLight),
          const SizedBox(height: 8),
          Text(
            '나와 ${friendName ?? '친구'}의 궁합',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.totalScore}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          if (friendZodiac.isNotEmpty && friendZodiac != '-') ...[
            const SizedBox(height: 6),
            Text(
              friendZodiac,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 세부 분석 카드 ─────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.score,
    required this.description,
  });

  final String label;
  final int score;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.line,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
