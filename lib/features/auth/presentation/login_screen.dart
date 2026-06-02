// lib/features/auth/presentation/login_screen.dart
//
// 로그인 화면. 디자이너 목업 기준.
// CSS/스타일은 디자인 담당자가 다듬을 예정.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../presentation/signup_screen.dart';
import '../../onboarding/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePw = true;
  String? _error;

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;

    if (id.isEmpty || pw.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthRepository().signInWithId(
        loginId: id,
        password: pw,
      );

      if (!mounted) return;
      ref.read(currentUserProvider.notifier).state = user;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.profileCompleted
              ? const AppShell()
              : const OnboardingScreen(),
        ),
      );
    } on AuthError catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = '오류가 발생했어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A0A1F), Color(0xFF08235F)],
              ),
            ),
          ),
          // 별 배경
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
          // 콘텐츠
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
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stellara에 다시 오신 것을 환영합니다',
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
                        const Text(
                          '아이디',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('아이디를 입력하세요.'),
                          onSubmitted: (_) => _login(),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          '비밀번호',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwCtrl,
                          obscureText: _obscurePw,
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
                          onSubmitted: (_) => _login(),
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              '비밀번호를 잊으셨나요?',
                              style: TextStyle(
                                color: Color(0xFF5B9BFF),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 8),

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
                            onPressed: _isLoading ? null : _login,
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
                                    '로그인',
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '계정이 없으신가요? ',
                        style: TextStyle(color: Colors.white54),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        child: const Text(
                          '계정 만들기',
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

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text(
                      '← 돌아가기',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
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
