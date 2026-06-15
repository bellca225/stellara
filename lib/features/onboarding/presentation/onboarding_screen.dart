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

import '../../../core/data/kr_regions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/glass_pickers.dart';
import '../../../core/widgets/region_picker.dart';
import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/landing_screen.dart';
import '../../users/application/user_providers.dart';
import '../app_shell.dart';

part 'onboarding_screen_widgets.dart';

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

  // 출생지 (목록에서만 선택)
  KrRegion? _selectedRegion;

  String? _error;
  bool _isSubmitting = false;

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
      _selectedRegion = findKrRegionByName(b.placeName);
    }
    _initialName = _nameCtrl.text.trim();
    _initialDate = _selectedDate;
    _initialTime = _selectedTime;
    _initialPlace = _selectedRegion?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRegion() async {
    FocusScope.of(context).unfocus();
    final picked = await showRegionPicker(
      context,
      selectedName: _selectedRegion?.name,
    );
    if (picked != null) {
      setState(() {
        _selectedRegion = picked;
        _error = null;
      });
    }
  }

  // ── 이름 검증 ─────────────────────────────────────────────────────
  String? _validateName(String value) {
    final v = value.trim();
    if (v.isEmpty) return '이름을 입력해주세요.';
    if (v.length > 20) return '20자 이내로 입력해주세요.';
    return null;
  }

  // ── 날짜 선택 (글라스 휠 바텀시트) ────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showGlassDatePicker(
      context,
      initialDate: _selectedDate ?? DateTime(2002, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── 시간 선택 (글라스 휠 바텀시트) ────────────────────────────────
  Future<void> _pickTime() async {
    final picked = await showGlassTimePicker(
      context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
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

      final region = _selectedRegion;
      if (region == null) {
        setState(() => _error = '출생지를 선택해주세요.');
        return;
      }
      final double latitude = region.latitude;
      final double longitude = region.longitude;
      final String placeName = region.name;

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
        await ref
            .read(userRepositoryProvider)
            .watch(uid)
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

  bool get _hasUnsavedChanges {
    final currentName = _nameCtrl.text.trim();
    final currentPlace = _selectedRegion?.name ?? '';
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
    final shouldLeave = await _showGlassConfirm(
      title: '수정 내용을 나갈까요?',
      message: '저장하지 않은 변경 내용은 사라져요.',
      cancelLabel: '계속 수정',
      confirmLabel: '나가기',
    );
    return shouldLeave ?? false;
  }

  // ── 글라스 스타일 확인 다이얼로그 ─────────────────────────────────
  Future<bool?> _showGlassConfirm({
    required String title,
    required String message,
    required String cancelLabel,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F1E38), Color(0xFF0A1326)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
            boxShadow: kGlassShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 14,
                  height: 1.45,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: cancelLabel,
                      isPrimary: false,
                      height: 50,
                      fontSize: 15,
                      onTap: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: confirmLabel,
                      isPrimary: true,
                      height: 50,
                      fontSize: 15,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackToMyPage() async {
    final canLeave = await _confirmDiscardIfNeeded();
    if (!mounted || !canLeave) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(false);
  }

  // ── 계정 만들기(온보딩) 취소 → 로그아웃 후 랜딩으로 ──────────────
  Future<void> _cancelSignup() async {
    FocusScope.of(context).unfocus();
    final shouldCancel = await _showGlassConfirm(
      title: '계정 만들기를 취소할까요?',
      message: '지금 나가면 입력한 정보가 저장되지 않아요.',
      cancelLabel: '계속하기',
      confirmLabel: '취소하기',
    );
    if (shouldCancel != true || !mounted) return;

    try {
      await ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // 로그아웃 실패해도 화면 전환은 진행 (세션 정리는 다음 진입 시 처리)
    }
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(currentUserProfileProvider);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
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
        final focusScope = FocusScope.of(context);
        final navigator = Navigator.of(context);
        if (didPop) return;
        final canLeave = await _confirmDiscardIfNeeded();
        if (!mounted || !canLeave) return;
        focusScope.unfocus();
        navigator.pop(false);
      },
      child: StarBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // ── 헤더: 뒤로가기 버튼 (점성술 화면과 동일한 원형 글라스) ──
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : (widget.isEditing
                                ? _handleBackToMyPage
                                : _cancelSignup),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                          ),
                          border: Border.all(
                            color: const Color(0x26FFFFFF),
                            width: 0.636,
                          ),
                          boxShadow: kGlassShadow,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF8EC5FF),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // 계정 만들기(신규) 모드는 헤더가 짧으므로 기존 여백감 유지
                  if (!widget.isEditing) const SizedBox(height: 125),

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
                        ? 'Step $_step of 3'
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
                    selectedRegion: _selectedRegion,
                    error: _error,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                    onPickRegion: _pickRegion,
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
