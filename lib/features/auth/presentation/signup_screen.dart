// lib/features/auth/presentation/signup_screen.dart
//
// 계정 만들기 화면. 디자이너 목업 기준.
// CSS/스타일은 디자인 담당자가 다듬을 예정. 로직과 구조만 구현.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/input/app_input_formatters.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../data/login_id_repository.dart';
import 'auth_entry_guard.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

const _svgPersonAdd = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21.332 27.9982V25.3317C21.332 23.9173 20.7701 22.5609 19.77 21.5607C18.7699 20.5606 17.4134 19.9987 15.999 19.9987H7.9995C6.5851 19.9987 5.22864 20.5606 4.2285 21.5607C3.22837 22.5609 2.6665 23.9173 2.6665 25.3317V27.9982" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M11.9993 14.6658C14.9446 14.6658 17.3323 12.2781 17.3323 9.33276C17.3323 6.38742 14.9446 3.99976 11.9993 3.99976C9.05393 3.99976 6.66626 6.38742 6.66626 9.33276C6.66626 12.2781 9.05393 14.6658 11.9993 14.6658Z" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M25.3317 10.666V18.6655" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M29.3315 14.6658H21.332" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgCheck = '''
<svg width="57" height="50" viewBox="0 0 57 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<g filter="url(#filter0_d_212_47)">
<circle cx="29" cy="25.0238" r="9" fill="url(#paint0_linear_212_47)"/>
</g>
<path d="M24.5001 25.315L27.6154 28.1738L33.5001 22.7738" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<filter id="filter0_d_212_47" x="0" y="-3.9762" width="58" height="58" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feFlood flood-opacity="0" result="BackgroundImageFix"/>
<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
<feOffset/>
<feGaussianBlur stdDeviation="10"/>
<feComposite in2="hardAlpha" operator="out"/>
<feColorMatrix type="matrix" values="0 0 0 0 0.231373 0 0 0 0 0.509804 0 0 0 0 0.964706 0 0 0 0.3 0"/>
<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_212_47"/>
<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_212_47" result="shape"/>
</filter>
<linearGradient id="paint0_linear_212_47" x1="20" y1="16.0238" x2="38" y2="34.0238" gradientUnits="userSpaceOnUse">
<stop stop-color="#51A2FF"/>
<stop offset="1" stop-color="#155DFC"/>
</linearGradient>
</defs>
</svg>
''';

const _svgX = '''
<svg width="58" height="58" viewBox="0 0 58 58" fill="none" xmlns="http://www.w3.org/2000/svg">
<g filter="url(#filter0_d_214_59)">
<circle cx="29" cy="29" r="9" fill="url(#paint0_linear_214_59)"/>
</g>
<path d="M32.5 32.5001L25.5002 25.5002" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M25.4999 32.5L32.4998 25.5001" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<filter id="filter0_d_214_59" x="0" y="0" width="58" height="58" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feFlood flood-opacity="0" result="BackgroundImageFix"/>
<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
<feOffset/>
<feGaussianBlur stdDeviation="10"/>
<feComposite in2="hardAlpha" operator="out"/>
<feColorMatrix type="matrix" values="0 0 0 0 0.231373 0 0 0 0 0.509804 0 0 0 0 0.964706 0 0 0 0.3 0"/>
<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_214_59"/>
<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_214_59" result="shape"/>
</filter>
<linearGradient id="paint0_linear_214_59" x1="20" y1="20" x2="38" y2="38" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF5151"/>
<stop offset="1" stop-color="#FC1515"/>
</linearGradient>
</defs>
</svg>
''';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePw = true;
  bool _obscurePwConfirm = true;
  String? _idError;
  String? _pwError;
  String? _generalError;
  bool? _pwMatch;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  // ── 아이디 실시간 검증 ───────────────────────────────────────────
  void _onIdChanged(String value) {
    final error = LoginIdRepository.validate(value);
    if (_idError != error) setState(() => _idError = error);
  }

  void _updatePasswordMatch([String? nextConfirm]) {
    final confirm = nextConfirm ?? _pwConfirmCtrl.text;
    final match = confirm.isEmpty ? null : confirm == _pwCtrl.text;
    if (_pwMatch != match) {
      setState(() => _pwMatch = match);
    }
  }

  // ── 회원가입 처리 ────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _generalError = null);

    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pwConfirm = _pwConfirmCtrl.text;

    // 클라이언트 검증
    final idValidation = LoginIdRepository.validate(id);
    if (idValidation != null) {
      setState(() => _idError = idValidation);
      return;
    }
    if (pw.length < 6) {
      setState(() => _pwError = '비밀번호는 6자 이상이어야 해요.');
      return;
    }
    if (pw != pwConfirm) {
      setState(() => _pwError = '비밀번호가 일치하지 않아요.');
      return;
    }
    setState(() {
      _idError = null;
      _pwError = null;
    });

    setState(() => _isLoading = true);
    try {
      final user = await AuthRepository().signUp(loginId: id, password: pw);

      if (!mounted) return;
      // Provider 에 세션 저장
      ref.read(currentUserProvider.notifier).state = user;

      // 온보딩으로 이동 (회원가입 직후 출생 정보 입력)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } on AuthError catch (e) {
      setState(() {
        if (e == AuthError.loginIdTaken) {
          _idError = e.message;
        } else if (e == AuthError.weakPassword) {
          _pwError = e.message;
        } else {
          _generalError = e.message;
        }
      });
    } catch (e) {
      final msg = _friendlySignUpError(e);
      setState(() => _generalError = msg);
      // ignore: avoid_print
      debugPrint('[SignUp] 회원가입 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignUpError(Object e) {
    final s = e.toString();
    if (s.contains('friend-code-conflict')) {
      return '일시적인 오류가 발생했어요. 다시 시도해주세요.';
    }
    if (s.contains('PERMISSION_DENIED') || s.contains('permission-denied')) {
      return '서버 권한 오류예요. 잠시 후 다시 시도해주세요.';
    }
    if (s.contains('email-already-in-use') || s.contains('already-exists')) {
      return '이미 사용 중인 아이디예요.';
    }
    if (s.contains('network') || s.contains('UNAVAILABLE')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (s.contains('requires-recent-login')) {
      return '로그인 세션이 만료됐어요. 앱을 재시작해주세요.';
    }
    // 디버그에서만 실제 에러 노출
    if (kDebugMode) return '오류: $s';
    return '오류가 발생했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final guarded = buildAuthEntryGuard(context, ref);
    if (guarded != null) return guarded;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF060618),
                  Color(0xFF0A0F2E),
                  Color(0xFF0D1F5C),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // 아이콘
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2B7FFF), Color(0xFF155DFC)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B7FFF).withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        _svgPersonAdd,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    '계정 만들기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stellara에 오신 것을 환영합니다',
                    style: TextStyle(color: Color(0xFF8EC5FF), fontSize: 14),
                  ),

                  const SizedBox(height: 32),

                  // 입력 폼
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x22FFFFFF), Color(0x11FFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 아이디
                        _fieldLabel('아이디'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idCtrl,
                          onChanged: _onIdChanged,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          enableSuggestions: false,
                          inputFormatters: <TextInputFormatter>[
                            LoginIdTextFormatter(),
                          ],
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('아이디를 입력하세요.'),
                        ),
                        if (_idError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _idError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // 비밀번호
                        _fieldLabel('비밀번호'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: _obscurePw,
                          onChanged: (_) {
                            if (_pwError != null) {
                              setState(() => _pwError = null);
                            }
                            _updatePasswordMatch();
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('').copyWith(
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePw
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white38,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePw = !_obscurePw),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 비밀번호 확인
                        _fieldLabel('비밀번호 확인'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwConfirmCtrl,
                          obscureText: _obscurePwConfirm,
                          onChanged: (value) {
                            if (_pwError != null) {
                              setState(() => _pwError = null);
                            }
                            _updatePasswordMatch(value);
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('').copyWith(
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_pwMatch != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: SvgPicture.string(
                                      _pwMatch! ? _svgCheck : _svgX,
                                      width: 36,
                                      height: 36,
                                    ),
                                  ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePwConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white38,
                                  ),
                                  onPressed: () => setState(
                                    () =>
                                        _obscurePwConfirm = !_obscurePwConfirm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_pwError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _pwError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        if (_generalError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _generalError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 20),

                        // 계정 만들기 버튼
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Opacity(
                            opacity: _isLoading ? 0.85 : 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2B7FFF),
                                    Color(0xFF155DFC),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 0.636,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: _isLoading ? null : _submit,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            '계정 만들기',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 이미 계정이 있으신가요?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '이미 계정이 있으신가요? ',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          '로그인',
                          style: TextStyle(
                            color: Color(0xFF5B9BFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF5B9BFF),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF8EC5FF),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0x668EC5FF)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
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
        borderSide: const BorderSide(color: Color(0xFF2B7FFF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
