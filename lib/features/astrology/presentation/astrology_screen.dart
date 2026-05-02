import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../application/astrology_providers.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';

class AstrologyScreen extends ConsumerWidget {
  const AstrologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);

    return Scaffold(
      body: SafeArea(
        child: asyncChart.when(
          loading: () => const _ChartSkeleton(),
          error: (error, _) => _ErrorView(message: '$error'),
          data: (chart) => _ChartContent(birth: birth, chart: chart),
        ),
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({
    required this.birth,
    required this.chart,
  });

  final BirthInfo birth;
  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    final detailPlanets = _orderedCorePlanets(chart.planets);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        const WireframeHeader('01 · 점성술 분석'),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 4),
            Text(
              '점성술 분석',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _BirthChartBadge(dateTime: birth.dateTime),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '상세 분석',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final planet in detailPlanets) ...[
          _InsightCard(
            title: '${planetNameKo(planet.name)} · ${zodiacNameKo(planet.sign)}',
            description: planetReadingKo(
              planet: planet.name,
              sign: planet.sign,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detailPlanets.isEmpty)
          const _InsightCard(
            title: '해석 준비 중',
            description: '차트 정보가 준비되면 행성별 해석이 이곳에 표시됩니다.',
          ),
      ],
    );
  }
}

List<Planet> _orderedCorePlanets(List<Planet> planets) {
  const order = ['Sun', 'Moon', 'Mercury', 'Venus'];
  final byName = {for (final planet in planets) planet.name: planet};
  return [
    for (final name in order)
      if (byName[name] != null) byName[name]!,
  ];
}

class _BirthChartBadge extends StatelessWidget {
  const _BirthChartBadge({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth * 0.46, 180.0);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.paper,
              border: Border.all(color: AppColors.inkSubtle, width: 1.6),
            ),
            child: Center(
              child: Container(
                width: size * 0.7,
                height: size * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.4),
                ),
                alignment: Alignment.center,
                child: Text(
                  '출생 차트\n${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.inkMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(width: 170, height: 18),
        SizedBox(height: AppSpacing.xl),
        SkeletonBox(width: 120, height: 22),
        SizedBox(height: AppSpacing.xl),
        Center(
          child: SizedBox(
            width: 180,
            height: 180,
            child: SkeletonBox(radius: 180),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 120, radius: 16),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          '점성술 분석 화면을 불러오지 못했어요.\n$message',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
