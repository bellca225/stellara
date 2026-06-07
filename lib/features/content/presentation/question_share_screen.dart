import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/ui/app_toast.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_saver.dart';
import '../../../core/widgets/glass.dart';

/// 랜덤 질문 공유 화면.
/// 미리보기 카드를 보여주고 (1) 스크린샷으로 저장 (2) SNS에 텍스트 공유 를 제공.
class QuestionShareScreen extends StatefulWidget {
  const QuestionShareScreen({
    super.key,
    required this.prompt,
    required this.answer,
  });

  final String prompt;
  final String answer;

  @override
  State<QuestionShareScreen> createState() => _QuestionShareScreenState();
}

class _QuestionShareScreenState extends State<QuestionShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  Future<void> _saveImage() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await saveImageBytes(
        bytes,
        'stellara_question.png',
        shareText: '✨ Stellara 랜덤 질문',
      );
      if (mounted) {
        showGlassToast(context, '이미지를 저장했어요.');
      }
    } catch (_) {
      if (mounted) {
        showGlassToast(context, '이미지 저장에 실패했어요. 다시 시도해주세요.', type: GlassToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareText() async {
    final text =
        '✨ 랜덤 질문\n\n${widget.prompt}\n\n점성술 답변\n${widget.answer}\n\n#Stellara #랜덤질문';
    try {
      await Share.share(text, subject: widget.prompt);
    } catch (_) {
      if (mounted) {
        showGlassToast(context, '공유를 지원하지 않는 환경이에요.', type: GlassToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── 헤더 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    const Text(
                      '공유하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                          ),
                          border: Border.all(
                            color: const Color(0x26FFFFFF),
                            width: 0.636,
                          ),
                          boxShadow: kGlassShadow,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _cardKey,
                        child: _ShareCard(
                          prompt: widget.prompt,
                          answer: widget.answer,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassButton(
                        label: '스크린샷으로 저장',
                        isPrimary: true,
                        isLoading: _saving,
                        height: 56,
                        leading: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: _saveImage,
                      ),
                      const SizedBox(height: 12),
                      GlassButton(
                        label: 'SNS에 공유하기',
                        isPrimary: false,
                        height: 56,
                        leading: const Icon(
                          Icons.ios_share_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onTap: _shareText,
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
}

/// 캡처/공유될 미리보기 카드. PNG로 저장되므로 배경은 불투명하게 둔다.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.prompt, required this.answer});

  final String prompt;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1B36), Color(0xFF0A1228)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
        boxShadow: kGlassShadow,
      ),
      child: Column(
        children: [
          Text(
            'Stellara',
            style: GoogleFonts.sulphurPoint(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 3,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '별자리의 신비를 탐험하세요',
            style: TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
              ),
              boxShadow: [
                BoxShadow(color: Color(0x4D3B82F6), blurRadius: 12),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '랜덤 질문',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '점성술이 알려주는 답',
            style: TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 12,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          // 내부 카드: 질문 + 구분선 + 답변
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                const SizedBox(height: 12),
                Text(
                  answer,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 14,
                    height: 1.6,
                    letterSpacing: -0.2,
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
