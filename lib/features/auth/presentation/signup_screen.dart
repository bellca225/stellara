// lib/features/auth/presentation/signup_screen.dart
//
// 계정 만들기 화면 — Figma 회원가입(Screens 2/3/4) 기준
// 아이디 중복 확인 버튼 추가, 글래스모피즘 디자인 적용

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
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

const _glassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
];

// 중복 확인 결과
enum _IdCheckState { unchecked, checking, available, taken, formatError }

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

  _IdCheckState _idCheckState = _IdCheckState.unchecked;
  String _idCheckMessage = '';

  final _loginIdRepo = LoginIdRepository(FirebaseFirestore.instance);

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
    // ID 변경 시 확인 결과 초기화
    if (_idCheckState != _IdCheckState.unchecked) {
      setState(() => _idCheckState = _IdCheckState.unchecked);
    }
  }

  void _updatePasswordMatch([String? nextConfirm]) {
    final confirm = nextConfirm ?? _pwConfirmCtrl.text;
    final match = confirm.isEmpty ? null : confirm == _pwCtrl.text;
    if (_pwMatch != match) setState(() => _pwMatch = match);
  }

  // ── 아이디 중복 확인 ─────────────────────────────────────────────
  Future<void> _checkId() async {
    final id = _idCtrl.text.trim();

    final formatError = LoginIdRepository.validate(id);
    if (formatError != null) {
      setState(() {
        _idError = formatError;
        _idCheckState = _IdCheckState.formatError;
      });
      return;
    }

    setState(() {
      _idError = null;
      _idCheckState = _IdCheckState.checking;
    });

    try {
      final available = await _loginIdRepo.isAvailable(id);
      if (!mounted) return;
      setState(() {
        _idCheckState =
            available ? _IdCheckState.available : _IdCheckState.taken;
        _idCheckMessage =
            available ? '사용 가능한 아이디입니다.' : '사용 불가한 아이디입니다.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _idCheckState = _IdCheckState.unchecked);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('확인 중 오류가 발생했어요. 다시 시도해주세요.')),
        );
      }
    }
  }

  // ── 회원가입 처리 ────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _generalError = null);

    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    final pwConfirm = _pwConfirmCtrl.text;

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
      ref.read(currentUserProvider.notifier).state = user;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } on AuthError catch (e) {
      setState(() {
        if (e == AuthError.loginIdTaken) {
          _idError = e.message;
          _idCheckState = _IdCheckState.taken;
          _idCheckMessage = '사용 불가한 아이디입니다.';
        } else if (e == AuthError.weakPassword) {
          _pwError = e.message;
        } else {
          _generalError = e.message;
        }
      });
    } catch (e) {
      final msg = _friendlySignUpError(e);
      setState(() => _generalError = msg);
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
    if (kDebugMode) return '오류: $s';
    return '오류가 발생했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final guarded = buildAuthEntryGuard(context, ref);
    if (guarded != null) return guarded;

    final showCheckResult = _idCheckState == _IdCheckState.available ||
        _idCheckState == _IdCheckState.taken;

    return StarBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 113),

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
                          BoxShadow(
                            color: Color(0x4D3B82F6),
                            blurRadius: 10,
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

                    const SizedBox(height: 16),

                    // ── 타이틀 ──────────────────────────────────────
                    const Text(
                      '계정 만들기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Stellara에 오신 것을 환영합니다',
                      style: TextStyle(
                        color: Color(0xFF8EC5FF),
                        fontSize: 12,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── 입력 카드 ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0x1FFFFFFF),
                          width: 0.612,
                        ),
                        boxShadow: _glassBoxShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 아이디 레이블
                          _GlassFieldLabel('아이디'),
                          const SizedBox(height: 8),

                          // 아이디 입력 + 중복 확인 버튼
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _GlassInput(
                                  controller: _idCtrl,
                                  hintText: '아이디를 입력하세요.',
                                  keyboardType: TextInputType.emailAddress,
                                  textCapitalization: TextCapitalization.none,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  inputFormatters: [LoginIdTextFormatter()],
                                  onChanged: _onIdChanged,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 중복 확인 버튼
                              GestureDetector(
                                onTap: _idCheckState == _IdCheckState.checking
                                    ? null
                                    : _checkId,
                                child: Container(
                                  height: 49,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0x1AFFFFFF),
                                        Color(0x0DFFFFFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0x26FFFFFF),
                                      width: 0.612,
                                    ),
                                    boxShadow: _glassBoxShadow,
                                  ),
                                  child: Center(
                                    child:
                                        _idCheckState == _IdCheckState.checking
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            '중복 확인',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (_idError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _idError!,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 12,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // 비밀번호
                          _GlassFieldLabel('비밀번호'),
                          const SizedBox(height: 8),
                          _GlassInput(
                            controller: _pwCtrl,
                            hintText: '',
                            obscureText: _obscurePw,
                            suffixIcon: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                _obscurePw
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0x668EC5FF),
                                size: 20,
                              ),
                              onPressed: () {
                                if (_pwError != null) {
                                  setState(() => _pwError = null);
                                }
                                setState(() => _obscurePw = !_obscurePw);
                                _updatePasswordMatch();
                              },
                            ),
                            onChanged: (_) {
                              if (_pwError != null) {
                                setState(() => _pwError = null);
                              }
                              _updatePasswordMatch();
                            },
                          ),

                          const SizedBox(height: 20),

                          // 비밀번호 확인
                          _GlassFieldLabel('비밀번호 확인'),
                          const SizedBox(height: 8),
                          _GlassInput(
                            controller: _pwConfirmCtrl,
                            hintText: '',
                            obscureText: _obscurePwConfirm,
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_pwMatch != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      _pwMatch!
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded,
                                      color: _pwMatch!
                                          ? const Color(0xFF51A2FF)
                                          : const Color(0xFFFF5151),
                                      size: 20,
                                    ),
                                  ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    _obscurePwConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0x668EC5FF),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePwConfirm =
                                        !_obscurePwConfirm,
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (value) {
                              if (_pwError != null) {
                                setState(() => _pwError = null);
                              }
                              _updatePasswordMatch(value);
                            },
                            onSubmitted: (_) => _submit(),
                          ),

                          if (_pwError != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _pwError!,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 12,
                              ),
                            ),
                          ],

                          if (_generalError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _generalError!,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // 계정 만들기 버튼
                          _GlassPrimaryButton(
                            label: '계정 만들기',
                            isLoading: _isLoading,
                            onTap: _submit,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 이미 계정이 있으신가요?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '이미 계정이 있으신가요?  ',
                          style: TextStyle(
                            color: Color(0xFF8EC5FF),
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            '로그인',
                            style: TextStyle(
                              color: Color(0xFF51A2FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF51A2FF),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 바텀 토스트 공간 확보
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // ── 중복 확인 결과 바텀 토스트 ───────────────────────────
            if (showCheckResult)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF010512),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0x26FFFFFF),
                        width: 0.636,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x801E3A8A),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _idCheckState == _IdCheckState.available
                                  ? const [
                                      Color(0xFF51A2FF),
                                      Color(0xFF155DFC),
                                    ]
                                  : const [
                                      Color(0xFFFF5151),
                                      Color(0xFFFC1515),
                                    ],
                            ),
                          ),
                          child: Icon(
                            _idCheckState == _IdCheckState.available
                                ? Icons.check
                                : Icons.close,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _idCheckMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 공통 위젯 ──────────────────────────────────────────────────────────

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
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  const _GlassInput({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.suffixIcon,
    this.onSubmitted,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.612),
        boxShadow: _glassBoxShadow,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        inputFormatters: inputFormatters,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          letterSpacing: -0.2,
          height: 1.0,
        ),
        cursorColor: const Color(0xFF8EC5FF),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0x808EC5FF),
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: -0.2,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

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
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 61,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0x662B7FFF), Color(0x40155DFC)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x26FFFFFF), width: 0.612),
          boxShadow: _glassBoxShadow,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
