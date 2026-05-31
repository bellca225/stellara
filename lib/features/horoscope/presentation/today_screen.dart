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

    return StarBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          children: [
            const ScreenCodeChip(code: 'TODAY-001', label: '오늘의 운세'),
            const SizedBox(height: AppSpacing.xl),
            Text('오늘의 운세', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final sign in _signs)
                  GestureDetector(
                    onTap: () =>
                        ref.read(selectedSignSlugProvider.notifier).state =
                            sign,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected == sign
                            ? AppColors.primary
                            : AppColors.glass,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected == sign
                              ? AppColors.primary
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        zodiacNameKo(sign),
                        style: TextStyle(
                          color: selected == sign
                              ? Colors.white
                              : AppColors.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                  '오늘의 운세를 불러오지 못했습니다.\n$error',
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
                          ? '오늘은 새로운 기회를 기다리며 주변을 돌아보는 하루가 될 것입니다.'
                          : horoscope.summary,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoChip(
                            label: '오늘의 기운',
                            value: moodKo(horoscope.mood),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _InfoChip(
                            label: '행운 색상',
                            value: colorKo(horoscope.luckyColor),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _InfoChip(
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});
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
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
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
