// lib/features/onboarding/presentation/onboarding_screen.dart
//
// ONBOARDING-001 — 별자리의 초대 (3단계 스텝 방식)
//
// Step 1: 생년월일 입력
// Step 2: 출생 시간 입력
// Step 3: 출생지 입력 → 완료 시 Firestore 저장
//
// 마이페이지에서 수정할 때는 isEditing=true 로 호출.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _step = 0; // 0=생년월일, 1=출생시간, 2=출생지

  // 네이티브 Picker로 선택된 값 (TextField 대신)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _timeUnknown = false; // 출생 시간 모름 토글

  // 출생지 (자유 텍스트 유지 — geocoding 연동)
  final _placeCtrl = TextEditingController();

  String? _error;
  bool _isSubmitting = false;

  final _placeResolver = PlaceResolver();

  @override
  void initState() {
    super.initState();
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
    _placeCtrl.dispose();
    super.dispose();
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
    if (picked != null) setState(() { _selectedTime = picked; _timeUnknown = false; });
  }

  // ── 다음 스텝으로 ───────────────────────────────────────────────
  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_selectedDate == null) {
          setState(() => _error = '생년월일을 선택해주세요.');
          return;
        }
        setState(() => _step = 1);
      case 1:
        // 시간은 선택사항 — "모름" 또는 선택 완료면 다음으로
        setState(() => _step = 2);
      case 2:
        _submit();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  // ── 최종 저장 ────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // ── 1. 생년월일 (네이티브 Picker로 선택됨) ────────────────────
      if (_selectedDate == null) {
        setState(() => _error = '생년월일을 선택해주세요.');
        return;
      }

      // ── 2. 출생 시간 (선택사항 — 모름이면 00:00) ──────────────────
      final hour = (_timeUnknown || _selectedTime == null) ? 0 : _selectedTime!.hour;
      final minute = (_timeUnknown || _selectedTime == null) ? 0 : _selectedTime!.minute;

      final dt = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        hour, minute,
      );

      // ── 3. 출생지 Geocoding ─────────────────────────────────────
      double latitude;
      double longitude;
      String? placeName;
      final placeQuery = _placeCtrl.text.trim();

      if (placeQuery.isEmpty) {
        // 출생지 미입력 → 서울 기본값으로 안내 후 처리
        if (kDebugMode) {
          // ignore: avoid_print
          print('[Onboarding] 출생지 미입력 → 서울 기본값 사용');
        }
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
              // ignore: avoid_print
              print('[Onboarding] 장소 변환 성공: "$placeQuery" → '
                  'lat=${place.latitude}, lng=${place.longitude}');
            }
          case PlaceResolutionFailure(:final kind):
            setState(() => _error = _placeErrorMessage(kind));
            return;
        }
      } else {
        // Web 등 geocoding 미지원 플랫폼 → 사용자 입력값 + 서울 좌표 fallback
        latitude = 37.5665;
        longitude = 126.9780;
        placeName = placeQuery;
        if (kDebugMode) {
          // ignore: avoid_print
          print('[Onboarding] geocoding 미지원 플랫폼 → 서울 좌표 fallback, placeName="$placeQuery"');
        }
      }

      // ── 4. BirthInfo 구성 ────────────────────────────────────────
      // utcOffset: 현재 한국 앱 대상이므로 기본 +09:00. 해외 출생지는 추후 geocoding
      // 결과에서 timezone 을 추출하여 자동화 예정.
      final birth = BirthInfo(
        nickname: ref.read(currentUserProvider)?.loginId ?? '별자리',
        dateTime: dt,
        latitude: latitude,
        longitude: longitude,
        utcOffset: '+09:00',
        placeName: placeName,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('[Onboarding] 저장할 BirthInfo: ${birth.chartVersion}');
      }

      // ── 5. 로그인 확인 ───────────────────────────────────────────
      final uid = ref.read(currentUserProvider)?.uid
          ?? ref.read(currentUserIdProvider).valueOrNull;
      if (uid == null) {
        setState(() => _error = '로그인 정보를 찾을 수 없어요. 앱을 재시작해주세요.');
        return;
      }

      await ref.read(userRepositoryProvider).upsertBirthInfo(
        uid: uid,
        birthInfo: birth,
        nickname: birth.nickname,
      );

      // Firestore stream 이 실제로 최신 birth 를 반영한 뒤에만 재분석을 시작한다.
      // 그렇지 않으면 저장 직후 old birth 로 한 번 더 요청하는 race 가 생길 수 있다.
      try {
        // ignore: deprecated_member_use
        await ref
            .read(currentUserProfileProvider.stream)
            .firstWhere((profile) => profile?.birthInfo?.chartVersion == birth.chartVersion)
            .timeout(const Duration(seconds: 5));
      } on TimeoutException catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[Onboarding] profile sync 대기 timeout (계속 진행): $e');
        }
      }

      if (!mounted) return;

      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
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

  // ── UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1F), Color(0xFF08235F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // 아이콘
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A5FD4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  widget.isEditing ? '출생 정보 수정' : '별자리의 초대',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Step ${_step + 1} of 3',
                  style: const TextStyle(
                    color: Color(0xFF5B9BFF),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 20),

                // 진행 바
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? const Color(0xFF1A5FD4)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // 스텝 카드
                Expanded(
                  child: _StepCard(
                    step: _step,
                    selectedDate: _selectedDate,
                    selectedTime: _selectedTime,
                    timeUnknown: _timeUnknown,
                    placeCtrl: _placeCtrl,
                    error: _error,
                    onPickDate: _pickDate,
                    onPickTime: _pickTime,
                    onToggleTimeUnknown: (v) => setState(() { _timeUnknown = v; if (v) _selectedTime = null; }),
                  ),
                ),

                const SizedBox(height: 16),

                // 버튼
                _StepButtons(
                  step: _step,
                  isSubmitting: _isSubmitting,
                  onNext: _next,
                  onPrev: _prev,
                ),

                const SizedBox(height: 32),
              ],
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
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final bool timeUnknown;
  final TextEditingController placeCtrl;
  final String? error;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final ValueChanged<bool> onToggleTimeUnknown;

  static const _cardDecoration = BoxDecoration(
    color: Color(0xD90D1830),
    borderRadius: BorderRadius.all(Radius.circular(24)),
    border: Border.fromBorderSide(BorderSide(color: Colors.white12)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Step 0: 생년월일 DatePicker ──────────────────────────
          if (step == 0) ...[
            const Text('생년월일', style: TextStyle(color: Colors.white70, fontSize: 14)),
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

          // ── Step 1: 출생 시간 TimePicker + 모름 토글 ─────────────
          if (step == 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('출생 시간', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Row(
                  children: [
                    const Text('모름', style: TextStyle(color: Colors.white38, fontSize: 13)),
                    const SizedBox(width: 4),
                    Switch(
                      value: timeUnknown,
                      onChanged: onToggleTimeUnknown,
                      activeColor: const Color(0xFF1A5FD4),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_rounded, color: Colors.white24, size: 20),
                    SizedBox(width: 8),
                    Text('시간 모름 — 상승 별자리 계산 제한됨',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              '정확한 출생 시간은 상승 별자리(Ascendant)에 영향을 줘요.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],

          // ── Step 2: 출생지 TextField (geocoding 연동) ─────────────
          if (step == 2) ...[
            const Text('출생지', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: placeCtrl,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              enableSuggestions: true,
              autocorrect: false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '예: 서울특별시, 부산광역시, 제주시',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1A5FD4), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 8),
              const Text(
                '웹에서는 자동 좌표 변환이 제한돼요. 정확한 계산은 앱에서 진행해주세요.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                '시/군/구 단위로 입력하면 더 정확해요. 예: 강남구, 해운대구',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
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
      case 0: return '언제 태어나셨나요?';
      case 1: return '몇 시에 태어나셨나요?';
      default: return '어디서 태어나셨나요?';
    }
  }

  String get _subtitle {
    switch (step) {
      case 0: return '정확한 별자리 차트를 위해 필요합니다';
      case 1: return '정확한 시간은 상승 별자리에 영향을 줍니다';
      default: return '지역에 따라 천체의 위치가 달라집니다';
    }
  }
}

// ── Picker 버튼 위젯 ─────────────────────────────────────────────────
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
            color: selected ? const Color(0xFF1A5FD4) : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? const Color(0xFF5B9BFF) : Colors.white38, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white38,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(
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
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: _primaryButton('다음', onNext, isSubmitting),
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
              child: const Text('이전',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: _primaryButton(step == 2 ? '완료' : '다음', onNext, isSubmitting),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap, bool loading) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A5FD4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
      onPressed: loading ? null : onTap,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(label,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }
}
