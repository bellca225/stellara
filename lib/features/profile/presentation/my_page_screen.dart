import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/landing_screen.dart';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);
    // birth 가 null 이면(profile 로딩 중 / birthInfo 미입력) demo 값으로 표시.
    final birthDisplay = birth ?? BirthInfo.demo();
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
                  firstLetter(birthDisplay.nickname, fallback: '별'),
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
                birthDisplay.nickname,
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
                        tooltip: '복사',
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
                      IconButton(
                        tooltip: '공유',
                        onPressed: () async {
                          try {
                            await Share.share(
                              'Stellara에서 함께 별자리 궁합 봐요! 🌟\n'
                              '친구 코드: $friendCode\n\n'
                              '#Stellara #점성술',
                              subject: 'Stellara 친구 초대',
                            );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.share_outlined,
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
                    value: birth == null
                        ? '-'
                        : '${birthDisplay.dateTime.year}-${_pad(birthDisplay.dateTime.month)}-${_pad(birthDisplay.dateTime.day)}',
                  ),
                  _InfoRow(
                    label: '출생 시간',
                    value: birth == null
                        ? '-'
                        : '${_pad(birthDisplay.dateTime.hour)}:${_pad(birthDisplay.dateTime.minute)}',
                  ),
                  _InfoRow(label: '출생지', value: birth?.placeName ?? '-'),
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
                onPressed: () async {
                  // Firebase Auth 세션 종료 + Riverpod 상태 초기화
                  await FirebaseAuth.instance.signOut();
                  ref.read(currentUserProvider.notifier).state = null;
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LandingScreen()),
                      (_) => false, // 스택 전체 제거
                    );
                  }
                },
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