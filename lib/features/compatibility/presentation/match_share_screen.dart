import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/utils/image_saver.dart';
import '../../../core/widgets/glass.dart';
import '../domain/synastry_result.dart';

/// 궁합 결과 공유 화면.
/// 미리보기 카드 + (1) 스크린샷으로 저장 (2) SNS에 텍스트 공유.
class MatchShareScreen extends StatefulWidget {
  const MatchShareScreen({
    super.key,
    required this.result,
    required this.friendName,
    required this.friendZodiac,
  });

  final SynastryResult result;
  final String? friendName;
  final String friendZodiac;

  @override
  State<MatchShareScreen> createState() => _MatchShareScreenState();
}

class _MatchShareScreenState extends State<MatchShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  String get _name => widget.friendName ?? '친구';

  ({String label, int score}) get _topCategory {
    final r = widget.result;
    final cats = <({String label, int score})>[
      (label: '감정', score: r.emotionScore),
      (label: '대화', score: r.communicationScore),
      (label: '연애', score: r.romanceScore),
    ];
    cats.sort((a, b) => b.score.compareTo(a.score));
    return cats.first;
  }

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
        'stellara_compatibility.png',
        shareText: '✨ Stellara 궁합 결과',
      );
      if (mounted) {
        showGlassToast(context, '이미지를 저장했어요.');
      }
    } catch (_) {
      if (mounted) {
        showGlassToast(
          context,
          '이미지 저장에 실패했어요. 다시 시도해주세요.',
          type: GlassToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareText() async {
    final r = widget.result;
    final text =
        '✨ Stellara 궁합 결과\n\n'
        '나와 $_name의 궁합 ${r.totalScore}%\n\n'
        '${r.summary}\n\n#Stellara #궁합 #점성술';
    try {
      await Share.share(text, subject: '궁합 결과 공유');
    } catch (_) {
      if (mounted) {
        showGlassToast(
          context,
          '공유를 지원하지 않는 환경이에요.',
          type: GlassToastType.error,
        );
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
                        child: _MatchShareCard(
                          name: _name,
                          zodiac: widget.friendZodiac,
                          totalScore: widget.result.totalScore,
                          topLabel: _topCategory.label,
                          topScore: _topCategory.score,
                          summary: widget.result.summary,
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

class _MatchShareCard extends StatelessWidget {
  const _MatchShareCard({
    required this.name,
    required this.zodiac,
    required this.totalScore,
    required this.topLabel,
    required this.topScore,
    required this.summary,
  });

  final String name;
  final String zodiac;
  final int totalScore;
  final String topLabel;
  final int topScore;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final showZodiac = zodiac.isNotEmpty && zodiac != '-';
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
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF51A2FF), Color(0xFF155DFC)],
              ),
              boxShadow: [BoxShadow(color: Color(0x4D3B82F6), blurRadius: 12)],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '궁합 결과',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '나와 $name의 케미',
            style: const TextStyle(
              color: Color(0xFF8EC5FF),
              fontSize: 12,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x14FFFFFF), width: 0.8),
            ),
            child: Column(
              children: [
                Text(
                  '$totalScore%',
                  style: GoogleFonts.rationale(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                    letterSpacing: -0.2,
                  ),
                ),
                if (showZodiac) ...[
                  const SizedBox(height: 4),
                  Text(
                    zodiac,
                    style: const TextStyle(
                      color: Color(0xFF8EC5FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      '최고 궁합 항목',
                      style: TextStyle(
                        color: Color(0xFF8EC5FF),
                        fontSize: 13,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$topLabel $topScore%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '궁합 요약',
                        style: TextStyle(
                          color: Color(0xFF8EC5FF),
                          fontSize: 13,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary,
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
          ),
        ],
      ),
    );
  }
}
