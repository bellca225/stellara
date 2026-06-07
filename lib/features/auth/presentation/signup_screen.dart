// lib/features/auth/presentation/signup_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/input/app_input_formatters.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
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

// 비밀번호 확인 - 색깔 있는 버전
const _svgCheckColor = '''
<svg width="57" height="50" viewBox="0 0 57 50" fill="none" xmlns="http://www.w3.org/2000/svg">
<g filter="url(#filter0_d_204_248)">
<circle cx="29" cy="25.0238" r="9" fill="url(#paint0_linear_204_248)"/>
</g>
<path d="M24.5001 25.315L27.6154 28.1738L33.5001 22.7738" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<filter id="filter0_d_204_248" x="0" y="-3.9762" width="58" height="58" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feFlood flood-opacity="0" result="BackgroundImageFix"/>
<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
<feOffset/><feGaussianBlur stdDeviation="10"/>
<feComposite in2="hardAlpha" operator="out"/>
<feColorMatrix type="matrix" values="0 0 0 0 0.231373 0 0 0 0 0.509804 0 0 0 0 0.964706 0 0 0 0.3 0"/>
<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_204_248"/>
<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_204_248" result="shape"/>
</filter>
<linearGradient id="paint0_linear_204_248" x1="20" y1="16.0238" x2="38" y2="34.0238" gradientUnits="userSpaceOnUse">
<stop stop-color="#51A2FF"/><stop offset="1" stop-color="#155DFC"/>
</linearGradient>
</defs>
</svg>
''';

const _svgCrossColor = '''
<svg width="58" height="58" viewBox="0 0 58 58" fill="none" xmlns="http://www.w3.org/2000/svg">
<g filter="url(#filter0_d_204_255)">
<circle cx="29" cy="29" r="9" fill="url(#paint0_linear_204_255)"/>
</g>
<path d="M32.5 32.5001L25.5002 25.5002" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M25.4999 32.5L32.4998 25.5001" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<defs>
<filter id="filter0_d_204_255" x="0" y="0" width="58" height="58" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">
<feFlood flood-opacity="0" result="BackgroundImageFix"/>
<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>
<feOffset/><feGaussianBlur stdDeviation="10"/>
<feComposite in2="hardAlpha" operator="out"/>
<feColorMatrix type="matrix" values="0 0 0 0 0.231373 0 0 0 0 0.509804 0 0 0 0 0.964706 0 0 0 0.3 0"/>
<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_204_255"/>
<feBlend mode="normal" in="SourceGraphic" in2="effect1_dropShadow_204_255" result="shape"/>
</filter>
<linearGradient id="paint0_linear_204_255" x1="20" y1="20" x2="38" y2="38" gradientUnits="userSpaceOnUse">
<stop stop-color="#FF5151"/><stop offset="1" stop-color="#FC1515"/>
</linearGradient>
</defs>
</svg>
''';

// 토스트 - 색깔 없는 흰색 버전
const _svgCheckWhite = '''
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="9" cy="9" r="9" fill="white"/>
<path d="M4.50006 9.29118L7.61545 12.15L13.5001 6.75" stroke="#010512" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

const _svgCrossWhite = '''
<svg width="18" height="18" viewBox="0 0 18 18" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="9" cy="9" r="9" fill="white"/>
<path d="M12.5 12.5001L5.50011 5.50016" stroke="#010512" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M5.49992 12.5L12.4998 5.50011" stroke="#010512" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

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

  void _onIdChanged(String value) {
    final error = LoginIdRepository.validate(value);
    if (_idError != error) setState(() => _idError = error);
    if (_idCheckState != _IdCheckState.unchecked) {
      setState(() => _idCheckState = _IdCheckState.unchecked);
    }
  }

  void _updatePasswordMatch([String? nextConfirm]) {
    final confirm = nextConfirm ?? _pwConfirmCtrl.text;
    final match = confirm.isEmpty ? null : confirm == _pwCtrl.text;
    if (_pwMatch != match) setState(() => _pwMatch = match);
  }

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
        _idCheckState = available
            ? _IdCheckState.available
            : _IdCheckState.taken;
        _idCheckMessage = available ? '사용 가능한 아이디입니다.' : '사용 불가한 아이디입니다.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _idCheckState = _IdCheckState.unchecked);
        showGlassToast(context, '확인 중 오류가 발생했어요. 다시 시도해주세요.', type: GlassToastType.error);
      }
    }
  }

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
      setState(() => _generalError = _friendlySignUpError(e));
      debugPrint('[SignUp] 회원가입 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlySignUpError(Object e) {
    final s = e.toString();
    if (s.contains('friend-code-conflict')) return '일시적인 오류가 발생했어요. 다시 시도해주세요.';
    if (s.contains('PERMISSION_DENIED') || s.contains('permission-denied'))
      return '서버 권한 오류예요. 잠시 후 다시 시도해주세요.';
    if (s.contains('email-already-in-use') || s.contains('already-exists'))
      return '이미 사용 중인 아이디예요.';
    if (s.contains('network') || s.contains('UNAVAILABLE'))
      return '네트워크 연결을 확인해주세요.';
    if (s.contains('requires-recent-login'))
      return '로그인 세션이 만료됐어요. 앱을 재시작해주세요.';
    if (kDebugMode) return '오류: $s';
    return '오류가 발생했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final guarded = buildAuthEntryGuard(context, ref);
    if (guarded != null) return guarded;

    final showCheckResult =
        _idCheckState == _IdCheckState.available ||
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
                      child: Center(
                        child: SvgPicture.string(
                          _svgPersonAdd,
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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

                    GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _GlassFieldLabel('아이디'),
                          const SizedBox(height: 8),
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
                              GestureDetector(
                                onTap: _idCheckState == _IdCheckState.checking
                                    ? null
                                    : _checkId,
                                child: GlassField(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Center(
                                      child:
                                          _idCheckState ==
                                              _IdCheckState.checking
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

                          _GlassFieldLabel('비밀번호'),
                          const SizedBox(height: 8),
                          _GlassInput(
                            controller: _pwCtrl,
                            hintText: '',
                            obscureText: _obscurePw,
                            suffixIcon: GestureDetector(
                              onTap: () {
                                if (_pwError != null)
                                  setState(() => _pwError = null);
                                setState(() => _obscurePw = !_obscurePw);
                                _updatePasswordMatch();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Icon(
                                  _obscurePw
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0x668EC5FF),
                                  size: 20,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_pwError != null)
                                setState(() => _pwError = null);
                              _updatePasswordMatch();
                            },
                          ),

                          const SizedBox(height: 20),

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
                                    padding: const EdgeInsets.only(right: 3),
                                    child: SvgPicture.string(
                                      _pwMatch!
                                          ? _svgCheckColor
                                          : _svgCrossColor,
                                      width: 45,
                                      height: 45,
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () =>
                                        _obscurePwConfirm = !_obscurePwConfirm,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      _obscurePwConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0x668EC5FF),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            onChanged: (value) {
                              if (_pwError != null)
                                setState(() => _pwError = null);
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

                          _GlassPrimaryButton(
                            label: '계정 만들기',
                            isLoading: _isLoading,
                            onTap: _submit,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

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

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

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
                        SvgPicture.string(
                          _idCheckState == _IdCheckState.available
                              ? _svgCheckWhite
                              : _svgCrossWhite,
                          width: 20,
                          height: 20,
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
    return GlassField(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: -0.2,
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
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            isDense: true,
          ),
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
