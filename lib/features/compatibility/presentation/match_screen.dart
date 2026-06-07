// lib/features/compatibility/presentation/match_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/glass.dart';
import '../../friends/application/friend_providers.dart';
import '../../friends/domain/friend.dart';
import '../../users/application/user_providers.dart';
import '../application/compatibility_providers.dart';
import '../domain/synastry_result.dart';
import 'match_share_screen.dart';

class _C {
  static const white = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8EC5FF);
  static const blue1 = Color(0xFF51A2FF);
  static const blue2 = Color(0xFF155DFC);
  static const cardBorder = Color(0x1FFFFFFF);
  static const headerBorder = Color(0x26FFFFFF);
  static const glassStart = Color(0x14FFFFFF);
  static const glassEnd = Color(0x08FFFFFF);
  static const progressBg = Color(0x0DFFFFFF);
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
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _C.cardBorder, width: 1),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.glassStart, _C.glassEnd],
        ),
        boxShadow: kGlassShadow,
      ),
      child: child,
    );
  }
}

class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.percent});

  final int percent;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.percent / 100.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9999),
          color: _C.progressBg,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: _anim.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9999),
                gradient: const LinearGradient(colors: [_C.blue1, _C.blue2]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeartIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 40;
    final p = Paint()
      ..color = const Color(0xFF51A2FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.33326 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(19.9995 * s, 8.333 * s)
      ..cubicTo(
        17.4996 * s,
        5.833 * s,
        15.433 * s,
        4.9999 * s,
        12.4997 * s,
        4.9999 * s,
      )
      ..cubicTo(
        10.0686 * s,
        4.9999 * s,
        7.737 * s,
        5.9656 * s,
        6.018 * s,
        7.6847 * s,
      )
      ..cubicTo(
        4.299 * s,
        9.4037 * s,
        3.333 * s,
        11.735 * s,
        3.333 * s,
        14.166 * s,
      )
      ..cubicTo(
        3.333 * s,
        17.9996 * s,
        5.833 * s,
        20.916 * s,
        8.333 * s,
        23.333 * s,
      )
      ..lineTo(19.9995 * s, 34.999 * s)
      ..lineTo(31.666 * s, 23.333 * s)
      ..cubicTo(
        34.149 * s,
        20.9 * s,
        36.666 * s,
        17.983 * s,
        36.666 * s,
        14.166 * s,
      )
      ..cubicTo(
        36.666 * s,
        11.735 * s,
        35.7 * s,
        9.4037 * s,
        33.981 * s,
        7.6847 * s,
      )
      ..cubicTo(
        32.262 * s,
        5.9656 * s,
        29.930 * s,
        4.9999 * s,
        27.499 * s,
        4.9999 * s,
      )
      ..cubicTo(
        24.566 * s,
        4.9999 * s,
        22.499 * s,
        5.833 * s,
        19.9995 * s,
        8.333 * s,
      )
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BackIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = const Color(0xFF8EC5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(
      Offset(9.9997 * r, 15.833 * r),
      Offset(4.1665 * r, 9.9997 * r),
      p,
    );
    canvas.drawLine(
      Offset(4.1665 * r, 9.9997 * r),
      Offset(9.9997 * r, 4.1665 * r),
      p,
    );
    canvas.drawLine(
      Offset(15.833 * r, 9.9998 * r),
      Offset(4.1665 * r, 9.9998 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ShareWhiteIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = Colors.white
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

class _StarsBg extends StatelessWidget {
  const _StarsBg({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF04081A),
            Color(0xFF060D2E),
            Color(0xFF08112A),
            Color(0xFF030818),
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: CustomPaint(painter: _StarsPainter(), child: child),
    );
  }
}

class _StarsPainter extends CustomPainter {
  static final _rng = math.Random(42);
  static final _pos = List.generate(
    80,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final _sz = List.generate(80, (_) => _rng.nextDouble() * 1.5 + 0.5);
  static final _op = List.generate(80, (_) => _rng.nextDouble() * 0.6 + 0.2);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pos.length; i++) {
      canvas.drawCircle(
        Offset(_pos[i].dx * size.width, _pos[i].dy * size.height),
        _sz[i],
        Paint()..color = Colors.white.withValues(alpha: _op[i]),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key, this.initialFriendUid});

  final String? initialFriendUid;

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen> {
  String? _selectedFriendUid;

  @override
  void initState() {
    super.initState();
    _selectedFriendUid = widget.initialFriendUid;
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendListProvider);
    final friends = friendsAsync.valueOrNull ?? const <Friend>[];
    final selectedUid =
        _selectedFriendUid ?? (friends.isNotEmpty ? friends.first.uid : null);
    final selectedFriend = friends.cast<Friend?>().firstWhere(
      (f) => f?.uid == selectedUid,
      orElse: () => null,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _StarsBg(
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: _HeaderIcon(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CustomPaint(painter: _BackIconPainter()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '궁합결과',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: _C.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.33,
                            letterSpacing: -0.2,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (widget.initialFriendUid == null) ...[
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '궁합 볼 친구 선택',
                            style: TextStyle(
                              color: _C.accent,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(height: 12),
                          friendsAsync.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) => const Text(
                              '친구 목록을 불러오지 못했어요',
                              style: TextStyle(color: _C.white),
                            ),
                            data: (list) => list.isEmpty
                                ? const Text(
                                    '아직 친구가 없어요.',
                                    style: TextStyle(
                                      color: _C.white,
                                      fontFamily: 'Pretendard',
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final f in list)
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => _selectedFriendUid = f.uid,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(9999),
                                              border: Border.all(
                                                color: f.uid == selectedUid
                                                    ? _C.accent
                                                    : _C.headerBorder,
                                                width: 1,
                                              ),
                                              color: f.uid == selectedUid
                                                  ? _C.accent.withValues(alpha: 0.2)
                                                  : Colors.transparent,
                                            ),
                                            child: Text(
                                              f.nickname,
                                              style: TextStyle(
                                                color: f.uid == selectedUid
                                                    ? _C.accent
                                                    : _C.white,
                                                fontFamily: 'Pretendard',
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (selectedUid == null)
                    _GlassCard(
                      child: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '궁합을 볼 친구를 선택해주세요.',
                            style: TextStyle(
                              color: _C.white,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    _MatchResultBody(
                      friendUid: selectedUid,
                      friendName: selectedFriend?.nickname,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchResultBody extends ConsumerWidget {
  const _MatchResultBody({
    required this.friendUid,
    this.friendName,
  });

  final String friendUid;
  final String? friendName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendProfileAsync = ref.watch(userProfileByIdProvider(friendUid));

    return friendProfileAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => _GlassCard(
        child: Text(
          '친구 정보를 불러오지 못했어요: $e',
          style: const TextStyle(color: _C.white),
        ),
      ),
      data: (friendProfile) {
        final friendBirth = friendProfile?.birthInfo;
        if (friendBirth == null) {
          return _GlassCard(
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '친구의 출생 정보가 아직 없어 궁합을 계산할 수 없어요.',
                style: TextStyle(color: _C.white, fontFamily: 'Pretendard'),
              ),
            ),
          );
        }

        final resultAsync = ref.watch(
          matchProvider((friendBirth: friendBirth, friendUid: friendUid)),
        );

        return resultAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => _GlassCard(
            child: Text(
              '궁합 계산 실패: $e',
              style: const TextStyle(color: _C.white),
            ),
          ),
          data: (result) => _ResultContent(
            result: result,
            friendName: friendName,
            friendZodiac: friendProfile?.sunSign ?? '-',
          ),
        );
      },
    );
  }
}

class _ResultContent extends StatefulWidget {
  const _ResultContent({
    required this.result,
    required this.friendZodiac,
    this.friendName,
  });

  final SynastryResult result;
  final String? friendName;
  final String friendZodiac;

  @override
  State<_ResultContent> createState() => _ResultContentState();
}

class _ResultContentState extends State<_ResultContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnim = IntTween(
      begin: 0,
      end: widget.result.totalScore,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomPaint(painter: _HeartIconPainter()),
              ),
              const SizedBox(height: 8),
              Text(
                '나와 ${widget.friendName ?? '친구'}의 궁합',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _C.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _countAnim,
                builder: (context, child) => Text(
                  '${_countAnim.value}%',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rationale(
                    color: _C.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.friendZodiac.isNotEmpty && widget.friendZodiac != '-')
                Text(
                  widget.friendZodiac,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _C.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    fontFamily: 'Pretendard',
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _AnalysisCard(
          label: '감정',
          percent: result.emotionScore,
          description: result.emotionalMatch,
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          label: '대화',
          percent: result.communicationScore,
          description: result.communicationStyle,
        ),
        const SizedBox(height: 12),
        _AnalysisCard(
          label: '연애 스타일',
          percent: result.romanceScore,
          description: result.romanticMatch,
        ),
        const SizedBox(height: 16),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '궁합 요약',
                style: TextStyle(
                  color: _C.accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.56,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.summary,
                style: const TextStyle(
                  color: _C.white,
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  height: 1.625,
                  letterSpacing: -0.15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GlassButton(
          label: 'SNS에 공유하기',
          isPrimary: true,
          height: 61,
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _ShareWhiteIconPainter()),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchShareScreen(
                result: widget.result,
                friendName: widget.friendName,
                friendZodiac: widget.friendZodiac,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
    required this.label,
    required this.percent,
    required this.description,
  });

  final String label;
  final int percent;
  final String description;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _C.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  fontFamily: 'Pretendard',
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ProgressBar(percent: percent),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: _C.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.43,
              letterSpacing: -0.2,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        boxShadow: kGlassShadow,
      ),
      child: Center(child: child),
    );
  }
}
