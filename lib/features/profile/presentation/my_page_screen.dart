import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/ui/app_toast.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/data/kr_regions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/glass_pickers.dart';
import '../../../core/widgets/region_picker.dart';
import '../../../core/utils/astro_text.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/landing_screen.dart';
import '../../friends/application/friend_providers.dart';
import '../../horoscope/application/horoscope_providers.dart';
import '../../users/application/user_providers.dart';
import '../../users/domain/user_profile.dart';

class _C {
  static const white = Color(0xFFFFFFFF);
  static const whiteDim = Color(0x99FFFFFF);
  static const accent = Color(0xFF8EC5FF);
  static const cardBorder = Color(0x1FFFFFFF);
  static const divider = Color(0x0DFFFFFF);
  static const pillBorder = Color(0x26FFFFFF);
  static const overlay = Color(0x99000000);
  static const inputHint = Color(0x668EC5FF);
  static const error = Color(0xFFFF8A8A);
  static const saveStart = Color(0x662B7FFF);
  static const saveEnd = Color(0x40155DFC);
  static const avatarStart = Color(0xFF51A2FF);
  static const avatarEnd = Color(0xFF155DFC);
}

// 표준 글라스 그림자(검정 2단)로 통일. 파란 글로우 제거.
const _glassBoxShadow = kGlassShadow;

class _UiMessageException implements Exception {
  const _UiMessageException(this.message);

  final String message;
}

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  Future<void> _showMessage(String message) async {
    showGlassToast(context, message);
  }

  String _displayNameOf(UserProfile? profile, BirthInfo? birth) {
    final profileName = profile?.effectiveDisplayName.trim() ?? '';
    if (profileName.isNotEmpty) {
      return profileName;
    }
    final userName =
        ref.read(currentUserProvider)?.effectiveDisplayName.trim() ?? '';
    if (userName.isNotEmpty) {
      return userName;
    }
    final birthName = birth?.nickname.trim() ?? '';
    if (birthName.isNotEmpty) {
      return birthName;
    }
    return '익명의 행성';
  }

  Future<void> _waitForProfileSync(
    bool Function(UserProfile? profile) predicate,
  ) async {
    final uid =
        ref.read(currentUserProvider)?.uid ??
        ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) {
      return;
    }
    try {
      await ref
          .read(userRepositoryProvider)
          .watch(uid)
          .firstWhere(predicate)
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Firestore stream 동기화가 지연돼도 UX를 막지는 않는다.
    }
  }

  Future<void> _persistProfile({
    required BirthInfo birthInfo,
    required String displayName,
  }) async {
    final trimmedName = displayName.trim();
    final currentUser = ref.read(currentUserProvider);
    final uid = currentUser?.uid ?? ref.read(currentUserIdProvider).valueOrNull;
    if (uid == null) {
      throw const _UiMessageException('로그인 정보를 찾을 수 없어요. 다시 로그인해주세요.');
    }

    await ref
        .read(userRepositoryProvider)
        .upsertBirthInfo(
          uid: uid,
          birthInfo: birthInfo,
          nickname: trimmedName,
          displayName: trimmedName,
        );

    if (currentUser != null) {
      ref.read(currentUserProvider.notifier).state = currentUser.copyWith(
        displayName: trimmedName,
        nickname: trimmedName,
        profileCompleted: true,
      );
    }

    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(currentBirthInfoProvider);
    ref.invalidate(myNatalChartProvider);
    ref.invalidate(todayHoroscopeProvider);
  }

  Future<void> _saveDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const _UiMessageException('닉네임을 입력해주세요.');
    }
    if (trimmed.length > 20) {
      throw const _UiMessageException('닉네임은 20자 이내로 입력해주세요.');
    }

    final currentBirth = ref.read(currentBirthInfoProvider);
    if (currentBirth == null) {
      throw const _UiMessageException('출생 정보가 없어 닉네임을 저장할 수 없어요.');
    }

    final updatedBirth = currentBirth.copyWith(nickname: trimmed);
    await _persistProfile(birthInfo: updatedBirth, displayName: trimmed);
    await _waitForProfileSync(
      (profile) =>
          profile?.effectiveDisplayName == trimmed &&
          profile?.birthInfo?.nickname == trimmed,
    );
    await _showMessage('닉네임이 수정되었습니다.');
  }

  Future<void> _saveBirthInfo(BirthInfo birthInfo) async {
    final displayName = _displayNameOf(
      ref.read(currentUserProfileProvider).valueOrNull,
      birthInfo,
    );
    await _persistProfile(birthInfo: birthInfo, displayName: displayName);
    await _waitForProfileSync(
      (profile) =>
          profile?.birthInfo?.chartVersion == birthInfo.chartVersion &&
          profile?.birthInfo?.placeName == birthInfo.placeName,
    );
    await _showMessage('출생 정보가 수정되었습니다.');
  }

  Future<void> _copyFriendCode(String friendCode) async {
    if (friendCode.isEmpty) {
      await _showMessage('친구 코드가 아직 없어요. 친구 관리에서 생성해주세요.');
      return;
    }
    try {
      await Clipboard.setData(ClipboardData(text: friendCode));
      await _showMessage('친구 코드가 복사되었습니다.');
    } catch (_) {
      await _showMessage('클립보드에 복사하지 못했어요. 다시 시도해주세요.');
    }
  }

  Future<void> _openNicknameDialog(String displayName) async {
    await _showGlassDialog(
      _EditNicknameDialog(initialValue: displayName, onSave: _saveDisplayName),
    );
  }

  Future<void> _openBirthInfoDialog(
    BirthInfo? birthInfo,
    String displayName,
  ) async {
    await _showGlassDialog(
      _EditBirthInfoDialog(
        initialBirthInfo: birthInfo,
        displayName: displayName,
        onSave: _saveBirthInfo,
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(currentUserProvider.notifier).state = null;
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(currentBirthInfoProvider);
    ref.invalidate(myNatalChartProvider);
    ref.invalidate(todayHoroscopeProvider);
    ref.invalidate(friendListProvider);
    ref.invalidate(receivedRequestsProvider);
    ref.invalidate(sentRequestsProvider);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  Future<T?> _showGlassDialog<T>(Widget child) {
    return showGeneralDialog<T>(
      context: context,
      // barrierDismissible을 false로 하고 backdrop GestureDetector에서
      // unfocus → pop 순서를 보장한다.
      // barrierDismissible: true이면 Flutter 내부에서 unfocus 없이
      // Navigator.pop()을 호출해 IME assertion을 유발할 수 있다.
      barrierDismissible: false,
      barrierLabel: 'close',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final bottomInset = MediaQuery.of(dialogContext).viewInsets.bottom;
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 배경 블러 + 탭 시 unfocus 후 닫기
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    FocusScope.of(dialogContext).unfocus();
                    Navigator.of(dialogContext).pop();
                  },
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                    child: Container(color: _C.overlay),
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
                    // 다이얼로그 카드 위의 탭은 배경 GestureDetector로 전파되지 않게 흡수
                    child: Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: SingleChildScrollView(child: child),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  String _dateText(BirthInfo? birth) {
    if (birth == null) {
      return '-';
    }
    return '${birth.dateTime.year}-${_pad(birth.dateTime.month)}-${_pad(birth.dateTime.day)}';
  }

  String _timeText(BirthInfo? birth) {
    if (birth == null) {
      return '-';
    }
    return '${_pad(birth.dateTime.hour)}:${_pad(birth.dateTime.minute)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final birth = ref.watch(currentBirthInfoProvider);
    final asyncChart = ref.watch(myNatalChartProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    final displayName = _displayNameOf(profile, birth);
    final friendCode = (profile?.friendCode ?? user?.friendCode ?? '').trim();
    final profileSunSign = profile?.sunSign;
    final signLabel = asyncChart.when(
      data: (chart) => zodiacLabelKo(chart.sunSign),
      loading: () =>
          profileSunSign != null ? zodiacLabelKo(profileSunSign) : '',
      error: (error, stackTrace) =>
          profileSunSign != null ? zodiacLabelKo(profileSunSign) : '',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 156),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                displayName: displayName,
                signLabel: signLabel,
                initial: firstLetter(displayName, fallback: '별'),
                onEdit: () => _openNicknameDialog(displayName),
              ),
              const SizedBox(height: 24),
              _GlassSurface(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '내 친구 코드',
                            style: TextStyle(
                              color: _C.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.43,
                              letterSpacing: -0.2,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            friendCode.isNotEmpty ? friendCode : '—',
                            style: GoogleFonts.sulphurPoint(
                              color: _C.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                              height: 1.28,
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '친구에게 이 코드를 공유하세요',
                            style: TextStyle(
                              color: Color(0xB38EC5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.33,
                              letterSpacing: -0.2,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    _GlassIconButton(
                      tooltip: '친구 코드 복사',
                      onTap: () => _copyFriendCode(friendCode),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _CopyIconPainter()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    '출생 정보',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.2,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const Spacer(),
                  _GlassPillAction(
                    label: '수정',
                    labelColor: _C.accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 9,
                    ),
                    onTap: () => _openBirthInfoDialog(birth, displayName),
                    leading: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CustomPaint(painter: _EditIconPainter()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GlassSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    _BirthRow(
                      iconPainter: _CalendarIconPainter(),
                      label: '생년월일',
                      value: _dateText(birth),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: _C.divider, height: 1),
                    ),
                    _BirthRow(
                      iconPainter: _ClockIconPainter(),
                      label: '출생 시간',
                      value: _timeText(birth),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: _C.divider, height: 1),
                    ),
                    _BirthRow(
                      iconPainter: _PinIconPainter(),
                      label: '출생지',
                      value: birth?.placeName?.trim().isNotEmpty == true
                          ? birth!.placeName!.trim()
                          : '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _GlassPillButton(
                label: '로그아웃',
                onTap: _logout,
                leading: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _LogoutIconPainter()),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.signLabel,
    required this.initial,
    required this.onEdit,
  });

  final String displayName;
  final String signLabel;
  final String initial;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 아바타 뒤 부드러운 글로우.
          // (BackdropFilter는 웹에서 클립이 안 먹어 배경 별빛을 뭉개므로
          //  RadialGradient 글로우로 대체)
          Positioned(
            top: 24,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x402B7FFF), Color(0x00000000)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_C.avatarStart, _C.avatarEnd],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D3B82F6),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1AFFFFFF), Color(0x00000000)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: -0.2,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _C.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                          letterSpacing: -0.2,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassIconButton(
                      size: 33.256,
                      radius: 28,
                      tooltip: '닉네임 수정',
                      onTap: onEdit,
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CustomPaint(painter: _EditHeaderIconPainter()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  signLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: -0.2,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // 표준 글라스 패턴(다른 화면의 GlassPanel과 동일): 블러/컬러 글로우 없이
    // 어두운 글라스 채움 + 옅은 테두리 + 표준 그림자.
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 0.612),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: child,
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.onTap,
    required this.child,
    required this.tooltip,
    this.size = 45.26,
    this.radius = 16,
  });

  final VoidCallback onTap;
  final Widget child;
  final String tooltip;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _C.pillBorder, width: 0.636),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
            ),
            boxShadow: _glassBoxShadow,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _GlassPillAction extends StatelessWidget {
  const _GlassPillAction({
    required this.label,
    required this.onTap,
    this.leading,
    this.labelColor = _C.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final Color labelColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: _C.pillBorder, width: 0.636),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
          ),
          boxShadow: _glassBoxShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 5)],
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.43,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPillButton extends StatelessWidget {
  const _GlassPillButton({
    required this.label,
    required this.onTap,
    this.leading,
    this.filled = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final bool filled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      label: label,
      isPrimary: filled,
      isLoading: isLoading,
      leading: leading,
      onTap: onTap,
      height: 62,
      fontWeight: FontWeight.w600,
    );
  }
}

class _BirthRow extends StatelessWidget {
  const _BirthRow({
    required this.iconPainter,
    required this.label,
    required this.value,
  });

  final CustomPainter iconPainter;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CustomPaint(painter: iconPainter),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: _C.accent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.43,
            letterSpacing: -0.2,
            fontFamily: 'Pretendard',
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogCard extends StatelessWidget {
  const _DialogCard({
    required this.title,
    required this.child,
    required this.onClose,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 345),
      child: _GlassSurface(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _C.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.2,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                _GlassIconButton(
                  size: 38,
                  radius: 9999,
                  tooltip: '닫기',
                  onTap: onClose ?? () {},
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFBEDBFF),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: -0.2,
        fontFamily: 'Pretendard',
      ),
    );
  }
}

class _GlassFieldShell extends StatelessWidget {
  const _GlassFieldShell({required this.child, this.hasError = false});

  final Widget child;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? _C.error : _C.cardBorder;
    return Container(
      height: 49,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.636),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        boxShadow: _glassBoxShadow,
      ),
      child: child,
    );
  }
}

class _DisplayInput extends StatelessWidget {
  const _DisplayInput({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.hasError = false,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final text = value?.trim() ?? '';
    final showPlaceholder = text.isEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _GlassFieldShell(
        hasError: hasError,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Text(
            showPlaceholder ? placeholder : text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: showPlaceholder ? _C.inputHint : _C.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }
}

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({required this.initialValue, required this.onSave});

  final String initialValue;
  final Future<void> Function(String value) onSave;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '닉네임을 입력해주세요.');
      return;
    }
    if (value.length > 20) {
      setState(() => _error = '닉네임은 20자 이내로 입력해주세요.');
      return;
    }
    if (value == widget.initialValue.trim()) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(value);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on _UiMessageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '닉네임을 저장하지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      title: '닉네임 수정',
      onClose: _isSaving
          ? null
          : () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('새 닉네임'),
          const SizedBox(height: 8),
          _GlassFieldShell(
            hasError: _error != null,
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              enabled: !_isSaving,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: _C.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
              cursorColor: _C.accent,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 14,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: _C.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassPillButton(
                  label: '취소',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassPillButton(
                  label: '저장',
                  filled: true,
                  isLoading: _isSaving,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBirthInfoDialog extends StatefulWidget {
  const _EditBirthInfoDialog({
    required this.initialBirthInfo,
    required this.displayName,
    required this.onSave,
  });

  final BirthInfo? initialBirthInfo;
  final String displayName;
  final Future<void> Function(BirthInfo birthInfo) onSave;

  @override
  State<_EditBirthInfoDialog> createState() => _EditBirthInfoDialogState();
}

class _EditBirthInfoDialogState extends State<_EditBirthInfoDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  KrRegion? _selectedRegion;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final birth = widget.initialBirthInfo;
    if (birth != null) {
      _selectedDate = DateTime(
        birth.dateTime.year,
        birth.dateTime.month,
        birth.dateTime.day,
      );
      _selectedTime = TimeOfDay(
        hour: birth.dateTime.hour,
        minute: birth.dateTime.minute,
      );
    }
    _selectedRegion = findKrRegionByName(birth?.placeName);
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

  Future<void> _pickDate() async {
    final picked = await showGlassDatePicker(
      context,
      initialDate: _selectedDate ?? DateTime(2002, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showGlassTimePicker(
      context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _error = null;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      setState(() => _error = '생년월일을 선택해주세요.');
      return;
    }
    if (_selectedTime == null) {
      setState(() => _error = '출생 시간을 선택해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final region = _selectedRegion;
      if (region == null) {
        throw const _UiMessageException('출생지를 선택해주세요.');
      }
      final double latitude = region.latitude;
      final double longitude = region.longitude;
      final String placeName = region.name;

      final birthInfo = BirthInfo(
        nickname: widget.displayName,
        dateTime: dt,
        latitude: latitude,
        longitude: longitude,
        utcOffset: widget.initialBirthInfo?.utcOffset ?? '+09:00',
        placeName: placeName,
      );

      final initial = widget.initialBirthInfo;
      final isSameAsInitial =
          initial != null &&
          initial.dateTime == birthInfo.dateTime &&
          initial.latitude == birthInfo.latitude &&
          initial.longitude == birthInfo.longitude &&
          initial.utcOffset == birthInfo.utcOffset &&
          (initial.placeName ?? '') == (birthInfo.placeName ?? '') &&
          initial.nickname == birthInfo.nickname;
      if (isSameAsInitial) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(false);
        return;
      }

      await widget.onSave(birthInfo);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on _UiMessageException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '출생 정보를 저장하지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _dateText() {
    final date = _selectedDate;
    if (date == null) {
      return '';
    }
    return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
  }

  String _timeText() {
    final time = _selectedTime;
    if (time == null) {
      return '';
    }
    return '${_pad(time.hour)}:${_pad(time.minute)}';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return _DialogCard(
      title: '출생 정보 수정',
      onClose: _isSaving
          ? null
          : () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('생년월일'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _dateText(),
            placeholder: '생년월일을 선택해주세요',
            onTap: _pickDate,
            hasError: _error == '생년월일을 선택해주세요.',
          ),
          const SizedBox(height: 20),
          const _FieldLabel('출생 시간'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _timeText(),
            placeholder: '출생 시간을 선택해주세요',
            onTap: _pickTime,
            hasError: _error == '출생 시간을 선택해주세요.',
          ),
          const SizedBox(height: 20),
          const _FieldLabel('출생지'),
          const SizedBox(height: 8),
          _DisplayInput(
            value: _selectedRegion?.name,
            placeholder: '출생지를 선택해주세요',
            onTap: _isSaving ? () {} : _pickRegion,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: _C.error,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.33,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _GlassPillButton(
                  label: '취소',
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop(false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlassPillButton(
                  label: '저장',
                  filled: true,
                  isLoading: _isSaving,
                  onTap: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditIconPainter extends CustomPainter {
  const _EditIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = Path()
      ..moveTo(8.0 * r, 2.0 * r)
      ..lineTo(3.332 * r, 2.0 * r)
      ..cubicTo(2.963 * r, 2.0 * r, 2.609 * r, 2.14 * r, 2.389 * r, 2.389 * r)
      ..cubicTo(
        2.139 * r,
        2.639 * r,
        1.999 * r,
        2.978 * r,
        1.999 * r,
        3.332 * r,
      )
      ..lineTo(1.999 * r, 12.66 * r)
      ..cubicTo(
        1.999 * r,
        13.014 * r,
        2.139 * r,
        13.353 * r,
        2.389 * r,
        13.602 * r,
      )
      ..cubicTo(
        2.639 * r,
        13.852 * r,
        2.978 * r,
        13.993 * r,
        3.332 * r,
        13.993 * r,
      )
      ..lineTo(12.66 * r, 13.993 * r)
      ..cubicTo(
        13.014 * r,
        13.993 * r,
        13.353 * r,
        13.852 * r,
        13.602 * r,
        13.602 * r,
      )
      ..cubicTo(
        13.852 * r,
        13.353 * r,
        13.993 * r,
        13.014 * r,
        13.993 * r,
        12.66 * r,
      )
      ..lineTo(13.993 * r, 7.996 * r);
    canvas.drawPath(rect, p);
    canvas.drawLine(
      Offset(12.244 * r, 1.749 * r),
      Offset(14.243 * r, 3.748 * r),
      p,
    );
    final pencil = Path()
      ..moveTo(12.244 * r, 1.749 * r)
      ..cubicTo(
        12.509 * r,
        1.484 * r,
        12.868 * r,
        1.335 * r,
        13.243 * r,
        1.335 * r,
      )
      ..cubicTo(
        13.618 * r,
        1.335 * r,
        13.977 * r,
        1.484 * r,
        14.243 * r,
        1.749 * r,
      )
      ..cubicTo(
        14.508 * r,
        2.014 * r,
        14.657 * r,
        2.374 * r,
        14.657 * r,
        2.748 * r,
      )
      ..cubicTo(
        14.657 * r,
        3.123 * r,
        14.508 * r,
        3.483 * r,
        14.243 * r,
        3.748 * r,
      )
      ..lineTo(8.237 * r, 9.754 * r)
      ..cubicTo(
        8.079 * r,
        9.912 * r,
        7.883 * r,
        10.028 * r,
        7.669 * r,
        10.091 * r,
      )
      ..lineTo(5.754 * r, 10.65 * r)
      ..cubicTo(
        5.697 * r,
        10.667 * r,
        5.636 * r,
        10.668 * r,
        5.578 * r,
        10.653 * r,
      )
      ..cubicTo(
        5.521 * r,
        10.638 * r,
        5.468 * r,
        10.608 * r,
        5.425 * r,
        10.566 * r,
      )
      ..cubicTo(
        5.383 * r,
        10.524 * r,
        5.353 * r,
        10.471 * r,
        5.338 * r,
        10.413 * r,
      )
      ..cubicTo(
        5.323 * r,
        10.355 * r,
        5.324 * r,
        10.295 * r,
        5.341 * r,
        10.237 * r,
      )
      ..lineTo(5.901 * r, 8.323 * r)
      ..cubicTo(5.964 * r, 8.108 * r, 6.08 * r, 7.913 * r, 6.238 * r, 7.755 * r)
      ..lineTo(12.244 * r, 1.749 * r)
      ..close();
    canvas.drawPath(pencil, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditHeaderIconPainter extends _EditIconPainter {
  const _EditHeaderIconPainter();
}

class _CopyIconPainter extends CustomPainter {
  const _CopyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final front = Path()
      ..addRRect(
        RRect.fromLTRBR(
          6.667 * r,
          6.667 * r,
          18.333 * r,
          18.333 * r,
          Radius.circular(1.667 * r),
        ),
      );
    canvas.drawPath(front, p);
    final back = Path()
      ..moveTo(13.333 * r, 6.667 * r)
      ..lineTo(13.333 * r, 3.333 * r)
      ..cubicTo(
        13.333 * r,
        2.413 * r,
        12.583 * r,
        1.667 * r,
        11.666 * r,
        1.667 * r,
      )
      ..lineTo(3.333 * r, 1.667 * r)
      ..cubicTo(
        2.416 * r,
        1.667 * r,
        1.667 * r,
        2.413 * r,
        1.667 * r,
        3.333 * r,
      )
      ..lineTo(1.667 * r, 11.666 * r)
      ..cubicTo(
        1.667 * r,
        12.583 * r,
        2.416 * r,
        13.333 * r,
        3.333 * r,
        13.333 * r,
      )
      ..lineTo(6.667 * r, 13.333 * r);
    canvas.drawPath(back, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalendarIconPainter extends CustomPainter {
  const _CalendarIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(
      Offset(5.331 * r, 1.333 * r),
      Offset(5.331 * r, 3.998 * r),
      p,
    );
    canvas.drawLine(
      Offset(10.661 * r, 1.333 * r),
      Offset(10.661 * r, 3.998 * r),
      p,
    );
    final rect = Path()
      ..addRRect(
        RRect.fromLTRBR(
          1.999 * r,
          2.666 * r,
          13.993 * r,
          14.659 * r,
          Radius.circular(1.333 * r),
        ),
      );
    canvas.drawPath(rect, p);
    canvas.drawLine(
      Offset(1.999 * r, 6.663 * r),
      Offset(13.993 * r, 6.663 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClockIconPainter extends CustomPainter {
  const _ClockIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(8 * r, 8 * r), 6.663 * r, p);
    canvas.drawLine(Offset(8 * r, 3.998 * r), Offset(8 * r, 7.996 * r), p);
    canvas.drawLine(Offset(8 * r, 7.996 * r), Offset(10.661 * r, 9.329 * r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinIconPainter extends CustomPainter {
  const _PinIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pin = Path()
      ..moveTo(13.326 * r, 6.663 * r)
      ..cubicTo(
        13.326 * r,
        9.99 * r,
        9.635 * r,
        13.455 * r,
        8.396 * r,
        14.525 * r,
      )
      ..cubicTo(
        8.281 * r,
        14.612 * r,
        8.14 * r,
        14.659 * r,
        7.996 * r,
        14.659 * r,
      )
      ..cubicTo(
        7.851 * r,
        14.659 * r,
        7.711 * r,
        14.612 * r,
        7.595 * r,
        14.525 * r,
      )
      ..cubicTo(
        6.356 * r,
        13.455 * r,
        2.665 * r,
        9.99 * r,
        2.665 * r,
        6.663 * r,
      )
      ..cubicTo(
        2.665 * r,
        5.249 * r,
        3.227 * r,
        3.893 * r,
        4.227 * r,
        2.894 * r,
      )
      ..cubicTo(
        5.226 * r,
        1.894 * r,
        6.582 * r,
        1.333 * r,
        7.996 * r,
        1.333 * r,
      )
      ..cubicTo(
        9.41 * r,
        1.333 * r,
        10.765 * r,
        1.894 * r,
        11.765 * r,
        2.894 * r,
      )
      ..cubicTo(
        12.765 * r,
        3.893 * r,
        13.326 * r,
        5.249 * r,
        13.326 * r,
        6.663 * r,
      )
      ..close();
    canvas.drawPath(pin, p);
    canvas.drawCircle(Offset(7.996 * r, 6.663 * r), 1.999 * r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoutIconPainter extends CustomPainter {
  const _LogoutIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.whiteDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final door = Path()
      ..moveTo(7.5 * r, 17.5 * r)
      ..lineTo(4.167 * r, 17.5 * r)
      ..cubicTo(
        3.725 * r,
        17.5 * r,
        3.301 * r,
        17.324 * r,
        2.988 * r,
        17.012 * r,
      )
      ..cubicTo(2.676 * r, 16.699 * r, 2.5 * r, 16.275 * r, 2.5 * r, 15.833 * r)
      ..lineTo(2.5 * r, 4.167 * r)
      ..cubicTo(2.5 * r, 3.725 * r, 2.676 * r, 3.301 * r, 2.988 * r, 2.988 * r)
      ..cubicTo(3.301 * r, 2.676 * r, 3.725 * r, 2.5 * r, 4.167 * r, 2.5 * r)
      ..lineTo(7.5 * r, 2.5 * r);
    canvas.drawPath(door, p);
    canvas.drawLine(
      Offset(13.333 * r, 14.166 * r),
      Offset(17.5 * r, 10 * r),
      p,
    );
    canvas.drawLine(Offset(17.5 * r, 10 * r), Offset(13.333 * r, 5.833 * r), p);
    canvas.drawLine(Offset(17.5 * r, 10 * r), Offset(7.5 * r, 10 * r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
