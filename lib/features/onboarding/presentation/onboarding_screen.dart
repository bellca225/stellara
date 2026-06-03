// lib/features/onboarding/presentation/onboarding_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../../users/application/user_providers.dart';
import '../data/place_resolver.dart';
import '../app_shell.dart';

const _svgCalendar = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M10.666 2.6665V7.9995" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M21.332 2.6665V7.9995" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M25.3318 5.33299H6.66626C5.19359 5.33299 3.99976 6.52683 3.99976 7.99949V26.665C3.99976 28.1377 5.19359 29.3315 6.66626 29.3315H25.3318C26.8044 29.3315 27.9983 28.1377 27.9983 26.665V7.99949C27.9983 6.52683 26.8044 5.33299 25.3318 5.33299Z" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M3.99976 13.3325H27.9983" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
  int _step = 0;

  final _nameCtrl = TextEditingController();
  String? _nameError;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _timeUnknown = false;

  final _placeCtrl = TextEditingController();

  String? _error;
  bool _isSubmitting = false;

  final _placeResolver = PlaceResolver();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _step = 1;
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.effectiveDisplayName;
    }
    final b = widget.initialBirthInfo;
    if (b != null) {
      _selectedDate = b.dateTime;
      final hour = b.dateTime.hour;
      final minute = b.dateTime.minute;
      if (hour == 0 && minute == 0) {
        _timeUnknown = true;
      } else {
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
      _placeCtrl.text = b.placeName ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    final v = value.trim();
    if (v.isEmpty) return '이름을 입력해주세요.';
    if (v.length > 20) return '20자 이내로 입력해주세요.';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1995, 2, 15),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '생년월일 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2B7FFF),
            onPrimary: Colors.white,
            surface: Color(0xFF0D1830),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: '출생 시간 선택',
      cancelText: '취소',
      confirmText: '확인',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2B7FFF),
            onPrimary: Colors.white,
            surface: Color(0xFF0D1830),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() {
        _selectedTime = picked;
        _timeUnknown = false;
      });
  }

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        final nameErr = _validateName(_nameCtrl.text);
        if (nameErr != null) {
          setState(() => _nameError = nameErr);
          return;
        }
        setState(() {
          _nameError = null;
          _step = 1;
        });
      case 1:
        if (_selectedDate == null) {
          setState(() => _error = '생년월일을 선택해주세요.');
          return;
        }
        setState(() => _step = 2);
      case 2:
        setState(() => _step = 3);
      case 3:
        _submit();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (_selectedDate == null) {
        setState(() => _error = '생년월일을 선택해주세요.');
        return;
      }
      final hour = (_timeUnknown || _selectedTime == null)
          ? 0
          : _selectedTime!.hour;
      final minute = (_timeUnknown || _selectedTime == null)
          ? 0
          : _selectedTime!.minute;
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        hour,
        minute,
      );

      double latitude;
      double longitude;
      String? placeName;
      final placeQuery = _placeCtrl.text.trim();

      if (placeQuery.isEmpty) {
        latitude = 37.5665;
        longitude = 126.9780;
        placeName = '서울특별시';
      } else if (_placeResolver.supportsForwardGeocoding) {
        final result = await _placeResolver.resolveDetailed(placeQuery);
        switch (result) {
          case PlaceResolutionSuccess(:final place):
            latitude = place.latitude;
            longitude = place.longitude;
            placeName = place.placeName;
          case PlaceResolutionFailure(:final kind):
            setState(() => _error = _placeErrorMessage(kind));
            return;
        }
      } else {
        latitude = 37.5665;
        longitude = 126.9780;
        placeName = placeQuery;
      }

      final enteredName = _nameCtrl.text.trim();
      final displayName = enteredName.isNotEmpty
          ? enteredName
          : (ref
                    .read(currentUserProfileProvider)
                    .valueOrNull
                    ?.effectiveDisplayName ??
                ref.read(currentUserProvider)?.effectiveDisplayName ??
                '별자리');

      final birth = BirthInfo(
        nickname: displayName,
        dateTime: dt,
        latitude: latitude,
        longitude: longitude,
        utcOffset: '+09:00',
        placeName: placeName,
      );

      final uid =
          ref.read(currentUserProvider)?.uid ??
          ref.read(currentUserIdProvider).valueOrNull;
      if (uid == null) {
        setState(() => _error = '로그인 정보를 찾을 수 없어요.');
        return;
      }

      await ref
          .read(userRepositoryProvider)
          .upsertBirthInfo(
            uid: uid,
            birthInfo: birth,
            nickname: displayName,
            displayName: displayName,
          );

      try {
        await ref
            .read(currentUserProfileProvider.stream)
            .firstWhere((p) => p?.birthInfo?.chartVersion == birth.chartVersion)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException catch (_) {}

      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      }
    } on FormatException {
      setState(() => _error = '입력값을 다시 확인해주세요.');
    } catch (e) {
      setState(() => _error = '저장 중 오류가 발생했어요.');
      if (kDebugMode) print('[Onboarding] error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _placeErrorMessage(PlaceResolutionFailureKind kind) {
    switch (kind) {
      case PlaceResolutionFailureKind.emptyQuery:
        return '출생지를 입력해주세요.';
      case PlaceResolutionFailureKind.notFound:
        return '출생지를 찾지 못했어요.';
      case PlaceResolutionFailureKind.platformError:
        return '주소 변환 중 오류가 발생했어요.';
      case PlaceResolutionFailureKind.unsupportedPlatform:
        return '현재 환경에서는 자동 변환이 제한돼요.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060618), Color(0xFF0A0F2E), Color(0xFF0D1F5C)],
            stops: [0.0, 0.5, 1.0],
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
                left: x / 100 * MediaQuery.of(context).size.width,
                top: y / 100 * MediaQuery.of(context).size.height,
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2B7FFF), Color(0xFF155DFC)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B7FFF).withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.string(
                          _svgCalendar,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isEditing ? '출생 정보 수정' : '별자리의 초대',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isEditing
                          ? 'Step $_step of 3'
                          : 'Step ${_step + 1} of 4',
                      style: const TextStyle(
                        color: Color(0xFF5B9BFF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: List.generate(widget.isEditing ? 3 : 4, (i) {
                        final filled = widget.isEditing
                            ? i < _step
                            : i <= _step;
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(
                              right: i < (widget.isEditing ? 2 : 3) ? 4 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: filled
                                  ? const Color(0xFF2B7FFF)
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _StepCard(
                        step: _step,
                        nameCtrl: _nameCtrl,
                        nameError: _nameError,
                        selectedDate: _selectedDate,
                        selectedTime: _selectedTime,
                        timeUnknown: _timeUnknown,
                        placeCtrl: _placeCtrl,
                        error: _error,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                        onToggleTimeUnknown: (v) => setState(() {
                          _timeUnknown = v;
                          if (v) _selectedTime = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StepButtons(
                      step: _step,
                      isSubmitting: _isSubmitting,
                      onNext: _next,
                      onPrev: _prev,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.nameCtrl,
    this.nameError,
    required this.selectedDate,
    required this.selectedTime,
    required this.timeUnknown,
    required this.placeCtrl,
    required this.error,
    required this.onPickDate,
    required this.onPickTime,
    required this.onToggleTimeUnknown,
  });

  final int step;
  final TextEditingController nameCtrl;
  final String? nameError;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool timeUnknown;
  final TextEditingController placeCtrl;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<bool> onToggleTimeUnknown;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: const TextStyle(color: Color(0xFF8EC5FF), fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (step == 0) ...[
            const Text(
              '이름',
              style: TextStyle(
                color: Color(0xFF8EC5FF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              maxLength: 20,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '예: 별이, 나영, 김별',
                hintStyle: const TextStyle(color: Color(0x668EC5FF)),
                counterText: '',
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2B7FFF),
                    width: 1.5,
                  ),
                ),
                errorText: nameError,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],

          if (step == 1) ...[
            const Text(
              '생년월일',
              style: TextStyle(
                color: Color(0xFF8EC5FF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _PickerButton(
              icon: Icons.calendar_month_outlined,
              label: selectedDate == null
                  ? '날짜 선택'
                  : '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일',
              selected: selectedDate != null,
              onTap: onPickDate,
            ),
          ],

          if (step == 2) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '출생 시간',
                  style: TextStyle(
                    color: Color(0xFF8EC5FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      '모름',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: timeUnknown,
                      onChanged: onToggleTimeUnknown,
                      activeColor: const Color(0xFF2B7FFF),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!timeUnknown)
              _PickerButton(
                icon: Icons.access_time_rounded,
                label: selectedTime == null
                    ? '시간 선택'
                    : selectedTime!.format(context),
                selected: selectedTime != null,
                onTap: onPickTime,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '시간 모름 — 상승 별자리 계산 제한됨',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],

          if (step == 3) ...[
            const Text(
              '출생지',
              style: TextStyle(
                color: Color(0xFF8EC5FF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: placeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '예: 서울특별시, 부산광역시',
                hintStyle: const TextStyle(color: Color(0x668EC5FF)),
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: Colors.white38,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2B7FFF),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  String get _title {
    switch (step) {
      case 0:
        return '어떻게 불러드리면 될까요?';
      case 1:
        return '언제 태어나셨나요?';
      case 2:
        return '몇 시에 태어나셨나요?';
      default:
        return '어디서 태어나셨나요?';
    }
  }

  String get _subtitle {
    switch (step) {
      case 0:
        return '당신만의 별자리 차트를 만들기 위해 필요해요.';
      case 1:
        return '정확한 별자리 차트를 위해 필요합니다';
      case 2:
        return '정확한 시간은 상승 별자리에 영향을 줍니다';
      default:
        return '지역에 따라 천체의 위치가 달라집니다';
    }
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF2B7FFF) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF5B9BFF) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButtons extends StatelessWidget {
  const _StepButtons({
    required this.step,
    required this.isSubmitting,
    required this.onNext,
    required this.onPrev,
  });
  final int step;
  final bool isSubmitting;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: _primaryBtn('다음', onNext, isSubmitting),
      );
    }
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: isSubmitting ? null : onPrev,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                '이전',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: _primaryBtn(step == 3 ? '완료' : '다음', onNext, isSubmitting),
          ),
        ),
      ],
    );
  }

  Widget _primaryBtn(String label, VoidCallback onTap, bool loading) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2B7FFF), Color(0xFF155DFC)],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
