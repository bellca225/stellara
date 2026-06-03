import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
import '../../users/application/user_providers.dart';
import '../application/compatibility_providers.dart';

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
    final me = ref.watch(currentBirthInfoProvider);
    final friendsAsync = ref.watch(friendListProvider);
    final friends = friendsAsync.valueOrNull ?? const <Friend>[];
    final effectiveSelectedUid =
        _selectedFriendUid ??
        widget.initialFriendUid ??
        (friends.isNotEmpty ? friends.first.uid : null);

    // 선택된 친구 이름 (AppBar 및 결과 헤더에 표시)
    final selectedFriendName = friends
        .where((f) => f.uid == effectiveSelectedUid)
        .map((f) => f.nickname)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedFriendName != null ? '나와 $selectedFriendName의 궁합' : '친구와 궁합',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const ScreenCodeChip(code: 'MATCH-001', label: '친구와의 궁합 결과'),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('내 출생정보'),
                  const SizedBox(height: 8),
                  if (me == null)
                    const Text('내 출생 정보가 아직 없어요. 온보딩 또는 마이페이지에서 먼저 입력해주세요.')
                  else ...[
                    KeyValueRow(label: '이름', value: me.nickname),
                    KeyValueRow(
                      label: '생년월일',
                      value:
                          '${me.dateTime.year}-${_pad(me.dateTime.month)}-${_pad(me.dateTime.day)}',
                    ),
                    KeyValueRow(
                      label: '시간',
                      value:
                          '${_pad(me.dateTime.hour)}:${_pad(me.dateTime.minute)} ${me.utcOffset}',
                    ),
                    KeyValueRow(label: '출생지', value: me.placeName ?? '-'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('궁합 볼 친구 선택'),
                  const SizedBox(height: AppSpacing.md),
                  friendsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text('친구 목록을 불러오지 못했어요: $error'),
                    data: (friends) {
                      if (friends.isEmpty) {
                        return const Text(
                          '아직 친구가 없어요.\n친구를 추가한 뒤 궁합을 볼 수 있어요.',
                        );
                      }
                      final selectedFriend = _findSelectedFriend(
                        friends,
                        effectiveSelectedUid,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final friend in friends)
                                ChoiceChip(
                                  label: Text(friend.nickname),
                                  selected: friend.uid == selectedFriend?.uid,
                                  onSelected: (_) {
                                    setState(
                                      () => _selectedFriendUid = friend.uid,
                                    );
                                  },
                                ),
                            ],
                          ),
                          if (selectedFriend != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _SelectedFriendPanel(friend: selectedFriend),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _MatchResultSection(
              selectedFriendUid: effectiveSelectedUid,
              friendName: selectedFriendName,
            ),
          ],
        ),
      ),
    );
  }

  Friend? _findSelectedFriend(List<Friend> friends, String? uid) {
    if (friends.isEmpty) return null;
    if (uid == null) return friends.first;
    for (final friend in friends) {
      if (friend.uid == uid) return friend;
    }
    return friends.first;
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _SelectedFriendPanel extends ConsumerWidget {
  const _SelectedFriendPanel({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileByIdProvider(friend.uid));

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Text('친구 정보를 불러오지 못했어요: $error'),
      data: (profile) {
        final birth = profile?.birthInfo;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              friend.nickname,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            KeyValueRow(label: '친구 코드', value: friend.friendCode),
            KeyValueRow(label: '태양 별자리', value: friend.sunSign),
            KeyValueRow(label: '출생정보', value: birth == null ? '미입력' : '입력 완료'),
            if (birth != null) ...[
              KeyValueRow(
                label: '생년월일',
                value:
                    '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
              ),
              KeyValueRow(
                label: '시간',
                value:
                    '${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)} ${birth.utcOffset}',
              ),
              KeyValueRow(label: '출생지', value: birth.placeName ?? '-'),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '이 친구는 아직 출생 정보를 완료하지 않았어요. 출생 정보가 있어야 궁합을 계산할 수 있어요.',
                ),
              ),
          ],
        );
      },
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _MatchResultSection extends ConsumerWidget {
  const _MatchResultSection({
    required this.selectedFriendUid,
    this.friendName,
  });

  final String? selectedFriendUid;
  final String? friendName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedFriendUid == null) {
      return const Panel(child: Text('궁합을 볼 친구를 선택해주세요.'));
    }

    final friendProfileAsync = ref.watch(
      userProfileByIdProvider(selectedFriendUid!),
    );

    return friendProfileAsync.when(
      loading: () => const Panel(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Panel(child: Text('친구 정보를 불러오지 못했어요: $error')),
      data: (friendProfile) {
        final friendBirth = friendProfile?.birthInfo;
        if (friendBirth == null) {
          return const Panel(child: Text('친구의 출생 정보가 아직 없어 궁합을 계산할 수 없어요.'));
        }

        final resultAsync = ref.watch(
          matchProvider((
            friendBirth: friendBirth,
            friendUid: selectedFriendUid!,
          )),
        );

        return resultAsync.when(
          loading: () => const Panel(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
          error: (error, _) => Panel(child: Text('궁합 계산 실패: $error')),
          data: (result) => Column(
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (friendName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Text(
                          '나와 $friendName의 궁합',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ),
                    _ScoreBig(score: result.totalScore),
                    const SizedBox(height: AppSpacing.lg),
                    _ScoreBar(label: '감정', value: result.emotionScore),
                    _ScoreBar(label: '대화', value: result.communicationScore),
                    _ScoreBar(label: '연애', value: result.romanceScore),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      '궁합 요약',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      result.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final name = friendName ?? '친구';
                    final text =
                        '✨ Stellara 궁합 결과\n'
                        '나와 $name의 궁합: ${result.totalScore}%\n\n'
                        '${result.summary}\n\n'
                        '#Stellara #점성술 #궁합';
                    try {
                      await Share.share(text, subject: '나와 $name의 궁합 결과');
                    } catch (_) {
                      // Web Share API 미지원 등 플랫폼 예외 → 조용히 처리
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')),
                        );
                      }
                    }
                  },
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

class _ScoreBig extends StatelessWidget {
  const _ScoreBig({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('$score', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(width: 4),
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            '%',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
