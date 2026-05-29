// lib/features/onboarding/presentation/onboarding_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../data/place_resolver.dart';
import '../app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    super.key,
    this.initialBirthInfo,
    this.isEditing = false,
  });

  final BirthInfo? initialBirthInfo;
  final bool isEditing;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nicknameC;
  late final TextEditingController _dateC;
  late final TextEditingController _timeC;
  late final TextEditingController _placeC;
  late final PlaceResolver _placeResolver;

  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final birth = widget.initialBirthInfo ?? BirthInfo.demo();
    _nicknameC = TextEditingController(text: birth.nickname);
    _dateC = TextEditingController(
      text: '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}',
    );
    _timeC = TextEditingController(
      text: '${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)}',
    );
    _placeC = TextEditingController(text: birth.placeName ?? '서울특별시');
    _placeResolver = PlaceResolver();
  }

  @override
  void dispose() {
    _nicknameC.dispose();
    _dateC.dispose();
    _timeC.dispose();
    _placeC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() { _error = null; _isSubmitting = true; });

    try {
      final dateParts = _dateC.text.split('-').map(int.parse).toList();
      final timeParts = _timeC.text.split(':').map(int.parse).toList();
      if (dateParts.length != 3 || timeParts.length != 2) {
        throw const FormatException('형식 오류');
      }

      final dt = DateTime(
        dateParts[0], dateParts[1], dateParts[2],
        timeParts[0], timeParts[1],
      );

      final placeQuery = _placeC.text.trim();
      final resolvedPlace = await _placeResolver.resolve(placeQuery);
      final fallbackBirth = widget.initialBirthInfo ?? BirthInfo.demo();

      final birth = BirthInfo(
        nickname: _nicknameC.text.trim().isEmpty ? '익명의 행성' : _nicknameC.text.trim(),
        dateTime: dt,
        latitude: resolvedPlace?.latitude ?? fallbackBirth.latitude,
        longitude: resolvedPlace?.longitude ?? fallbackBirth.longitude,
        utcOffset: '+09:00',
        placeName: placeQuery.isEmpty ? fallbackBirth.placeName : placeQuery,
      );

      ref.read(currentBirthInfoProvider.notifier).state = birth;
      ref.invalidate(myNatalChartProvider);

      // Firestore 저장 (실패해도 앱은 계속)
      try {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'birthInfo': {
              'dateTimeLocal': '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}T${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)}:00',
              'utcOffset': birth.utcOffset,
              'placeName': birth.placeName ?? '',
              'latitude': birth.latitude,
              'longitude': birth.longitude,
              'geocodingSource': 'manual',
            },
            'profileCompleted': true,
            'nickname': birth.nickname,
          });
        }
      } catch (e) {
        debugPrint('Firestore 저장 실패 (무시): $e');
      }

      if (!mounted) return;

      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      }
    } catch (e) {
      setState(() => _error = '입력값을 다시 확인해주세요 (생년월일: 1995-02-15, 시간: 14:30).');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '출생 정보 수정' : '출생 정보 입력'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ScreenCodeChip(
              code: 'ONBOARDING-001',
              label: widget.isEditing ? '출생 정보 수정' : '출생 정보 입력',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.isEditing ? '출생 정보를\n다시 조정해 주세요' : '차트를 만들기 위한\n첫 정보를 알려주세요',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.isEditing
                  ? '저장하면 현재 차트와 화면 정보가 새 입력값 기준으로 다시 반영됩니다.'
                  : '정확한 시간을 알수록 차트의 정밀도가 올라갑니다.',
              style: const TextStyle(color: AppColors.inkMuted, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Panel(
              child: Column(
                children: [
                  TextField(
                    controller: _nicknameC,
                    decoration: const InputDecoration(labelText: '닉네임', hintText: '예: 물병자리의 꿈'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dateC,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: '생년월일', hintText: '예: 1995-02-15'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _timeC,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: '출생 시간', hintText: '예: 14:30'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _placeC,
                    decoration: const InputDecoration(labelText: '출생지', hintText: '예: 서울특별시'),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 10),
                    const Text(
                      '웹에서는 출생지 좌표 자동 변환이 제한될 수 있어요.',
                      style: TextStyle(color: AppColors.inkMuted, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.ink)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.isEditing ? '변경 사항 저장' : '차트 만들기'),
            ),
          ],
        ),
      ),
    );
  }

  String _pad(int value) => value.toString().padLeft(2, '0');
}