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
  static const accentDim = Color(0x808EC5FF); // 50% opacity
  static const blue1 = Color(0xFF51A2FF);
  static const blue2 = Color(0xFF155DFC);
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
// 새로고침 아이콘 (Icon__21_ 정확한 path)
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

    // 위쪽 반원: 2.5,10 → arc → 15.616,4.783
    final top = Path();
    top.moveTo(2.5 * r, 10 * r);
    top.arcToPoint(
      Offset(15.616 * r, 4.783 * r),
      radius: Radius.circular(7.5 * r),
      clockwise: false,
    );
    top.lineTo(17.5 * r, 6.667 * r);
    canvas.drawPath(top, p);
    // 위 화살표 꺾임
    canvas.drawLine(Offset(17.5 * r, 2.5 * r), Offset(17.5 * r, 6.667 * r), p);
    canvas.drawLine(
      Offset(13.333 * r, 6.667 * r),
      Offset(17.5 * r, 6.667 * r),
      p,
    );

    // 아래쪽 반원: 17.5,10 → arc → 4.383,15.216
    final bot = Path();
    bot.moveTo(17.5 * r, 10 * r);
    bot.arcToPoint(
      Offset(4.383 * r, 15.216 * r),
      radius: Radius.circular(7.5 * r),
      clockwise: false,
    );
    bot.lineTo(2.5 * r, 13.333 * r);
    canvas.drawPath(bot, p);
    canvas.drawLine(
      Offset(6.667 * r, 13.333 * r),
      Offset(2.5 * r, 13.333 * r),
      p,
    );
    canvas.drawLine(Offset(2.5 * r, 17.5 * r), Offset(2.5 * r, 13.333 * r), p);
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
// 별빛 배경
// ──────────────────────────────────────────────
class _StarsBg extends StatelessWidget {
  final Widget child;
  const _StarsBg({required this.child});

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
  static final _rng = math.Random(77);
  static final _pos = List.generate(
    80,
    (_) => Offset(_rng.nextDouble(), _rng.nextDouble()),
  );
  static final _sz = List.generate(80, (_) => _rng.nextDouble() * 1.5 + 0.4);
  static final _op = List.generate(80, (_) => _rng.nextDouble() * 0.55 + 0.15);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pos.length; i++) {
      canvas.drawCircle(
        Offset(_pos[i].dx * size.width, _pos[i].dy * size.height),
        _sz[i],
        Paint()..color = Colors.white.withOpacity(_op[i]),
      );
    }
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
                  fontWeight: FontWeight.w600,
                  height: 1.5,
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9999),
              color: const Color(0x2951A2FF),
            ),
            child: Text(
              item.isAiGenerated ? 'AI 점성술 답변' : '점성술 답변',
              style: const TextStyle(
                color: _C.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.answer,
            style: const TextStyle(
              color: _C.white,
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.65,
              letterSpacing: -0.15,
              fontFamily: 'Pretendard',
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

    return StarBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 제목 영역 ─────────────────────────────────
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
                '친구와 더 깊은 이야기를 나눠보세요',
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

              // ── 친구 선택 ──────────────────────────────────
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
    // 친구 없을 때
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
        // ── 친구 선택 박스 ──────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            _GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: SizedBox(
                height: 49,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFriendUid,
                    dropdownColor: const Color(0xFF0A1628),
                    iconEnabledColor: _C.accent,
                    isExpanded: true,
                    hint: const Text(
                      '친구를 선택해주세요',
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
          ],
        ),

        const SizedBox(height: 24),

        // ── 질문 카드 ───────────────────────────────────
        if (!hasSelected || !_hasRequestedQuestion)
          _GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: const SizedBox.shrink(),
          )
        else
          _AnimatedQuestionCard(
            text: generatedQuestion?.prompt,
            isLoading: isQuestionLoading,
          ),

        // 답변 카드
        if (_showAnswer && generatedQuestion != null) ...[
          const SizedBox(height: 16),
          _AnswerCard(item: generatedQuestion),
        ],

        // 답변 생성 버튼
        if (_hasRequestedQuestion &&
            generatedQuestion != null &&
            !_showAnswer) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _showAnswer = true),
            child: _GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: _C.accent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '답변 생성하기',
                    style: TextStyle(
                      color: _C.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── 새 질문 / 공유하기 버튼 ─────────────────────
        Row(
          children: [
            // 새 질문
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
            // 공유하기
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

        // ── 하단 저장 버튼 ──────────────────────────────
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('질문이 저장되었어요.')));
          },
          child: Container(
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
                '질문 저장하기',
                style: TextStyle(
                  color: _C.accentDim,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  fontFamily: 'Pretendard',
                ),
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
