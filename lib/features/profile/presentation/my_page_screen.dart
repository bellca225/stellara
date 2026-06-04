// lib/features/profile/presentation/my_page_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/birth_info.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../../users/application/user_providers.dart';

// ──────────────────────────────────────────────
// 디자인 토큰
// ──────────────────────────────────────────────
class _C {
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8EC5FF);
  static const blue1 = Color(0xFF51A2FF);
  static const cardBorder = Color(0x1FFFFFFF);
  static const headerBorder = Color(0x26FFFFFF);
  static const glassStart = Color(0x14FFFFFF);
  static const glassEnd = Color(0x08FFFFFF);
  static const accentDim = Color(0xB38EC5FF); // 70%
  static const whiteDim = Color(0x99FFFFFF); // 60%
}

// ──────────────────────────────────────────────
// Glass Card
// ──────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.glassStart, _C.glassEnd],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x801E3A8A),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────
// Icon Painters
// ──────────────────────────────────────────────

// Icon__31_ — 편집(연필+사각) #8EC5FF 16×16
class _EditIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // 사각형
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
    // 연필
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
  bool shouldRepaint(_) => false;
}

// Icon__32_ — 복사 #8EC5FF 20×20
class _CopyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // 앞 사각형
    final path1 = Path()
      ..addRRect(
        RRect.fromLTRBR(
          6.667 * r,
          6.667 * r,
          18.333 * r,
          18.333 * r,
          Radius.circular(1.667 * r),
        ),
      );
    canvas.drawPath(path1, p);
    // 뒤 사각형
    final path2 = Path()
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
    canvas.drawPath(path2, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// Icon__33_ — 달력 #8EC5FF 16×16
class _CalendarIconPainter extends CustomPainter {
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
  bool shouldRepaint(_) => false;
}

// Icon__34_ — 시계 #8EC5FF 16×16
class _ClockIconPainter extends CustomPainter {
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
  bool shouldRepaint(_) => false;
}

// Icon__35_ — 위치 핀 #8EC5FF 16×16
class _PinIconPainter extends CustomPainter {
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
        9.990 * r,
        9.635 * r,
        13.455 * r,
        8.396 * r,
        14.525 * r,
      )
      ..cubicTo(
        8.281 * r,
        14.612 * r,
        8.140 * r,
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
        9.990 * r,
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
        9.410 * r,
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
  bool shouldRepaint(_) => false;
}

// Icon__36_ — 로그아웃 white 60% 20×20
class _LogoutIconPainter extends CustomPainter {
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
    // 화살표
    canvas.drawLine(
      Offset(13.333 * r, 14.166 * r),
      Offset(17.5 * r, 10.0 * r),
      p,
    );
    canvas.drawLine(
      Offset(17.5 * r, 10.0 * r),
      Offset(13.333 * r, 5.833 * r),
      p,
    );
    canvas.drawLine(Offset(17.5 * r, 10.0 * r), Offset(7.5 * r, 10.0 * r), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 출생 정보 행
// ──────────────────────────────────────────────
class _BirthRow extends StatelessWidget {
  final CustomPainter iconPainter;
  final String label;
  final String value;

  const _BirthRow({
    required this.iconPainter,
    required this.label,
    required this.value,
  });

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
            fontWeight: FontWeight.w300,
            fontFamily: 'Pretendard',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: _C.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// 메인 화면
// ──────────────────────────────────────────────
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birth = ref.watch(currentBirthInfoProvider) ?? BirthInfo.demo();
    final asyncChart = ref.watch(myNatalChartProvider);

    final initial = birth.nickname.isNotEmpty
        ? birth.nickname.characters.first
        : '별';
    final signLabel = asyncChart.when(
      data: (chart) => zodiacLabelKo(chart.sunSign),
      loading: () => '...',
      error: (_, __) => '',
    );
    final friendCode = asyncChart.when(
      data: (chart) => chart.sunSign.toUpperCase().substring(0, 3) + '2024',
      loading: () => '------',
      error: (_, __) => 'AQU2024',
    );

    final birthDateStr =
        '${birth.dateTime.year}-'
        '${birth.dateTime.month.toString().padLeft(2, '0')}-'
        '${birth.dateTime.day.toString().padLeft(2, '0')}';
    final birthTimeStr =
        '${birth.dateTime.hour.toString().padLeft(2, '0')}:'
        '${birth.dateTime.minute.toString().padLeft(2, '0')}';
    final birthPlaceStr = birth.placeName ?? '-';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // ── 프로필 영역 ──────────────────────────────
              Column(
                children: [
                  // 아바타 — 파란색 채우기
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x803B82F6),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: _C.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 닉네임 + 수정하기 버튼 같은 줄
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        birth.nickname.isNotEmpty ? birth.nickname : '닉네임 없음',
                        style: const TextStyle(
                          color: _C.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9999),
                            border: Border.all(
                              color: _C.headerBorder,
                              width: 1,
                            ),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CustomPaint(painter: _EditIconPainter()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 별자리
                  Text(
                    signLabel,
                    style: const TextStyle(
                      color: _C.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── 친구 코드 카드 ──────────────────────────
              _GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '내 친구 코드',
                            style: TextStyle(
                              color: _C.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            friendCode,
                            style: const TextStyle(
                              color: _C.white,
                              fontSize: 24,
                              fontFamily: 'Menlo',
                              letterSpacing: 2.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '친구에게 이 코드를 공유하세요',
                            style: TextStyle(
                              color: _C.accentDim,
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 복사 버튼
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: friendCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('코드가 복사되었어요.')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _C.headerBorder, width: 1),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                          ),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _CopyIconPainter()),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 출생 정보 섹션 타이틀 + 수정하기 ──────────
              Row(
                children: [
                  const Text(
                    '출생 정보',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: _C.headerBorder, width: 1),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CustomPaint(painter: _EditIconPainter()),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '수정',
                            style: TextStyle(
                              color: _C.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── 출생 정보 카드 ───────────────────────────
              _GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _BirthRow(
                      iconPainter: _CalendarIconPainter(),
                      label: '생년월일',
                      value: birthDateStr,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0x1AFFFFFF), height: 1),
                    ),
                    _BirthRow(
                      iconPainter: _ClockIconPainter(),
                      label: '출생 시간',
                      value: birthTimeStr,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Color(0x1AFFFFFF), height: 1),
                    ),
                    _BirthRow(
                      iconPainter: _PinIconPainter(),
                      label: '출생지',
                      value: birthPlaceStr,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 로그아웃 버튼 ────────────────────────────
              GestureDetector(
                onTap: () => _logout(context, ref),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: _C.headerBorder, width: 1),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _LogoutIconPainter()),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '로그아웃',
                        style: TextStyle(
                          color: _C.whiteDim,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말 로그아웃 할까요?',
          style: TextStyle(color: Color(0xFF8EC5FF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: Color(0xFF8EC5FF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('로그아웃', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (_) {}
      if (context.mounted) {
        ref.read(currentUserProvider.notifier).state = null;
      }
    }
  }
}
