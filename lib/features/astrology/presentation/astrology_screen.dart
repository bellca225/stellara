import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../application/astrology_providers.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';
import 'natal_chart_painter.dart';

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
      physics: const ClampingScrollPhysics(),
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
        _BirthChartHeader(birth: birth),
        const SizedBox(height: AppSpacing.lg),
        _ChartPanel(chart: chart),
        const SizedBox(height: AppSpacing.lg),
        _Big3Panel(chart: chart),
        const SizedBox(height: AppSpacing.lg),
        _PlanetTable(chart: chart),
        const SizedBox(height: AppSpacing.lg),
        _AspectTable(chart: chart),
        const SizedBox(height: AppSpacing.xl),
        Text(
          '상세 해석',
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

class _BirthChartHeader extends StatelessWidget {
  const _BirthChartHeader({required this.birth});

  final BirthInfo birth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 178,
        height: 178,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.paper,
          border: Border.all(color: AppColors.inkSubtle, width: 1.6),
        ),
        child: Center(
          child: Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line, width: 1.4),
            ),
            alignment: Alignment.center,
            child: Text(
              '출생 차트\n${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
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
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.chart});

  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '출생 차트 보기',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: NatalChartPainter(chart),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Big3Panel extends StatelessWidget {
  const _Big3Panel({required this.chart});

  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '나의 Big 3',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Big3Chip(label: '태양', value: zodiacNameKo(chart.sunSign)),
              _Big3Chip(label: '달', value: zodiacNameKo(chart.moonSign)),
              _Big3Chip(label: '상승', value: zodiacNameKo(chart.ascendantSign)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Big3Chip extends StatelessWidget {
  const _Big3Chip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.inkMuted,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlanetTable extends StatelessWidget {
  const _PlanetTable({required this.chart});

  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '행성 정보',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (chart.planets.isEmpty)
            const Text('표시할 행성 정보가 아직 없어요.')
          else
            ...chart.planets.map(
              (planet) => KeyValueRow(
                label: planetNameKo(planet.name),
                value:
                    '${zodiacNameKo(planet.sign)} · ${planet.degreeInSign.toStringAsFixed(1)}°'
                    '${planet.house != null ? ' · ${planet.house}하우스' : ''}',
              ),
            ),
        ],
      ),
    );
  }
}

class _AspectTable extends StatelessWidget {
  const _AspectTable({required this.chart});

  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주요 각도',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (chart.aspects.isEmpty)
            const Text('표시할 각도 정보가 아직 없어요.')
          else
            ...chart.aspects.take(6).map(
              (aspect) => KeyValueRow(
                label:
                    '${planetNameKo(aspect.planetA)} · ${planetNameKo(aspect.planetB)}',
                value: '${aspectNameKo(aspect.aspect)} · 오차 ${aspect.orb.toStringAsFixed(1)}°',
              ),
            ),
        ],
      ),
    );
  }
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

List<Planet> _orderedCorePlanets(List<Planet> planets) {
  const order = ['Sun', 'Moon', 'Mercury', 'Venus'];
  final byName = {for (final planet in planets) planet.name: planet};
  return [
    for (final name in order)
      if (byName[name] != null) byName[name]!,
  ];
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(width: 170, height: 18),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.skeleton,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 340, radius: 16),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 110, radius: 16),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 180, radius: 16),
        const SizedBox(height: AppSpacing.lg),
        const SkeletonBox(height: 170, radius: 16),
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
