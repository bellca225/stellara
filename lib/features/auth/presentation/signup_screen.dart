// lib/features/auth/presentation/signup_screen.dart
//
// 계정 만들기 화면. 디자이너 목업 기준.
// CSS/스타일은 디자인 담당자가 다듬을 예정. 로직과 구조만 구현.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input/app_input_formatters.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../data/login_id_repository.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

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
      final user = await AuthRepository().signUp(
        loginId: id,
        password: pw,
      );

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
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A1F), Color(0xFF08235F)],
              ),
            ),
          ),
          ...List.generate(40, (i) {
            final x = (i * 137.5) % 100;
            final y = (i * 97.3) % 100;
            final size = (i % 3 + 1).toDouble();
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // 아이콘
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A5FD4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  '계정 만들기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stellara에 오신 것을 환영합니다',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),

                const SizedBox(height: 40),

                // 입력 폼
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1830).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 아이디
                      const Text(
                        '아이디',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
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
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 비밀번호
                      const Text(
                        '비밀번호',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pwCtrl,
                        obscureText: _obscurePw,
                        onChanged: (_) {
                          if (_pwError != null) setState(() => _pwError = null);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('').copyWith(
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
                      const Text(
                        '비밀번호 확인',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _pwConfirmCtrl,
                        obscureText: _obscurePwConfirm,
                        onChanged: (_) {
                          if (_pwError != null) setState(() => _pwError = null);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePwConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white38,
                            ),
                            onPressed: () => setState(
                                () => _obscurePwConfirm = !_obscurePwConfirm),
                          ),
                        ),
                      ),
                      if (_pwError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _pwError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 12),
                        ),
                      ],

                      if (_generalError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _generalError!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 계정 만들기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A5FD4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '계정 만들기',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 이미 계정이 있으신가요?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '이미 계정이 있으신가요? ',
                      style: TextStyle(color: Colors.white54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
