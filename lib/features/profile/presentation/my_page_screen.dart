import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../auth/application/auth_providers.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);
    final user = ref.watch(currentUserProvider);
    final friendCode = user?.friendCode ?? 'AQU2024';

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
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.glass,
                  border: Border.all(color: AppColors.primaryLight, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter(birth.nickname, fallback: '별'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
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
                    color: AppColors.primaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                loading: () => const Text(
                  '로딩 중...',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                error: (_, __) => const Text(
                  '정보를 불러오지 못했습니다',
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
                          friendCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: friendCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('친구 코드가 복사되었습니다')),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_all_outlined,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    '친구에게 이 코드를 공유하고 함께 별자리를 탐색해보세요',
                    style: TextStyle(color: AppColors.inkMuted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('출생 정보', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    label: '생년월일',
                    value:
                        '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
                  ),
                  _InfoRow(
                    label: '출생 시간',
                    value:
                        '${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)}',
                  ),
                  _InfoRow(label: '출생지', value: birth.placeName ?? '-'),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
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
                            const SnackBar(content: Text('출생 정보가 수정되었습니다')),
                          );
                        }
                      },
                      child: const Text('출생 정보 설정'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}