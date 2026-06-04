// lib/features/horoscope/presentation/today_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/widgets/panel.dart';
import '../application/horoscope_providers.dart';
import '../domain/horoscope.dart';

class _C {
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8EC5FF);
  static const blue1 = Color(0xFF51A2FF);
  static const cardBorder = Color(0x1FFFFFFF);
  static const headerBorder = Color(0x26FFFFFF);
  static const glassStart = Color(0x14FFFFFF);
  static const glassEnd = Color(0x08FFFFFF);
  static const shareBtnStart = Color(0x662B7FFF);
  static const shareBtnEnd = Color(0x40155DFC);
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

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

class _ShareAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(15.0 * r, 4.166 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(5.0 * r, 10.0 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(15.0 * r, 15.833 * r), 2.5 * r, p);
    canvas.drawLine(
      Offset(7.158 * r, 11.258 * r),
      Offset(12.850 * r, 14.574 * r),
      p,
    );
    canvas.drawLine(
      Offset(12.841 * r, 5.425 * r),
      Offset(7.158 * r, 8.741 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ClockPainter extends CustomPainter {
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
    canvas.drawLine(Offset(8 * r, 4 * r), Offset(8 * r, 8 * r), p);
    canvas.drawLine(Offset(8 * r, 8 * r), Offset(10.661 * r, 9.329 * r), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.blue1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = 8.0 * r;
    final cy = 8.0 * r;
    final outerR = 6.5 * r;
    final innerR = 2.8 * r;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi / 5) - math.pi / 2;
      final radius = i.isEven ? outerR : innerR;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ShareWhitePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(15.0 * r, 4.166 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(5.0 * r, 10.0 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(15.0 * r, 15.833 * r), 2.5 * r, p);
    canvas.drawLine(
      Offset(7.158 * r, 11.258 * r),
      Offset(12.850 * r, 14.574 * r),
      p,
    );
    canvas.drawLine(
      Offset(12.841 * r, 5.425 * r),
      Offset(7.158 * r, 8.741 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHoroscope = ref.watch(todayHoroscopeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: asyncHoroscope.when(
          loading: () => const _LoadingSkeleton(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is StateError
                          ? error.message
                          : '오늘의 운세를 불러오지 못했어요.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _C.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(todayHoroscopeProvider),
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (horoscope) => _HoroscopeBody(horoscope: horoscope),
        ),
      ),
    );
  }
}

class _HoroscopeBody extends StatelessWidget {
  const _HoroscopeBody({required this.horoscope});

  final Horoscope horoscope;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy년 M월 d일').format(horoscope.date);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오늘의 운세',
                      style: TextStyle(
                        color: _C.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CustomPaint(painter: _ClockPainter()),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: _C.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _share(context, horoscope),
                child: Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _C.headerBorder, width: 1),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Color(0x801E3A8A),
                        blurRadius: 20,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CustomPaint(painter: _ShareAccentPainter()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CustomPaint(painter: _StarPainter()),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '전체 운세',
                      style: TextStyle(
                        color: _C.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  horoscope.summary.trim().isNotEmpty
                      ? horoscope.summary
                      : '오늘의 운세를 준비 중이에요.',
                  style: const TextStyle(
                    color: _C.white,
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
          const SizedBox(height: 20),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 감정 상태',
                  style: TextStyle(
                    color: _C.blue1,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  horoscope.mood.trim().isNotEmpty ? horoscope.mood : '-',
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '행운 요소',
            style: TextStyle(
              color: _C.white,
              fontSize: 18,
              fontWeight: FontWeight.w300,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          _LuckyCard(label: '숫자', value: _luckyNumbers(horoscope.luckyNumbers)),
          const SizedBox(height: 12),
          _LuckyCard(label: '색상', value: _luckyColor(horoscope.luckyColor)),
          if (horoscope.luckyPlace != null &&
              horoscope.luckyPlace!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _LuckyCard(label: '장소', value: horoscope.luckyPlace!.trim()),
          ],
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => _share(context, horoscope),
            child: Container(
              width: double.infinity,
              height: 61,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                border: Border.all(color: _C.headerBorder, width: 1),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_C.shareBtnStart, _C.shareBtnEnd],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x661E3A8A),
                    blurRadius: 40,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _ShareWhitePainter()),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SNS에 공유하기',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _luckyNumbers(List<int> numbers) {
    if (numbers.isEmpty) {
      return '-';
    }
    return numbers.join(', ');
  }

  String _luckyColor(String color) {
    final trimmed = color.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Future<void> _share(BuildContext ctx, Horoscope horoscope) async {
    final date = DateFormat('yyyy년 M월 d일').format(horoscope.date);
    final fallback =
        '✨ 오늘의 운세 ($date)\n\n'
        '${horoscope.summary}\n\n'
        '🎨 행운 색상: ${_luckyColor(horoscope.luckyColor)}\n'
        '🔢 행운 숫자: ${_luckyNumbers(horoscope.luckyNumbers)}\n'
        '#Stellara #오늘의운세';
    final text = horoscope.shareText.trim().isNotEmpty
        ? '${horoscope.shareText.trim()}\n\n$fallback'
        : fallback;
    try {
      await Share.share(text);
    } catch (_) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')));
      }
    }
  }
}

class _LuckyCard extends StatelessWidget {
  const _LuckyCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _C.blue1,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
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
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 160, height: 36),
          SizedBox(height: 8),
          SkeletonBox(width: 120, height: 16),
          SizedBox(height: 28),
          SkeletonBox(height: 120, radius: 24),
          SizedBox(height: 20),
          SkeletonBox(height: 80, radius: 24),
          SizedBox(height: 24),
          SkeletonBox(width: 80, height: 20),
          SizedBox(height: 16),
          SkeletonBox(height: 72, radius: 24),
          SizedBox(height: 12),
          SkeletonBox(height: 72, radius: 24),
          SizedBox(height: 12),
          SkeletonBox(height: 72, radius: 24),
        ],
      ),
    );
  }
}
