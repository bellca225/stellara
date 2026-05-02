import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../application/horoscope_providers.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  static const _signs = [
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedSignSlugProvider);
    final asyncH = ref.watch(todayHoroscopeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const WireframeHeader('TODAY-001 · 오늘의 운세'),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '오늘의 운세',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final sign in _signs)
                  ChoiceChip(
                    selected: selected == sign,
                    label: Text(zodiacNameKo(sign)),
                    labelStyle: TextStyle(
                      color: selected == sign ? AppColors.paper : AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    selectedColor: AppColors.ink,
                    backgroundColor: AppColors.paper,
                    side: const BorderSide(color: AppColors.line),
                    showCheckmark: false,
                    onSelected: (_) =>
                        ref.read(selectedSignSlugProvider.notifier).state = sign,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            asyncH.when(
              loading: () => const Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 96, height: 18),
                    SizedBox(height: AppSpacing.md),
                    SkeletonBox(width: double.infinity, height: 18),
                    SizedBox(height: AppSpacing.sm),
                    SkeletonBox(width: 230, height: 18),
                    SizedBox(height: AppSpacing.lg),
                    SkeletonBox(height: 84, radius: 16),
                  ],
                ),
              ),
              error: (error, _) => Panel(
                child: Text(
                  '오늘의 운세를 불러오지 못했어요.\n$error',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              data: (horoscope) => Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            zodiacLabelKo(horoscope.signName),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          DateFormat('yyyy.MM.dd').format(horoscope.date),
                          style: const TextStyle(
                            color: AppColors.inkMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      horoscope.summary.isEmpty
                          ? '오늘은 잠시 숨을 고르고 주변의 리듬을 살피는 하루예요.'
                          : horoscope.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _Info(
                            label: '오늘의 기분',
                            value: moodKo(horoscope.mood),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _Info(
                            label: '행운 색상',
                            value: colorKo(horoscope.luckyColor),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _Info(
                            label: '행운 숫자',
                            value: horoscope.luckyNumber.toString(),
                          ),
                        ),
                      ],
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
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
