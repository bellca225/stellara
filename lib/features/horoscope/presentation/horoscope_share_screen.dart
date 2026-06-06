import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_saver.dart';
import '../../../core/widgets/glass.dart';
import '../domain/horoscope.dart';

/// 오늘의 운세 공유 화면.
/// 미리보기 카드 + (1) 스크린샷으로 저장 (2) SNS에 텍스트 공유.
class HoroscopeShareScreen extends StatefulWidget {
  const HoroscopeShareScreen({super.key, required this.horoscope});

  final Horoscope horoscope;

  @override
  State<HoroscopeShareScreen> createState() => _HoroscopeShareScreenState();
}

class _HoroscopeShareScreenState extends State<HoroscopeShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false;

  String get _dateStr => DateFormat('yyyy년 M월 d일').format(widget.horoscope.date);

  String _luckyNumbers() {
    final n = widget.horoscope.luckyNumbers;
    return n.isEmpty ? '-' : n.join(', ');
  }

  String _luckyColor() {
    final c = widget.horoscope.luckyColor.trim();
    return c.isEmpty ? '-' : c;
  }

  String? _luckyPlace() {
    final p = widget.horoscope.luckyPlace?.trim();
    return (p == null || p.isEmpty) ? null : p;
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
        'stellara_horoscope.png',
        shareText: '✨ Stellara 오늘의 운세',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 저장했어요.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 저장에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _shareText() async {
    final h = widget.horoscope;
    final fallback =
        '✨ 오늘의 운세 ($_dateStr)\n\n${h.summary}\n\n'
        '🎨 행운 색상: ${_luckyColor()}\n'
        '🔢 행운 숫자: ${_luckyNumbers()}\n'
        '#Stellara #오늘의운세';
    final text = h.shareText.trim().isNotEmpty
        ? '${h.shareText.trim()}\n\n$fallback'
        : fallback;
    try {
      await Share.share(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유를 지원하지 않는 환경이에요.')),
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
                        child: _HoroscopeShareCard(
                          dateStr: _dateStr,
                          summary: widget.horoscope.summary,
                          luckyNumber: _luckyNumbers(),
                          luckyColor: _luckyColor(),
                          luckyPlace: _luckyPlace(),
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

class _HoroscopeShareCard extends StatelessWidget {
  const _HoroscopeShareCard({
    required this.dateStr,
    required this.summary,
    required this.luckyNumber,
    required this.luckyColor,
    required this.luckyPlace,
  });

  final String dateStr;
  final String summary;
  final String luckyNumber;
  final String luckyColor;
  final String? luckyPlace;

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
            '우주의 신비를 탐험하세요',
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
            child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            '오늘의 운세',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  style: const TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 15,
                    height: 1.6,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0x1FFFFFFF), height: 1),
                const SizedBox(height: 14),
                _LuckyRow(label: '행운의 숫자', value: luckyNumber),
                const SizedBox(height: 8),
                _LuckyRow(label: '행운의 색상', value: luckyColor),
                if (luckyPlace != null) ...[
                  const SizedBox(height: 8),
                  _LuckyRow(label: '행운의 장소', value: luckyPlace!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LuckyRow extends StatelessWidget {
  const _LuckyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8EC5FF),
            fontSize: 13,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
