// lib/features/onboarding/presentation/onboarding_screen.dart
//
// ONBOARDING-001 — 별자리의 초대 (3단계 스텝 방식)
//
// Step 1: 생년월일 입력
// Step 2: 출생 시간 입력
// Step 3: 출생지 입력 → 완료 시 Firestore 저장
//
// 마이페이지에서 수정할 때는 isEditing=true 로 호출.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../astrology/application/astrology_providers.dart';
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

  // 각 스텝 컨트롤러
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  String? _error;
  bool _isSubmitting = false;

  final _placeResolver = PlaceResolver();

  @override
  void initState() {
    super.initState();
    final b = widget.initialBirthInfo;
    if (b != null) {
      String pad(int n) => n.toString().padLeft(2, '0');
      _dateCtrl.text =
          '${b.dateTime.year}-${pad(b.dateTime.month)}-${pad(b.dateTime.day)}';
      _timeCtrl.text =
          '${pad(b.dateTime.hour)}:${pad(b.dateTime.minute)}';
      _placeCtrl.text = b.placeName ?? '';
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  // ── 다음 스텝으로 ───────────────────────────────────────────────
  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (!_validateDate(_dateCtrl.text)) return;
        setState(() => _step = 1);
      case 1:
        if (!_validateTime(_timeCtrl.text)) return;
        setState(() => _step = 2);
      case 2:
        _submit();
    }
  }

  void _prev() {
    if (_step > 0) setState(() => _step--);
  }

  // ── 유효성 검사 ─────────────────────────────────────────────────
  bool _validateDate(String value) {
    final parts = value.trim().split('-');
    if (parts.length != 3) {
      setState(() => _error = '형식: 1995-02-15');
      return false;
    }
    try {
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      if (y < 1900 || y > DateTime.now().year) throw FormatException();
      if (m < 1 || m > 12) throw FormatException();
      if (d < 1 || d > 31) throw FormatException();
    } catch (_) {
      setState(() => _error = '올바른 날짜를 입력해주세요. 예: 1995-02-15');
      return false;
    }
    return true;
  }

  bool _validateTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true; // 출생 시간은 선택사항
    final parts = trimmed.split(':');
    if (parts.length != 2) {
      setState(() => _error = '형식: 14:30');
      return false;
    }
    try {
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      if (h < 0 || h > 23 || m < 0 || m > 59) throw FormatException();
    } catch (_) {
      setState(() => _error = '올바른 시간을 입력해주세요. 예: 14:30');
      return false;
    }
    return true;
  }

  // ── 최종 저장 ────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // ── 1. 생년월일 파싱 ──────────────────────────────────────────
      final dateStr = _dateCtrl.text.trim();
      if (dateStr.isEmpty) {
        setState(() => _error = '생년월일을 입력해주세요.');
        return;
      }
      final dateParts = dateStr.split('-').map(int.parse).toList();
      if (dateParts.length != 3) {
        setState(() => _error = '생년월일 형식을 확인해주세요. 예: 1995-02-15');
        return;
      }

      // ── 2. 출생 시간 파싱 (선택사항) ──────────────────────────────
      final timeStr = _timeCtrl.text.trim();
      final timeParts = timeStr.isEmpty
          ? [0, 0]
          : timeStr.split(':').map(int.parse).toList();

      final dt = DateTime(
        dateParts[0], dateParts[1], dateParts[2],
        timeParts[0], timeParts[1],
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

      // 저장 전 이전 birth 기반 캐시를 먼저 무효화한다.
      // Firestore stream 업데이트 타이밍에 의존하지 않기 위해 명시적으로 처리.
      final oldBirth = ref.read(currentBirthInfoProvider);
      if (oldBirth != null) {
        ref.invalidate(natalChartProvider(oldBirth));
      }

      await ref.read(userRepositoryProvider).upsertBirthInfo(
        uid: uid,
        birthInfo: birth,
        nickname: birth.nickname,
      );

      // myNatalChartProvider 도 invalidate 해 Firestore stream 업데이트 전이라도
      // 최신 birth 가 반영된 시점에 즉시 재실행되도록 한다.
      ref.invalidate(myNatalChartProvider);

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
                    dateCtrl: _dateCtrl,
                    timeCtrl: _timeCtrl,
                    placeCtrl: _placeCtrl,
                    error: _error,
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
    required this.dateCtrl,
    required this.timeCtrl,
    required this.placeCtrl,
    required this.error,
  });

  final int step;
  final TextEditingController dateCtrl;
  final TextEditingController timeCtrl;
  final TextEditingController placeCtrl;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1830).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
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
          Text(
            _label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: _keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: _hint,
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF1A5FD4), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          if (step == 1) ...[
            const SizedBox(height: 8),
            const Text(
              '출생 시간을 모른다면 비워두셔도 괜찮아요.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if (kIsWeb && step == 2) ...[
            const SizedBox(height: 8),
            const Text(
              '웹에서는 출생지 자동 변환이 제한될 수 있어요.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 13),
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

  String get _label {
    switch (step) {
      case 0: return '생년월일';
      case 1: return '출생 시간';
      default: return '출생지';
    }
  }

  String get _hint {
    switch (step) {
      case 0: return '예: 1995-02-15';
      case 1: return '예: 14:30';
      default: return '예: 서울특별시';
    }
  }

  TextInputType get _keyboardType {
    switch (step) {
      case 0:
      case 1:
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  TextEditingController get _controller {
    switch (step) {
      case 0: return dateCtrl;
      case 1: return timeCtrl;
      default: return placeCtrl;
    }
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
