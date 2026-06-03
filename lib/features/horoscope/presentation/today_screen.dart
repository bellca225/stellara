// lib/features/horoscope/presentation/today_screen.dart
//
// 오늘의 운세 화면 — 스크린샷 UI 구조 기준
//
// 구조:
//   제목 "오늘의 운세" + 날짜(시계 아이콘) + 공유 버튼(우측 상단)
//   전체 운세 카드 (☆ 아이콘 + summary)
//   오늘의 감정 상태 카드 (mood)
//   행운 요소 섹션 타이틀
//   숫자 카드 (luckyNumber × 1,2,3)
//   색상 카드 (luckyColor)
//   장소 카드 (luckyPlace, 있을 때만)
//   SNS에 공유하기 버튼

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../application/horoscope_providers.dart';
import '../domain/horoscope.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncH = ref.watch(todayHoroscopeProvider);

    return StarBackground(
      child: SafeArea(
        child: asyncH.when(
          loading: () => const _LoadingSkeleton(),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is StateError
                      ? error.message
                      : '오늘의 운세를 불러오지 못했어요.',
                  style: const TextStyle(color: AppColors.inkMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(todayHoroscopeProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
          data: (h) => _HoroscopeBody(horoscope: h),
        ),
      ),
    );
  }
}

// ── 본문 ──────────────────────────────────────────────────────────

class _HoroscopeBody extends StatelessWidget {
  const _HoroscopeBody({required this.horoscope});

  final Horoscope horoscope;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(horoscope.date);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── 제목 + 날짜 + 공유 버튼 ────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 운세',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.inkMuted),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 공유 버튼 (우측 상단 원형)
            _CircleIconButton(
              icon: Icons.share_outlined,
              onTap: () => _share(context, horoscope),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── 전체 운세 카드 ─────────────────────────────────────────
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_outline_rounded,
                      size: 16, color: AppColors.primaryLight),
                  const SizedBox(width: 6),
                  const Text(
                    '전체 운세',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                horoscope.summary,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── 오늘의 감정 상태 카드 ────────────────────────────────────
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '오늘의 감정 상태',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                horoscope.mood,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── 행운 요소 섹션 타이틀 ────────────────────────────────────
        const Text(
          '행운 요소',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 12),

        // ── 숫자 카드 ────────────────────────────────────────────────
        _LuckyCard(
          label: '숫자',
          value: _luckyNumbers(horoscope.luckyNumbers),
        ),

        const SizedBox(height: 10),

        // ── 색상 카드 ────────────────────────────────────────────────
        _LuckyCard(
          label: '색상',
          value: horoscope.luckyColor,
        ),

        // ── 장소 카드 (데이터 있을 때만) ─────────────────────────────
        if (horoscope.luckyPlace != null &&
            horoscope.luckyPlace!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _LuckyCard(
            label: '장소',
            value: horoscope.luckyPlace!,
          ),
        ],

        const SizedBox(height: 28),

        // ── SNS 공유 버튼 ────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _share(context, horoscope),
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('SNS에 공유하기'),
          ),
        ),
      ],
    );
  }

  String _luckyNumbers(List<int> numbers) {
    if (numbers.isEmpty) return '-';
    return numbers.join(', ');
  }

  Future<void> _share(BuildContext ctx, Horoscope h) async {
    final date = DateFormat('yyyy년 M월 d일').format(h.date);
    final text = h.shareText.trim().isNotEmpty
        ? '${h.shareText}\n\n'
            '✨ 오늘의 운세 ($date)\n'
            '🎨 행운 색상: ${h.luckyColor}\n'
            '🔢 행운 숫자: ${_luckyNumbers(h.luckyNumbers)}\n'
            '#Stellara #오늘의운세'
        : '✨ 오늘의 운세 ($date)\n\n'
            '${h.summary}\n\n'
            '🎨 행운 색상: ${h.luckyColor}\n'
            '🔢 행운 숫자: ${_luckyNumbers(h.luckyNumbers)}\n'
            '#Stellara #오늘의운세';
    try {
      await Share.share(text);
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')),
        );
      }
    }
  }
}

// ── 서브 위젯 ─────────────────────────────────────────────────────

class _LuckyCard extends StatelessWidget {
  const _LuckyCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

// ── 로딩 스켈레톤 ─────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: const [
        SkeletonBox(width: 160, height: 32),
        SizedBox(height: 8),
        SkeletonBox(width: 120, height: 16),
        SizedBox(height: 28),
        SkeletonBox(height: 100, radius: 16),
        SizedBox(height: 12),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 24),
        SkeletonBox(width: 80, height: 20),
        SizedBox(height: 12),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 10),
        SkeletonBox(height: 72, radius: 16),
        SizedBox(height: 10),
        SkeletonBox(height: 72, radius: 16),
      ],
    );
  }
}
