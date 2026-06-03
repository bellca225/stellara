import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/env/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../users/application/user_providers.dart';
import '../application/astrology_providers.dart';
import '../domain/birth_info.dart';
import '../domain/natal_chart.dart';
import 'natal_chart_painter.dart';

const _svgBack = '''
<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">
<path d="M9.99975 15.8329L4.16656 9.99969L9.99975 4.1665" stroke="#8EC5FF" stroke-width="1.66663" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M15.8329 9.99976H4.16656" stroke="#8EC5FF" stroke-width="1.66663" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgStar = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M15.3636 3.05935C15.422 2.94133 15.5122 2.84198 15.6241 2.77251C15.736 2.70305 15.8651 2.66624 15.9968 2.66624C16.1285 2.66624 16.2575 2.70305 16.3694 2.77251C16.4813 2.84198 16.5715 2.94133 16.63 3.05935L19.7093 9.29671C19.9122 9.70725 20.2116 10.0624 20.582 10.3318C20.9523 10.6011 21.3825 10.7766 21.8355 10.8431L28.7221 11.8508C28.8526 11.8698 28.9752 11.9248 29.076 12.0097C29.1768 12.0947 29.2519 12.2062 29.2927 12.3316C29.3334 12.4569 29.3383 12.5912 29.3068 12.7192C29.2752 12.8473 29.2084 12.9639 29.114 13.0559L24.1337 17.9056C23.8053 18.2256 23.5595 18.6207 23.4177 19.0568C23.2758 19.4929 23.242 19.957 23.3192 20.4091L24.495 27.261C24.518 27.3914 24.5039 27.5256 24.4543 27.6485C24.4047 27.7713 24.3216 27.8776 24.2144 27.9555C24.1073 28.0333 23.9804 28.0794 23.8483 28.0886C23.7161 28.0978 23.5841 28.0697 23.4672 28.0075L17.3112 24.7708C16.9055 24.5578 16.4542 24.4465 15.9961 24.4465C15.5379 24.4465 15.0867 24.5578 14.681 24.7708L8.52632 28.0075C8.40946 28.0693 8.27757 28.0972 8.14567 28.0878C8.01377 28.0784 7.88715 28.0322 7.78021 27.9544C7.67326 27.8767 7.5903 27.7704 7.54074 27.6478C7.49118 27.5252 7.47702 27.3912 7.49987 27.261L8.67429 20.4104C8.75187 19.9581 8.71826 19.4938 8.57636 19.0574C8.43447 18.621 8.18854 18.2257 7.8598 17.9056L2.87951 13.0573C2.78432 12.9653 2.71686 12.8485 2.68483 12.7201C2.6528 12.5917 2.65747 12.4569 2.69832 12.331C2.73916 12.2051 2.81454 12.0933 2.91587 12.0081C3.01719 11.923 3.14039 11.868 3.27142 11.8495L10.1566 10.8431C10.6102 10.7771 11.041 10.6019 11.4118 10.3325C11.7827 10.0631 12.0825 9.70766 12.2855 9.29671L15.3636 3.05935Z" stroke="#51A2FF" stroke-width="2.66611" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _glassBoxShadow = [
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
      return _buildShell(
        context,
        child: _NoBirthInfoView(onBack: () => Navigator.of(context).pop()),
      );
    }

    return _buildShell(
      context,
      child: asyncChart.when(
        loading: () => const _ChartSkeleton(),
        error: (error, _) => _ErrorView(message: '$error'),
        data: (chart) {
          if (birth == null) return const _ChartSkeleton();
          return _ChartContent(birth: birth, chart: chart);
        },
      ),
    );
  }

  Widget _buildShell(BuildContext context, {required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1F), Color(0xFF0F1729), Color(0xFF1E3A8A)],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(40, (i) {
            final x = (i * 137.5) % 100;
            final y = (i * 97.3) % 100;
            final size = (i % 3 + 1) * 0.6;
            final opacity = (i % 5 + 3) / 10;
            return Positioned(
              left:
                  x /
                  100 *
                  (WidgetsBinding.instance.window.physicalSize.width /
                      WidgetsBinding.instance.window.devicePixelRatio),
              top:
                  y /
                  100 *
                  (WidgetsBinding.instance.window.physicalSize.height /
                      WidgetsBinding.instance.window.devicePixelRatio),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(child: child),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        // 헤더
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.636,
                  ),
                ),
                child: Center(
                  child: SvgPicture.string(_svgBack, width: 20, height: 20),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              '점성술 분석',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 32 / 24,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // 출생 차트 카드
        Container(
          height: 345,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.636,
            ),
            boxShadow: _glassBoxShadow,
          ),
          child: Center(child: _BirthChartCircle(birth: birth)),
        ),

        const SizedBox(height: 24),

        // 상세 분석 제목
        const Text(
          '상세 분석',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
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
            title: '데이터 없음',
            description: '출생 정보가 입력되면 분석 내용을 표시합니다.',
          ),
      ],
    );
  }
}

class _BirthChartCircle extends StatelessWidget {
  const _BirthChartCircle({required this.birth});
  final BirthInfo birth;

  bool get _isDemo => Env.shouldUseFixtureForProkerala;
  static String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 가장 바깥 원
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x1451A2FF), width: 1.0),
            ),
          ),
          // 중간 원
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x2051A2FF), width: 1.0),
            ),
          ),
          // 안쪽 원
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x1A51A2FF), width: 1.0),
            ),
          ),
          // 중앙 내용
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.string(_svgStar, width: 32, height: 32),
              const SizedBox(height: 8),
              const Text(
                '출생 차트',
                style: TextStyle(
                  color: Color(0xFF8EC5FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              if (_isDemo) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '데모',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String description;

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 0.636),
        boxShadow: _glassBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
              letterSpacing: -0.2,
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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Container(
          height: 36,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 345,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
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
        padding: const EdgeInsets.all(24),
        child: Text(
          '점성술 분석을 불러올 수 없습니다.\n$message',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF8EC5FF)),
        ),
      ),
    );
  }
}

class _NoBirthInfoView extends StatelessWidget {
  const _NoBirthInfoView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 0.636,
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.string(_svgBack, width: 20, height: 20),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                '점성술 분석',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          SvgPicture.string(_svgStar, width: 56, height: 56),
          const SizedBox(height: 24),
          const Text(
            '출생 정보가 필요해요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '점성술 분석을 보려면\n이름•생년월일•출생시간•출생지를\n입력해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
