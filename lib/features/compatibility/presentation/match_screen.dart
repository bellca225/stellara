// lib/features/compatibility/presentation/match_screen.dart
//
// MATCH-001 — 친구와의 궁합 결과.
//
// 9주차 단계: "친구"는 아직 Firestore 가 없으므로,
// 화면에서 친구 출생정보를 직접 입력 → SynastryProvider 호출 형식.
// 11주차 친구 기능 붙으면 Friend 객체에서 자동으로 BirthInfo 가져오도록 교체.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../application/compatibility_providers.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  final _nicknameC = TextEditingController(text: '바다고래');
  final _dateC = TextEditingController(text: '1996-08-21');
  final _timeC = TextEditingController(text: '09:15');
  final _placeC = TextEditingController(text: '부산광역시');

  BirthInfo? _partner;

  @override
  void dispose() {
    _nicknameC.dispose();
    _dateC.dispose();
    _timeC.dispose();
    _placeC.dispose();
    super.dispose();
  }

  void _runMatch() {
    // 9주차에서는 입력값을 그대로 BirthInfo 로 만든다.
    // (실제 lat/lng 변환은 10주차 geocoding 에서. 일단 부산 좌표로 폴백.)
    DateTime dt;
    try {
      final dateParts = _dateC.text.split('-').map(int.parse).toList();
      final timeParts = _timeC.text.split(':').map(int.parse).toList();
      dt = DateTime(dateParts[0], dateParts[1], dateParts[2],
          timeParts[0], timeParts[1]);
    } catch (_) {
      dt = DateTime(1996, 8, 21, 9, 15);
    }
    setState(() {
      _partner = BirthInfo(
        nickname: _nicknameC.text.trim(),
        dateTime: dt,
        latitude: 35.1796,
        longitude: 129.0756,
        utcOffset: '+09:00',
        placeName: _placeC.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentBirthInfoProvider);
    final partner = _partner;
    final result = partner == null
        ? null
        : ref.watch(synastryProvider((me: me, partner: partner)));

    return Scaffold(
      appBar: AppBar(title: const Text('친구와 궁합')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const ScreenCodeChip(code: 'MATCH-001', label: '친구와의 궁합 결과'),
            const SizedBox(height: AppSpacing.lg),

            // ── 내 정보 요약 ─────────────────────────
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('내 출생정보'),
                  const SizedBox(height: 8),
                  KeyValueRow(label: '닉네임', value: me.nickname),
                  KeyValueRow(
                      label: '생년월일',
                      value:
                          '${me.dateTime.year}-${_pad(me.dateTime.month)}-${_pad(me.dateTime.day)}'),
                  KeyValueRow(
                      label: '시간',
                      value:
                          '${_pad(me.dateTime.hour)}:${_pad(me.dateTime.minute)} ${me.utcOffset}'),
                  KeyValueRow(label: '출생지', value: me.placeName ?? '-'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 친구 정보 입력 폼 ────────────────────
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('친구 출생정보'),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _nicknameC,
                    decoration: const InputDecoration(labelText: '닉네임'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dateC,
                    decoration:
                        const InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _timeC,
                    decoration: const InputDecoration(labelText: '시간 (HH:MM)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _placeC,
                    decoration: const InputDecoration(labelText: '출생지'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: _runMatch,
                    child: const Text('궁합 보기'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── 결과 ─────────────────────────────────
            if (result != null)
              result.when(
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
                )),
                error: (e, _) => Panel(child: Text('궁합 계산 실패: $e')),
                data: (r) => Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('궁합 결과'),
                      const SizedBox(height: AppSpacing.md),
                      _ScoreBig(score: r.totalScore),
                      const SizedBox(height: AppSpacing.lg),
                      _ScoreBar(label: '감정', value: r.emotionScore),
                      _ScoreBar(label: '대화', value: r.communicationScore),
                      _ScoreBar(label: '연애', value: r.romanceScore),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        r.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _pad(int v) => v.toString().padLeft(2, '0');
}

class _ScoreBig extends StatelessWidget {
  const _ScoreBig({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$score',
          style: Theme.of(context).textTheme.displaySmall,
        ),
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
              Text('$value%',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100.0,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
