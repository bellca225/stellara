import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/input/app_input_formatters.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import 'signup_screen.dart';
import '../../onboarding/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

const _svgLogin = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M19.9988 3.99976H25.3318C26.039 3.99976 26.7172 4.28069 27.2173 4.78076C27.7173 5.28082 27.9983 5.95906 27.9983 6.66626V25.3318C27.9983 26.039 27.7173 26.7172 27.2173 27.2173C26.7172 27.7173 26.039 27.9983 25.3318 27.9983H19.9988" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M13.3325 22.6652L19.9988 15.999L13.3325 9.33275" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M19.9988 15.999H3.99976" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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
                          color: const Color(0xFF2B7FFF).withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        _svgLogin,
                        width: 32,
                        height: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '로그인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stellarara에 다시 오신 것을 환영합니다',
                    style: TextStyle(color: Color(0xFF8EC5FF), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        _fieldLabel('아이디'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _idCtrl,
                          hint: '아이디를 입력하세요.',
                          onSubmitted: (_) => _login(),
                          inputFormatters: [LoginIdTextFormatter()],
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel('비밀번호'),
                        const SizedBox(height: 8),
                        _inputField(
                          controller: _pwCtrl,
                          hint: '',
                          obscure: _obscurePw,
                          onSubmitted: (_) => _login(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePw
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePw = !_obscurePw),
                          ),
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
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _login,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2B7FFF),
                                    Color(0xFF155DFC),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                  width: 0.636,
                                ),
                              ),
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
                                        '로그인',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '계정이 없으신가요? ',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => SignUpScreen()),
                        ),
                        child: const Text(
                          '계정 만들기',
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
                  const SizedBox(height: 8),
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

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF8EC5FF),
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x668EC5FF)),
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
          borderSide: const BorderSide(color: Color(0xFF2B7FFF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
