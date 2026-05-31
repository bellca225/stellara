import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);

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
            const ScreenCodeChip(
              code: 'MYPAGE-001',
              label: '마이페이지',
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paper,
                  border: Border.all(color: AppColors.inkSubtle, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter(birth.nickname, fallback: '물'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                birth.nickname,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: asyncChart.when(
                data: (chart) => Text(
                  zodiacLabelKo(chart.sunSign),
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                loading: () => const Text(
                  '차트 정보를 불러오는 중',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                error: (error, _) => const Text(
                  '별자리 정보를 준비 중이에요',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 친구 코드',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AQU2024',
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontSize: 22,
                                  ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.copy_all_outlined,
                          color: AppColors.inkSubtle,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '친구에게 이 코드를 공유해 연결할 수 있어요.',
                    style: TextStyle(
                      color: AppColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '출생 정보',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  KeyValueRow(
                    label: '생년월일',
                    value:
                        '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
                  ),
                  KeyValueRow(
                    label: '출생 시간',
                    value:
                        '${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)}',
                  ),
                  KeyValueRow(
                    label: '출생지',
                    value: birth.placeName ?? '-',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                    onPressed: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => OnboardingScreen(
                            initialBirthInfo: birth,
                            isEditing: true,
                          ),
                        ),
                      );
                      if (changed == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('출생 정보가 변경되었어요.'),
                          ),
                        );
                      }
                    },
                    child: const Text('출생 정보 수정'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () {},
              child: const Text('→ 로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}
