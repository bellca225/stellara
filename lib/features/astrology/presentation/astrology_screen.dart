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
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(999),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
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
        _ChartPanel(birth: birth, chart: chart),
        const SizedBox(height: 28),
        const Text(
          '상세 분석',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
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
  const _ChartPanel({required this.birth, required this.chart});

  final BirthInfo birth;
  final NatalChart chart;

  bool get _isDemo => Env.shouldUseFixtureForProkerala;
  static String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.636),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        painter: NatalChartPainter(chart),
                        child: const SizedBox.expand(),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x10FFFFFF), Color(0x08FFFFFF)],
                          ),
                          border: Border.all(
                            color: const Color(0x3351A2FF),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x401E3A8A), blurRadius: 12),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star_outline_rounded,
                              color: AppColors.primaryLight,
                              size: 22,
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '출생 차트',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
                              style: const TextStyle(
                                color: Color(0xFFBEDBFF),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_isDemo) ...[
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '데모',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.636),
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
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Color(0x998EC5FF),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xF0FFFFFF),
              fontSize: 15,
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
                  color: Color(0xFF8EC5FF),
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  '점성술 분석 화면을 불러오지 못했어요.\n$message',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                  color: Color(0xFF8EC5FF),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  '출생 정보가 필요해요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  '점성술 분석을 보려면\n마이페이지에서 생년월일·출생시간·출생지를\n먼저 입력해주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xCCFFFFFF), height: 1.5),
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
