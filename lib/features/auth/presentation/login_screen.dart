// lib/features/auth/presentation/login_screen.dart
//
// 로그인 화면 — Figma 로그인(Screen 5) 기준
// 비밀번호 찾기/재설정 기능 제거됨 (서비스 범위 외)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import 'auth_entry_guard.dart';
import '../presentation/signup_screen.dart';
import '../../onboarding/app_shell.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

const _svgLogin = '''
<svg width="32" height="32" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M19.9988 3.99976H25.3318C26.039 3.99976 26.7172 4.28069 27.2173 4.78076C27.7173 5.28082 27.9983 5.95906 27.9983 6.66626V25.3318C27.9983 26.039 27.7173 26.7172 27.2173 27.2173C26.7172 27.7173 26.039 27.9983 25.3318 27.9983H19.9988" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M13.3325 22.6652L19.9988 15.999L13.3325 9.33275" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M19.9988 15.999H3.99976" stroke="white" stroke-width="2.6665" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _glassBoxShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x801E3A8A), blurRadius: 20, offset: Offset(0, 5)),
];

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
    final guarded = buildAuthEntryGuard(context, ref);
    if (guarded != null) return guarded;

    return StarBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 114),

                // ── 아이콘 ──────────────────────────────────────────
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
                    boxShadow: [
                      BoxShadow(color: const Color(0x4D3B82F6), blurRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.string(_svgLogin, width: 32, height: 32),
                  ),
                ),

                const SizedBox(height: 16),

                // ── 타이틀 ──────────────────────────────────────────
                const Text(
                  '로그인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stellarara에 다시 오신 것을 환영합니다',
                  style: TextStyle(
                    color: Color(0xFF8EC5FF),
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 32),

                // ── 입력 카드 ────────────────────────────────────────
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
                      // 아이디
                      _GlassFieldLabel('아이디'),
                      const SizedBox(height: 8),
                      _GlassInput(
                        controller: _idCtrl,
                        hintText: '아이디를 입력하세요.',
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [LoginIdTextFormatter()],
                        onSubmitted: (_) => _login(),
                      ),

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
                          onPressed: () =>
                              setState(() => _obscurePw = !_obscurePw),
                        ),
                        onSubmitted: (_) => _login(),
                      ),

                      // 에러 메시지
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 12,
                            letterSpacing: -0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 로그인 버튼
                      _GlassPrimaryButton(
                        label: '로그인',
                        isLoading: _isLoading,
                        onTap: _login,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 계정이 없으신가요?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '계정이 없으신가요?  ',
                      style: TextStyle(
                        color: Color(0xFF8EC5FF),
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      ),
                      child: const Text(
                        '계정 만들기',
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

                const SizedBox(height: 32),

                // 돌아가기
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: const Text(
                    '← 돌아가기',
                    style: TextStyle(
                      color: Color(0xB351A2FF),
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
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
    this.enabled = true,
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
  final bool enabled;

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
        enabled: enabled,
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
          filled: false,
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
    return GlassButton(
      label: label,
      isPrimary: true,
      isLoading: isLoading,
      onTap: onTap,
      height: 61,
    );
  }
}
