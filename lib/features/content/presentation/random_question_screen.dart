// lib/features/content/presentation/random_question_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/env/env.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/astro_text.dart';
import '../../../core/widgets/panel.dart';
import '../../astrology/application/astrology_providers.dart';
import '../../astrology/domain/natal_chart.dart';
import '../../compatibility/application/compatibility_providers.dart';
import '../../compatibility/domain/synastry_result.dart';
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
import '../../friends/presentation/friend_screen.dart';
import '../../users/application/user_providers.dart';
import '../../users/domain/user_profile.dart';
import '../application/question_providers.dart';
import '../domain/question_item.dart';

// ──────────────────────────────────────────────
// 디자인 토큰
// ──────────────────────────────────────────────
class _C {
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8EC5FF);
  static const accentDim = Color(0x808EC5FF);
  static const cardBorder = Color(0x1FFFFFFF);
  static const headerBorder = Color(0x26FFFFFF);
  static const glassStart = Color(0x14FFFFFF);
  static const glassEnd = Color(0x08FFFFFF);
  static const shareBtnStart = Color(0x662B7FFF);
  static const shareBtnEnd = Color(0x40155DFC);
  static const labelColor = Color(0xFFBEDBFF);
}

// ──────────────────────────────────────────────
// Glass Card
// ──────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const _GlassCard({
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _C.cardBorder, width: 1),
        gradient:
            gradient ??
            const LinearGradient(
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
// 새로고침 아이콘 (Icon__21_ — 4개 path 정확히)
// ──────────────────────────────────────────────
class _RefreshIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // path1: M2.5 10 C(위 반원) L17.5 6.667
    final top = Path();
    top.moveTo(2.5 * r, 10 * r);
    top.cubicTo(2.5 * r, 8.011 * r, 3.29 * r, 6.103 * r, 4.697 * r, 4.697 * r);
    top.cubicTo(6.103 * r, 3.29 * r, 8.011 * r, 2.5 * r, 10 * r, 2.5 * r);
    top.cubicTo(
      12.096 * r,
      2.508 * r,
      14.109 * r,
      3.326 * r,
      15.616 * r,
      4.783 * r,
    );
    top.lineTo(17.5 * r, 6.667 * r);
    canvas.drawPath(top, p);

    // path2: M17.5 2.5 V6.667 H13.333
    canvas.drawLine(Offset(17.5 * r, 2.5 * r), Offset(17.5 * r, 6.667 * r), p);
    canvas.drawLine(
      Offset(17.5 * r, 6.667 * r),
      Offset(13.333 * r, 6.667 * r),
      p,
    );

    // path3: M17.5 10 C(아래 반원) L2.5 13.333
    final bot = Path();
    bot.moveTo(17.5 * r, 10 * r);
    bot.cubicTo(
      17.5 * r,
      11.989 * r,
      16.709 * r,
      13.896 * r,
      15.303 * r,
      15.303 * r,
    );
    bot.cubicTo(13.896 * r, 16.709 * r, 11.989 * r, 17.5 * r, 10 * r, 17.5 * r);
    bot.cubicTo(
      7.903 * r,
      17.492 * r,
      5.891 * r,
      16.674 * r,
      4.383 * r,
      15.216 * r,
    );
    bot.lineTo(2.5 * r, 13.333 * r);
    canvas.drawPath(bot, p);

    // path4: M6.667 13.333 H2.5 V17.5
    canvas.drawLine(
      Offset(6.667 * r, 13.333 * r),
      Offset(2.5 * r, 13.333 * r),
      p,
    );
    canvas.drawLine(Offset(2.5 * r, 13.333 * r), Offset(2.5 * r, 17.5 * r), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 드롭다운 화살표 (Icon__23_)
// ──────────────────────────────────────────────
class _ChevronDownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(4.4852 * r, 7.861 * r)
      ..lineTo(9.4853 * r, 12.861 * r)
      ..lineTo(14.4853 * r, 7.861 * r);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 공유 아이콘 (흰색)
// ──────────────────────────────────────────────
class _ShareWhiteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(14.9996 * r, 4.1664 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(4.9998 * r, 9.9997 * r), 2.5 * r, p);
    canvas.drawCircle(Offset(14.9996 * r, 15.833 * r), 2.5 * r, p);
    canvas.drawLine(
      Offset(7.1582 * r, 11.258 * r),
      Offset(12.8497 * r, 14.575 * r),
      p,
    );
    canvas.drawLine(
      Offset(12.8414 * r, 5.4248 * r),
      Offset(7.1582 * r, 8.7414 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 별빛 아이콘 (Icon__24_ — 답변 생성하기 버튼용)
// ──────────────────────────────────────────────
class _SparkleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 별 모양 path
    final star = Path()
      ..moveTo(8.281 * r, 12.916 * r)
      ..cubicTo(
        8.206 * r,
        12.628 * r,
        8.056 * r,
        12.365 * r,
        7.845 * r,
        12.154 * r,
      )
      ..cubicTo(
        7.635 * r,
        11.944 * r,
        7.372 * r,
        11.793 * r,
        7.083 * r,
        11.719 * r,
      )
      ..lineTo(1.971 * r, 10.401 * r)
      ..cubicTo(
        1.884 * r,
        10.376 * r,
        1.807 * r,
        10.323 * r,
        1.752 * r,
        10.251 * r,
      )
      ..cubicTo(
        1.697 * r,
        10.179 * r,
        1.668 * r,
        10.091 * r,
        1.668 * r,
        10.0 * r,
      )
      ..cubicTo(
        1.668 * r,
        9.909 * r,
        1.697 * r,
        9.821 * r,
        1.752 * r,
        9.749 * r,
      )
      ..cubicTo(
        1.807 * r,
        9.676 * r,
        1.884 * r,
        9.624 * r,
        1.971 * r,
        9.599 * r,
      )
      ..lineTo(7.083 * r, 8.280 * r)
      ..cubicTo(
        7.371 * r,
        8.206 * r,
        7.635 * r,
        8.055 * r,
        7.845 * r,
        7.845 * r,
      )
      ..cubicTo(
        8.056 * r,
        7.634 * r,
        8.206 * r,
        7.371 * r,
        8.281 * r,
        7.083 * r,
      )
      ..lineTo(9.599 * r, 1.971 * r)
      ..cubicTo(
        9.623 * r,
        1.883 * r,
        9.676 * r,
        1.806 * r,
        9.748 * r,
        1.751 * r,
      )
      ..cubicTo(9.821 * r, 1.696 * r, 9.909 * r, 1.667 * r, 10.0 * r, 1.667 * r)
      ..cubicTo(
        10.091 * r,
        1.667 * r,
        10.180 * r,
        1.696 * r,
        10.252 * r,
        1.751 * r,
      )
      ..cubicTo(
        10.324 * r,
        1.806 * r,
        10.377 * r,
        1.883 * r,
        10.401 * r,
        1.971 * r,
      )
      ..lineTo(11.719 * r, 7.083 * r)
      ..cubicTo(
        11.793 * r,
        7.372 * r,
        11.944 * r,
        7.635 * r,
        12.154 * r,
        7.845 * r,
      )
      ..cubicTo(
        12.365 * r,
        8.056 * r,
        12.628 * r,
        8.206 * r,
        12.916 * r,
        8.281 * r,
      )
      ..lineTo(18.029 * r, 9.598 * r)
      ..cubicTo(
        18.117 * r,
        9.622 * r,
        18.194 * r,
        9.675 * r,
        18.249 * r,
        9.747 * r,
      )
      ..cubicTo(
        18.305 * r,
        9.820 * r,
        18.335 * r,
        9.909 * r,
        18.335 * r,
        10.0 * r,
      )
      ..cubicTo(
        18.335 * r,
        10.091 * r,
        18.305 * r,
        10.180 * r,
        18.249 * r,
        10.252 * r,
      )
      ..cubicTo(
        18.194 * r,
        10.325 * r,
        18.117 * r,
        10.377 * r,
        18.029 * r,
        10.402 * r,
      )
      ..lineTo(12.916 * r, 11.719 * r)
      ..cubicTo(
        12.628 * r,
        11.793 * r,
        12.365 * r,
        11.944 * r,
        12.154 * r,
        12.154 * r,
      )
      ..cubicTo(
        11.944 * r,
        12.365 * r,
        11.793 * r,
        12.628 * r,
        11.719 * r,
        12.916 * r,
      )
      ..lineTo(10.401 * r, 18.029 * r)
      ..cubicTo(
        10.376 * r,
        18.116 * r,
        10.324 * r,
        18.194 * r,
        10.251 * r,
        18.249 * r,
      )
      ..cubicTo(
        10.179 * r,
        18.303 * r,
        10.090 * r,
        18.333 * r,
        9.999 * r,
        18.333 * r,
      )
      ..cubicTo(
        9.908 * r,
        18.333 * r,
        9.820 * r,
        18.303 * r,
        9.748 * r,
        18.249 * r,
      )
      ..cubicTo(
        9.675 * r,
        18.194 * r,
        9.623 * r,
        18.116 * r,
        9.598 * r,
        18.029 * r,
      )
      ..close();
    canvas.drawPath(star, p);

    // 오른쪽 위 작은 십자
    canvas.drawLine(
      Offset(16.666 * r, 2.5 * r),
      Offset(16.666 * r, 5.833 * r),
      p,
    );
    canvas.drawLine(
      Offset(18.333 * r, 4.167 * r),
      Offset(15.0 * r, 4.167 * r),
      p,
    );

    // 왼쪽 아래 작은 십자
    canvas.drawLine(
      Offset(3.333 * r, 14.166 * r),
      Offset(3.333 * r, 15.833 * r),
      p,
    );
    canvas.drawLine(Offset(4.167 * r, 15.0 * r), Offset(2.5 * r, 15.0 * r), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 점성술 답변 아이콘 (Icon__26_ — #51A2FF, 16×16)
// ──────────────────────────────────────────────
class _AnswerSparkleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = const Color(0xFF51A2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 별 모양
    final star = Path()
      ..moveTo(6.621 * r, 10.328 * r)
      ..cubicTo(
        6.562 * r,
        10.097 * r,
        6.442 * r,
        9.887 * r,
        6.273 * r,
        9.719 * r,
      )
      ..cubicTo(
        6.105 * r,
        9.550 * r,
        5.894 * r,
        9.430 * r,
        5.664 * r,
        9.371 * r,
      )
      ..lineTo(1.576 * r, 8.316 * r)
      ..cubicTo(
        1.506 * r,
        8.297 * r,
        1.445 * r,
        8.255 * r,
        1.401 * r,
        8.197 * r,
      )
      ..cubicTo(
        1.357 * r,
        8.139 * r,
        1.334 * r,
        8.068 * r,
        1.334 * r,
        7.996 * r,
      )
      ..cubicTo(
        1.334 * r,
        7.923 * r,
        1.357 * r,
        7.853 * r,
        1.401 * r,
        7.795 * r,
      )
      ..cubicTo(
        1.445 * r,
        7.737 * r,
        1.506 * r,
        7.695 * r,
        1.576 * r,
        7.675 * r,
      )
      ..lineTo(5.664 * r, 6.621 * r)
      ..cubicTo(
        5.894 * r,
        6.561 * r,
        6.105 * r,
        6.441 * r,
        6.273 * r,
        6.273 * r,
      )
      ..cubicTo(
        6.441 * r,
        6.105 * r,
        6.562 * r,
        5.894 * r,
        6.621 * r,
        5.664 * r,
      )
      ..lineTo(7.675 * r, 1.576 * r)
      ..cubicTo(
        7.695 * r,
        1.506 * r,
        7.737 * r,
        1.444 * r,
        7.795 * r,
        1.400 * r,
      )
      ..cubicTo(
        7.853 * r,
        1.356 * r,
        7.924 * r,
        1.333 * r,
        7.996 * r,
        1.333 * r,
      )
      ..cubicTo(
        8.069 * r,
        1.333 * r,
        8.140 * r,
        1.356 * r,
        8.198 * r,
        1.400 * r,
      )
      ..cubicTo(
        8.255 * r,
        1.444 * r,
        8.297 * r,
        1.506 * r,
        8.317 * r,
        1.576 * r,
      )
      ..lineTo(9.371 * r, 5.664 * r)
      ..cubicTo(
        9.430 * r,
        5.894 * r,
        9.550 * r,
        6.105 * r,
        9.719 * r,
        6.273 * r,
      )
      ..cubicTo(
        9.887 * r,
        6.442 * r,
        10.097 * r,
        6.562 * r,
        10.328 * r,
        6.621 * r,
      )
      ..lineTo(14.416 * r, 7.675 * r)
      ..cubicTo(
        14.486 * r,
        7.694 * r,
        14.548 * r,
        7.736 * r,
        14.592 * r,
        7.794 * r,
      )
      ..cubicTo(
        14.637 * r,
        7.852 * r,
        14.660 * r,
        7.923 * r,
        14.660 * r,
        7.996 * r,
      )
      ..cubicTo(
        14.660 * r,
        8.069 * r,
        14.637 * r,
        8.140 * r,
        14.592 * r,
        8.198 * r,
      )
      ..cubicTo(
        14.548 * r,
        8.256 * r,
        14.486 * r,
        8.298 * r,
        14.416 * r,
        8.317 * r,
      )
      ..lineTo(10.328 * r, 9.371 * r)
      ..cubicTo(
        10.097 * r,
        9.430 * r,
        9.887 * r,
        9.550 * r,
        9.719 * r,
        9.719 * r,
      )
      ..cubicTo(
        9.550 * r,
        9.887 * r,
        9.430 * r,
        10.097 * r,
        9.371 * r,
        10.328 * r,
      )
      ..lineTo(8.316 * r, 14.416 * r)
      ..cubicTo(
        8.297 * r,
        14.486 * r,
        8.255 * r,
        14.548 * r,
        8.197 * r,
        14.592 * r,
      )
      ..cubicTo(
        8.139 * r,
        14.636 * r,
        8.068 * r,
        14.659 * r,
        7.996 * r,
        14.659 * r,
      )
      ..cubicTo(
        7.923 * r,
        14.659 * r,
        7.852 * r,
        14.636 * r,
        7.794 * r,
        14.592 * r,
      )
      ..cubicTo(
        7.736 * r,
        14.548 * r,
        7.694 * r,
        14.486 * r,
        7.675 * r,
        14.416 * r,
      )
      ..close();
    canvas.drawPath(star, p);

    // 오른쪽 위 십자
    canvas.drawLine(
      Offset(13.326 * r, 1.999 * r),
      Offset(13.326 * r, 4.664 * r),
      p,
    );
    canvas.drawLine(
      Offset(14.659 * r, 3.332 * r),
      Offset(11.994 * r, 3.332 * r),
      p,
    );

    // 왼쪽 아래 십자
    canvas.drawLine(
      Offset(2.665 * r, 11.327 * r),
      Offset(2.665 * r, 12.660 * r),
      p,
    );
    canvas.drawLine(
      Offset(3.332 * r, 11.994 * r),
      Offset(1.999 * r, 11.994 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ──────────────────────────────────────────────
// 질문 카드 (Fade 전환)
// ──────────────────────────────────────────────
class _AnimatedQuestionCard extends StatefulWidget {
  final String? text;
  final bool isLoading;
  const _AnimatedQuestionCard({this.text, this.isLoading = false});

  @override
  State<_AnimatedQuestionCard> createState() => _AnimatedQuestionCardState();
}

class _AnimatedQuestionCardState extends State<_AnimatedQuestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  String? _displayText;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _displayText = widget.text;
    if (_displayText != null) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedQuestionCard old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.text != null) {
      _ctrl.reverse().then((_) {
        if (mounted) setState(() => _displayText = widget.text);
        _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(24),
      child: widget.isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF8EC5FF),
                ),
              ),
            )
          : FadeTransition(
              opacity: _fade,
              child: Text(
                _displayText ?? '',
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
    );
  }
}

// ──────────────────────────────────────────────
// 답변 카드
// ──────────────────────────────────────────────
class _AnswerCard extends StatelessWidget {
  final QuestionItem item;
  const _AnswerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 + "점성술 답변" 라벨
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CustomPaint(painter: _AnswerSparkleIconPainter()),
              ),
              const SizedBox(width: 8),
              Text(
                item.isAiGenerated ? 'AI 점성술 답변' : '점성술 답변',
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 답변 본문
          Text(
            item.answer,
            style: const TextStyle(
              color: _C.white,
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 메인 화면
// ──────────────────────────────────────────────
class RandomQuestionScreen extends ConsumerStatefulWidget {
  const RandomQuestionScreen({super.key});

  @override
  ConsumerState<RandomQuestionScreen> createState() =>
      _RandomQuestionScreenState();
}

class _RandomQuestionScreenState extends ConsumerState<RandomQuestionScreen> {
  String? _selectedFriendUid;
  bool _hasRequestedQuestion = false;
  bool _showAnswer = false;
  int _revision = 0;

  void _requestNewQuestion(BuildContext context) {
    if (_selectedFriendUid == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 친구를 선택해주세요.')));
      return;
    }
    setState(() {
      _hasRequestedQuestion = true;
      _showAnswer = false;
      _revision += 1;
    });
  }

  Future<void> _shareQuestion(BuildContext context, QuestionItem? item) async {
    if (item == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 질문을 생성해주세요.')));
      return;
    }
    final text = _showAnswer
        ? '✨ 랜덤 질문\n\n${item.prompt}\n\n점성술 답변\n${item.answer}\n\n#Stellara #랜덤질문'
        : '✨ 랜덤 질문\n\n${item.prompt}\n\n#Stellara #랜덤질문';
    try {
      await Share.share(text, subject: item.prompt);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final myUid = ref.watch(myUidProvider);
    final myNickname = ref.watch(myNicknameProvider) ?? '나';
    final aiEnabled = Env.aiRemoteEnabled;
    final myChartAsync = aiEnabled
        ? ref.watch(myChartForQuestionProvider)
        : const AsyncValue<NatalChart?>.data(null);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 제목 영역 (padding-top: 24, 제목↔설명 8px) ──
              const SizedBox(height: 24),
              const Text(
                '랜덤질문',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '친구를 선택하고 점성술 질문을 받아보세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 24),

              friendsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _GlassCard(
                  child: Text(
                    '친구 목록을 불러오지 못했어요: $e',
                    style: const TextStyle(color: _C.white),
                  ),
                ),
                data: (friends) => _buildBody(
                  context,
                  friends,
                  myUid,
                  myNickname,
                  aiEnabled,
                  myChartAsync,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Friend> friends,
    String? myUid,
    String myNickname,
    bool aiEnabled,
    AsyncValue<NatalChart?> myChartAsync,
  ) {
    if (friends.isEmpty) {
      return _GlassCard(
        child: Column(
          children: [
            const Text(
              '아직 친구가 없어요.\n친구를 추가하면 별자리 질문을 받을 수 있어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _C.white,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FriendScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: _C.headerBorder),
                  gradient: const LinearGradient(
                    colors: [_C.shareBtnStart, _C.shareBtnEnd],
                  ),
                ),
                child: const Text(
                  '친구 추가하러 가기',
                  style: TextStyle(
                    color: _C.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedFriend = _resolveSelectedFriend(friends);
    final hasSelected = selectedFriend != null;

    final friendProfileAsync = (aiEnabled && hasSelected)
        ? ref.watch(userProfileByIdProvider(selectedFriend.uid))
        : const AsyncValue<UserProfile?>.data(null);
    final friendBirth = friendProfileAsync.valueOrNull?.birthInfo;

    final friendChartAsync = (aiEnabled && hasSelected && friendBirth != null)
        ? ref.watch(natalChartProvider(friendBirth))
        : const AsyncValue<NatalChart>.data(NatalChart.empty);
    final friendChart = friendChartAsync.valueOrNull;
    final isFriendChartLoading =
        aiEnabled &&
        hasSelected &&
        (friendProfileAsync.isLoading || friendChartAsync.isLoading);

    final myBirth = aiEnabled ? ref.watch(currentBirthInfoProvider) : null;
    SynastryResult? synastry;
    if (hasSelected &&
        !Env.shouldUseFixtureForProkerala &&
        myBirth != null &&
        friendBirth != null) {
      synastry = ref
          .watch(
            matchProvider((
              friendBirth: friendBirth,
              friendUid: selectedFriend.uid,
            )),
          )
          .valueOrNull;
    }

    final myChart = myChartAsync.valueOrNull;
    final canUseAi =
        aiEnabled &&
        myChart != null &&
        myChart != NatalChart.empty &&
        friendChart != null &&
        friendChart != NatalChart.empty &&
        myUid != null;

    AsyncValue<QuestionItem>? questionAsync;
    if (_hasRequestedQuestion && hasSelected) {
      if (!aiEnabled) {
        questionAsync = ref.watch(
          localSingleQuestionProvider((
            friendUid: selectedFriend.uid,
            friendName: selectedFriend.nickname,
            friendSign: selectedFriend.sunSign,
            mySign: ref.watch(mySunSignProvider),
            revision: _revision,
          )),
        );
      } else if (canUseAi) {
        questionAsync = ref.watch(
          aiSingleQuestionProvider((
            myUid: myUid,
            myNickname: myNickname,
            myChart: myChart,
            friendUid: selectedFriend.uid,
            friendNickname: selectedFriend.nickname,
            friendChart: friendChart,
            synastry: synastry,
            revision: _revision,
          )),
        );
      } else if (myChartAsync.isLoading || isFriendChartLoading) {
        questionAsync = const AsyncValue<QuestionItem>.loading();
      } else {
        questionAsync = ref.watch(
          localSingleQuestionProvider((
            friendUid: selectedFriend.uid,
            friendName: selectedFriend.nickname,
            friendSign: selectedFriend.sunSign,
            mySign: ref.watch(mySunSignProvider),
            revision: _revision,
          )),
        );
      }
    }

    final generatedQuestion = questionAsync?.valueOrNull;
    final isQuestionLoading = questionAsync?.isLoading ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 친구 선택 라벨 ──────────────────────────────
        const Text(
          '친구 선택',
          style: TextStyle(
            color: _C.labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),

        // ── 친구 선택 드롭다운 ──────────────────────────
        _GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: SizedBox(
            height: 49,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFriendUid,
                      dropdownColor: const Color(0xFF0A1628),
                      // 기본 화살표 숨기고 커스텀 아이콘 사용
                      icon: SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _ChevronDownPainter()),
                      ),
                      isExpanded: true,
                      hint: const Text(
                        '친구 선택',
                        style: TextStyle(
                          color: _C.accentDim,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      items: [
                        for (final f in friends)
                          DropdownMenuItem(
                            value: f.uid,
                            child: Text(
                              '${f.nickname} · ${_signLabel(f.sunSign)}',
                              style: const TextStyle(
                                color: _C.white,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFriendUid = value;
                          _hasRequestedQuestion = false;
                          _showAnswer = false;
                          _revision = 0;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isFriendChartLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                SizedBox(width: 8),
                Text(
                  '친구 별자리 차트 불러오는 중...',
                  style: TextStyle(
                    color: _C.accentDim,
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // ── 질문 카드 (생성됐을 때만 표시) ───────────────
        if (_hasRequestedQuestion) ...[
          // 질문 + 답변생성 버튼을 하나의 GlassCard 안에
          _GlassCard(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 질문 텍스트 or 로딩
                if (isQuestionLoading)
                  const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8EC5FF),
                      ),
                    ),
                  )
                else
                  Text(
                    generatedQuestion?.prompt ?? '',
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

                // 답변 생성하기 버튼 (답변 안 보일 때만)
                if (generatedQuestion != null && !_showAnswer) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => _showAnswer = true),
                    child: Container(
                      width: 191,
                      height: 61,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0x26FFFFFF),
                          width: 1,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0x662B7FFF), Color(0x40155DFC)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x7F1E3A8A),
                            blurRadius: 20,
                            offset: Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 4,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _SparkleIconPainter()),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '답변 생성하기',
                            style: TextStyle(
                              color: _C.white,
                              fontSize: 18,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              height: 1.56,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 답변 카드
          if (_showAnswer && generatedQuestion != null) ...[
            const SizedBox(height: 16),
            _AnswerCard(item: generatedQuestion),
          ],

          const SizedBox(height: 24),
        ],

        // ── 새 질문 / 공유하기 버튼 ─────────────────────
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isQuestionLoading
                    ? null
                    : () => _requestNewQuestion(context),
                child: Container(
                  height: 61,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: _C.headerBorder, width: 1),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CustomPaint(painter: _RefreshIconPainter()),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '새 질문',
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _shareQuestion(context, generatedQuestion),
                child: Container(
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
                        child: CustomPaint(painter: _ShareWhiteIconPainter()),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '공유하기',
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
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── 하단 안내 문구 — 질문 생성 전에만 표시 ────────
        if (!_hasRequestedQuestion)
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.cardBorder, width: 1),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.glassStart, _C.glassEnd],
              ),
            ),
            child: const Center(
              child: Text(
                '친구를 선택하고 "새 질문" 버튼을 눌러 시작하세요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _C.accentDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Friend? _resolveSelectedFriend(List<Friend> friends) {
    final uid = _selectedFriendUid;
    if (uid == null) return null;
    for (final f in friends) {
      if (f.uid == uid) return f;
    }
    return null;
  }
}

String _signLabel(String sign) {
  final n = sign.trim().toLowerCase();
  if (n.isEmpty || n == '-') return '별자리 미확인';
  return zodiacNameKo(sign);
}
