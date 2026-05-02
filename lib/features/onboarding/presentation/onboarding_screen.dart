// lib/features/onboarding/presentation/onboarding_screen.dart
//
// ONBOARDING-001 — 출생 정보 입력 화면.
//
// 9주차 동작
//  1. 사용자 입력 → BirthInfo 객체로 변환
//  2. currentBirthInfoProvider 에 저장 (Riverpod state)
//  3. AppShell 로 이동 → Astrology/Today 화면이 자동으로 새 차트 호출
//
// 10주차에서 Firestore + 입력값 검증 정교화 + geocoding 으로 lat/lng 변환.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nicknameC = TextEditingController(text: '물병자리의 꿈');
  final _dateC = TextEditingController(text: '1995-02-15');
  final _timeC = TextEditingController(text: '14:30');
  final _placeC = TextEditingController(text: '서울특별시');

  String? _error;

  @override
  void dispose() {
    _nicknameC.dispose();
    _dateC.dispose();
    _timeC.dispose();
    _placeC.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    try {
      final dateParts = _dateC.text.split('-').map(int.parse).toList();
      final timeParts = _timeC.text.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length != 2) {
        throw const FormatException('형식이 올바르지 않습니다.');
      }
      final dt = DateTime(
        dateParts[0],
        dateParts[1],
        dateParts[2],
        timeParts[0],
        timeParts[1],
      );

      final birth = BirthInfo(
        nickname: _nicknameC.text.trim().isEmpty
            ? '익명의 행성'
            : _nicknameC.text.trim(),
        dateTime: dt,
        // 9주차에는 출생지 → 좌표 변환은 나중. 한국 기본값으로 폴백.
        latitude: 37.5665,
        longitude: 126.9780,
        utcOffset: '+09:00',
        placeName: _placeC.text.trim(),
      );

      ref.read(currentBirthInfoProvider.notifier).state = birth;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      setState(() => _error =
          '입력값을 다시 확인해주세요 (생년월일은 1995-02-15, 시간은 14:30 형식).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('출생 정보 입력')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const ScreenCodeChip(
                code: 'ONBOARDING-001', label: '출생 정보 입력'),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '차트를 만들기 위한\n첫 정보를 알려주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '정확한 시간을 알수록 차트의 정밀도가 올라갑니다. '
              '나중에 마이페이지에서 언제든 수정할 수 있어요.',
              style: TextStyle(color: AppColors.inkMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameC,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      hintText: '예: 물병자리의 꿈',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dateC,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: '생년월일',
                      hintText: '예: 1995-02-15',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeC,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: '출생 시간',
                      hintText: '예: 14:30',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _placeC,
                    decoration: const InputDecoration(
                      labelText: '출생지',
                      hintText: '예: 서울특별시',
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.ink)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(onPressed: _submit, child: const Text('차트 만들기')),
          ],
        ),
      ),
    );
  }
}
