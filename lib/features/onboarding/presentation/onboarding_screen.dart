// lib/features/onboarding/presentation/onboarding_screen.dart
//
// ONBOARDING — 별자리의 초대 (4단계 스텝 방식)
// Figma Screens 6/7/8/9 기준
//
// Step 0: 이름(displayName) 입력
// Step 1: 생년월일 입력
// Step 2: 출생 시간 입력
// Step 3: 출생지 입력 → 완료 시 Firestore 저장
//
// 마이페이지에서 수정할 때는 isEditing=true 로 호출.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../../users/application/user_providers.dart';
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
  int _step = 0; // 0=이름, 1=생년월일, 2=출생시간, 3=출생지

  // Step 0: 이름(displayName)
  final _nameCtrl = TextEditingController();
  String? _nameError;

  // 네이티브 Picker로 선택된 값
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // 출생지
  final _placeCtrl = TextEditingController();

  String? _error;
  bool _isSubmitting = false;

  final _placeResolver = PlaceResolver();

  String _initialName = '';
  DateTime? _initialDate;
  TimeOfDay? _initialTime;
  String _initialPlace = '';

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
      _selectedTime = TimeOfDay(
        hour: b.dateTime.hour,
        minute: b.dateTime.minute,
      );
      _placeCtrl.text = b.placeName ?? '';
    }
    _initialName = _nameCtrl.text.trim();
    _initialDate = _selectedDate;
    _initialTime = _selectedTime;
    _initialPlace = _placeCtrl.text.trim();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  // ── 이름 검증 ─────────────────────────────────────────────────────
  String? _validateName(String value) {
    final v = value.trim();
    if (v.isEmpty) return '이름을 입력해주세요.';
    if (v.length > 20) return '20자 이내로 입력해주세요.';
    return null;
  }

  // ── 날짜 선택 ─────────────────────────────────────────────────────
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
            primary: Color(0xFF1A5FD4),
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

  // ── 시간 선택 ─────────────────────────────────────────────────────
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
            primary: Color(0xFF1A5FD4),
            onPrimary: Colors.white,
            surface: Color(0xFF0D1830),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // ── 다음 스텝으로 ───────────────────────────────────────────────
  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        final nameErr = _validateName(_nameCtrl.text);
        if (nameErr != null) {
          setState(() => _nameError = nameErr);
          return;
        }
        // step 0(이름 입력)에서 step 1로 넘어갈 때 TextField가 dispose되기 전에
        // IME 연결을 먼저 해제해 text_input assertion을 방지한다.
        FocusScope.of(context).unfocus();
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
        if (_selectedTime == null) {
          setState(() => _error = '출생 시간을 선택해주세요.');
          return;
        }
        // step 3에 출생지 TextField가 있으므로 이전 포커스 정리
        FocusScope.of(context).unfocus();
        setState(() => _step = 3);
      case 3:
        // 출생지 TextField가 포커스된 채 _submit()이 호출될 수 있으므로 먼저 해제
        FocusScope.of(context).unfocus();
        _submit();
    }
  }

  void _prev() {
    if (_step > 0) {
      // step 3(출생지 TextField)에서 이전으로 돌아갈 때 IME 연결 먼저 해제
      FocusScope.of(context).unfocus();
      setState(() => _step--);
    }
  }

  // ── 최종 저장 ────────────────────────────────────────────────────
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
      if (_selectedTime == null) {
        setState(() => _error = '출생 시간을 선택해주세요.');
        return;
      }
      final hour = _selectedTime!.hour;
      final minute = _selectedTime!.minute;

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
        if (kDebugMode) print('[Onboarding] 출생지 미입력 → 서울 기본값 사용');
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
            if (kDebugMode) {
              print(
                '[Onboarding] 장소 변환 성공: "$placeQuery" → '
                'lat=${place.latitude}, lng=${place.longitude}',
              );
            }
          case PlaceResolutionFailure(:final kind):
            setState(() => _error = _placeErrorMessage(kind));
            return;
        }
      } else {
        latitude = 37.5665;
        longitude = 126.9780;
        placeName = placeQuery;
        if (kDebugMode) {
          print(
            '[Onboarding] geocoding 미지원 → 서울 fallback, placeName="$placeQuery"',
          );
        }
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

      if (kDebugMode) {
        print('[Onboarding] 저장할 BirthInfo: ${birth.chartVersion}');
      }

      final uid =
          ref.read(currentUserProvider)?.uid ??
          ref.read(currentUserIdProvider).valueOrNull;
      if (uid == null) {
        setState(() => _error = '로그인 정보를 찾을 수 없어요. 앱을 재시작해주세요.');
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
        // ignore: deprecated_member_use
        await ref
            .read(currentUserProfileProvider.stream)
            .firstWhere(
              (profile) =>
                  profile?.birthInfo?.chartVersion == birth.chartVersion,
            )
            .timeout(const Duration(seconds: 5));
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          print('[Onboarding] profile sync 대기 timeout (계속 진행): $e');
        }
      }

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
      setState(() => _error = '저장 중 오류가 발생했어요. 다시 시도해주세요.');
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
        return '출생지를 찾지 못했어요. 더 구체적으로 입력해주세요.';
      case PlaceResolutionFailureKind.platformError:
        return '주소 변환 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
      case PlaceResolutionFailureKind.unsupportedPlatform:
        return '현재 환경에서는 자동 변환이 제한돼요.';
    }
  }

  bool get _hasUnsavedChanges {
    final currentName = _nameCtrl.text.trim();
    final currentPlace = _placeCtrl.text.trim();
    final currentTime = _selectedTime;
    final sameTime =
        currentTime?.hour == _initialTime?.hour &&
        currentTime?.minute == _initialTime?.minute;
    return currentName != _initialName ||
        _selectedDate != _initialDate ||
        !sameTime ||
        currentPlace != _initialPlace;
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!widget.isEditing || !_hasUnsavedChanges) return true;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수정 내용을 나갈까요?'),
        content: const Text('저장하지 않은 변경 내용은 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('계속 수정'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  Future<void> _handleBackToMyPage() async {
    final canLeave = await _confirmDiscardIfNeeded();
    if (!mounted || !canLeave) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(false);
  }

  // ── 진행바 (4개 세그먼트) ────────────────────────────────────────
  Widget _buildProgressBar() {
    final totalSteps = widget.isEditing ? 3 : 4;
    final filledSteps = widget.isEditing ? _step : _step + 1;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isFilled = index < filledSteps;
        final isLast = index == totalSteps - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 4),
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: isFilled
                  ? const LinearGradient(
                      colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
                    )
                  : null,
              color: isFilled ? null : Colors.white.withValues(alpha: 0.12),
            ),
          ),
        );
      }),
    );
  }

  // ── 스텝별 아이콘 ───────────────────────────────────────────────
  IconData get _stepIcon {
    if (widget.isEditing) {
      switch (_step) {
        case 1:
          return Icons.calendar_today_outlined;
        case 2:
          return Icons.access_time_outlined;
        default:
          return Icons.location_on_outlined;
      }
    }
    switch (_step) {
      case 0:
        return Icons.person_outline_rounded;
      case 1:
        return Icons.calendar_today_outlined;
      case 2:
        return Icons.access_time_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  // ── UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !widget.isEditing || !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmDiscardIfNeeded();
        if (!mounted || !canLeave) return;
        FocusScope.of(context).unfocus();
        Navigator.of(context).pop(false);
      },
      child: StarBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // ── 헤더 (수정 모드: 뒤로가기 버튼) ──────────────
                  if (widget.isEditing) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _isSubmitting ? null : _handleBackToMyPage,
                        child: Container(
                          width: 37,
                          height: 37,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0x26FFFFFF),
                              width: 0.636,
                            ),
                            boxShadow: kGlassShadow,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 181),

                  // ── 아이콘 ──────────────────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
                      ),
                      boxShadow: const [
                        BoxShadow(color: Color(0x4D3B82F6), blurRadius: 10),
                      ],
                    ),
                    child: Icon(_stepIcon, color: Colors.white, size: 32),
                  ),

                  const SizedBox(height: 16),

                  // ── 타이틀 ──────────────────────────────────────
                  Text(
                    widget.isEditing ? '출생 정보 수정' : '별자리의 초대',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isEditing
                        ? 'Step ${_step} of 3'
                        : 'Step ${_step + 1} of 4',
                    style: const TextStyle(
                      color: Color(0xFF8EC5FF),
                      fontSize: 12,
                      letterSpacing: -0.2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 진행 바 (4 세그먼트) ─────────────────────────
                  _buildProgressBar(),

                  const SizedBox(height: 32),

                  // ── 스텝 카드 ────────────────────────────────────
                  _StepCard(
                    step: _step,
                    nameCtrl: _nameCtrl,
                    nameError: _nameError,
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    placeCtrl: _placeCtrl,
                    error: _error,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                  ),

                  const SizedBox(height: 20),

                  // ── 버튼 ─────────────────────────────────────────
                  _StepButtons(
                    step: _step,
                    isSubmitting: _isSubmitting,
                    onNext: _next,
                    onPrev: _prev,
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 스텝 카드 ────────────────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.nameCtrl,
    this.nameError,
    required this.selectedDate,
    required this.selectedTime,
    required this.placeCtrl,
    required this.error,
    required this.onPickDate,
    required this.onPickTime,
  });

  final int step;
  final TextEditingController nameCtrl;
  final String? nameError;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final TextEditingController placeCtrl;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 질문 제목 — center 정렬
          Text(
            _title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 28 / 20,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),

          // 부제목 — center 정렬
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 20),

          // ── Step 0: 이름 입력 ──────────────────────────────────
          if (step == 0) ...[
            _GlassFieldLabel('이름'),
            const SizedBox(height: 8),
            _GlassTextInput(
              controller: nameCtrl,
              hintText: '',
              autofocus: true,
              maxLength: 20,
              errorText: nameError,
            ),
          ],

          // ── Step 1: 생년월일 DatePicker ────────────────────────
          if (step == 1) ...[
            _GlassFieldLabel('생년월일'),
            const SizedBox(height: 8),
            _GlassPickerButton(
              icon: Icons.calendar_today_outlined,
              label: selectedDate == null
                  ? '날짜 선택'
                  : '${selectedDate!.year}년 ${selectedDate!.month}월 ${selectedDate!.day}일',
              selected: selectedDate != null,
              onTap: onPickDate,
            ),
          ],

          // ── Step 2: 출생 시간 TimePicker ──────────────────────
          if (step == 2) ...[
            _GlassFieldLabel('출생 시간'),
            const SizedBox(height: 8),
            _GlassPickerButton(
              icon: Icons.access_time_outlined,
              label: selectedTime == null
                  ? '시간 선택'
                  : selectedTime!.format(context),
              selected: selectedTime != null,
              onTap: onPickTime,
            ),
          ],

          // ── Step 3: 출생지 TextField ───────────────────────────
          if (step == 3) ...[
            _GlassFieldLabel('출생지'),
            const SizedBox(height: 8),
            _GlassTextInput(
              controller: placeCtrl,
              hintText: '예: 서울특별시',
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0x668EC5FF),
                size: 20,
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                '시/군/구 단위로 입력하면 더 정확해요.',
                style: TextStyle(color: Color(0x668EC5FF), fontSize: 12),
              ),
            ],
          ],

          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 12,
                letterSpacing: -0.2,
              ),
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

// ── 글래스 입력 필드 (텍스트) ────────────────────────────────────────
class _GlassTextInput extends StatelessWidget {
  const _GlassTextInput({
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.maxLength,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final int? maxLength;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? prefixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return GlassField(
      hasError: errorText != null,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        autocorrect: false,
        onSubmitted: onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          letterSpacing: -0.2,
        ),
        cursorColor: const Color(0xFF8EC5FF),
        decoration: InputDecoration(
          hintText: hintText.isEmpty ? null : hintText,
          hintStyle: const TextStyle(
            color: Color(0x808EC5FF),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.2,
          ),
          prefixIcon: prefixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
          filled: false,
        ),
      ),
    );
  }
}

// ── 글래스 Picker 버튼 ──────────────────────────────────────────────
class _GlassPickerButton extends StatelessWidget {
  const _GlassPickerButton({
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
        height: 49,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF51A2FF) : const Color(0x1FFFFFFF),
            width: selected ? 1.5 : 0.612,
          ),
          boxShadow: kGlassShadow,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF8EC5FF)
                  : const Color(0x668EC5FF),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0x80FFFFFF),
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0x40FFFFFF),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 필드 레이블 ─────────────────────────────────────────────────────
class _GlassFieldLabel extends StatelessWidget {
  const _GlassFieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBEDBFF),
        fontSize: 14,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ── 스텝 버튼 ────────────────────────────────────────────────────────
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
      return _GlassPrimaryButton(
        label: '다음',
        isLoading: isSubmitting,
        onTap: onNext,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _GlassSecondaryButton(
            label: '이전',
            isLoading: false,
            onTap: onPrev,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GlassPrimaryButton(
            label: step == 3 ? '완료' : '다음',
            isLoading: isSubmitting,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

// ── 주 버튼 (파란 그라디언트) ─────────────────────────────────────
class _GlassPrimaryButton extends StatelessWidget {
  const _GlassPrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: true,
      isLoading: isLoading,
      onTap: onTap,
      height: 61,
    );
  }
}

// ── 보조 버튼 (이전) ────────────────────────────────────────────────
class _GlassSecondaryButton extends StatelessWidget {
  const _GlassSecondaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: false,
      isLoading: isLoading,
      onTap: onTap,
      height: 61,
    );
  }
}
