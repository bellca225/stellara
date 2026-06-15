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

part 'my_page_dialogs.dart';
part 'my_page_painters.dart';
part 'my_page_widgets.dart';

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
