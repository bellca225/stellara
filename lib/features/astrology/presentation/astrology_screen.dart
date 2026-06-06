import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../users/application/user_providers.dart';
import '../application/astrology_providers.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';
import 'natal_chart_painter.dart';

const _astrologyGlassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
  BoxShadow(color: Color(0x26FFFFFF), blurRadius: 1, offset: Offset(0, 1)),
];

class AstrologyScreen extends ConsumerWidget {
  const AstrologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final asyncChart = ref.watch(myNatalChartProvider);

    // 출생 정보가 없는 사용자 가드
    // profileCompleted=false 이거나 birthInfo=null이면 차트 화면 대신 안내 표시.
    // profile 이 아직 로딩 중이면(null) 스켈레톤을 보여주며 기다린다.
    final profile = profileAsync.valueOrNull;
    if (profileAsync.hasValue &&
        profile != null &&
        (!profile.profileCompleted || profile.birthInfo == null)) {
      return StarBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: _ScreenShell(
              header: const _ScreenHeader(),
              child: const _NoBirthInfoView(),
            ),
          ),
        ),
      );
    }

    // birth 변경 후 차트가 아직 갱신되지 않았는지 확인.
    // activeChartVersion != birth.chartVersion → 재분석 진행 중 또는 필요.
    final isStale =
        birth != null &&
        profile != null &&
        profile.activeChartVersion != null &&
        profile.activeChartVersion != birth.chartVersion;

    return StarBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: _ScreenShell(
            header: const _ScreenHeader(),
            banner: isStale ? const _StaleBanner() : null,
            child: asyncChart.when(
              loading: () => const _ChartSkeleton(),
              error: (error, _) => _ErrorView(message: '$error'),
              data: (chart) {
                if (birth == null) return const _ChartSkeleton();
                return _ChartContent(birth: birth, chart: chart);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenShell extends StatelessWidget {
  const _ScreenShell({required this.header, required this.child, this.banner});

  final Widget header;
  final Widget child;
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        if (banner != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: banner!,
          ),
        ],
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.636,
                  ),
                  boxShadow: _astrologyGlassBoxShadow,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF8EC5FF),
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            '점성술 분석',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.refresh_rounded, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '출생 정보가 변경됐어요. 차트를 다시 분석 중이에요.',
              style: TextStyle(color: Colors.orange.shade100, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({required this.birth, required this.chart});

  final BirthInfo birth;
  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    final detailPlanets = _orderedCorePlanets(chart.planets);

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        const SizedBox(height: 16),
        _ChartPanel(chart: chart),
        const SizedBox(height: 28),
        Text(
          '상세 분석',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 16),
        for (final planet in detailPlanets) ...[
          _InsightCard(
            title:
                '${planetNameKo(planet.name)} in ${zodiacNameKo(planet.sign)}',
            subtitle: planetSubtitleKo(planet.name),
            description: planetReadingKo(
              planet: planet.name,
              sign: planet.sign,
            ),
          ),
          const SizedBox(height: 16),
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

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.chart});

  final NatalChart chart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.636,
        ),
        boxShadow: _astrologyGlassBoxShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('출생 차트', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: NatalChartPainter(chart)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.636,
        ),
        boxShadow: _astrologyGlassBoxShadow,
      ),
      child: child,
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.description,
    this.subtitle,
  });

  final String title;

  /// 예: '핵심 성향', '감정과 내면' — planetSubtitleKo() 결과.
  final String? subtitle;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _GlassSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              color: AppColors.primaryLight,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.inkSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.inkMuted,
              height: 1.55,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: [
        _GlassSection(
          child: Column(
            children: [
              Container(
                width: 178,
                height: 178,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(height: 340, radius: 28),
        const SizedBox(height: 28),
        const SkeletonBox(width: 120, height: 16),
        const SizedBox(height: 16),
        const SkeletonBox(height: 120, radius: 28),
        const SizedBox(height: 16),
        const SkeletonBox(height: 120, radius: 28),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          _GlassSection(
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.inkMuted,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  '점성술 분석 화면을 불러오지 못했어요.\n$message',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 출생 정보 미입력 사용자에게 보여주는 가드 화면.
class _NoBirthInfoView extends StatelessWidget {
  const _NoBirthInfoView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          const Spacer(),
          _GlassSection(
            child: Column(
              children: [
                const Icon(
                  Icons.star_outline_rounded,
                  size: 56,
                  color: AppColors.inkSubtle,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  '출생 정보가 필요해요',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '점성술 분석을 보려면\n마이페이지에서 생년월일·출생시간·출생지를\n먼저 입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted, height: 1.5),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
