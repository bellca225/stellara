// lib/features/astrology/presentation/natal_chart_painter.dart
//
// 360° 출생 차트를 흑백으로 그리는 CustomPainter.
//
// 좌표계 메모
// - 점성술 차트는 보통 "ascendant 가 9시 방향"이 되도록 회전한다.
// - Flutter Canvas 의 0 rad 은 3시 방향 → 그래서 -π 만큼 더 돌려 9시로 맞춘다.
// - 또한 황도는 반시계 방향으로 증가하므로, degree 에 -1 을 곱한다.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/natal_chart.dart';

class NatalChartPainter extends CustomPainter {
  NatalChartPainter(this.chart);
  final NatalChart chart;

  static const _zodiac = [
    '양', '황', '쌍', '게', '사', '처', '천', '전', '궁', '염', '병', '고',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 8;

    final outer = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 외곽 원과 내곽 원.
    canvas.drawCircle(c, r, outer);
    canvas.drawCircle(c, r * 0.78, inner);
    canvas.drawCircle(c, r * 0.55, inner);

    // 12 개 별자리 칸 구분선.
    for (var i = 0; i < 12; i++) {
      final angle = _toCanvasAngle(i * 30.0);
      final p1 = c + Offset(math.cos(angle) * r * 0.78, math.sin(angle) * r * 0.78);
      final p2 = c + Offset(math.cos(angle) * r, math.sin(angle) * r);
      canvas.drawLine(p1, p2, inner);
      // 별자리 약자 표기.
      _drawText(
        canvas,
        _zodiac[i],
        c + Offset(math.cos(angle - math.pi / 12) * r * 0.88,
            math.sin(angle - math.pi / 12) * r * 0.88),
        size: 10,
        weight: FontWeight.w600,
      );
    }

    // 하우스 cusp (있으면 그린다).
    final cuspPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (final h in chart.houses) {
      final angle = _toCanvasAngle(h.degree);
      final p1 = c + Offset(math.cos(angle) * r * 0.55, math.sin(angle) * r * 0.55);
      final p2 = c + Offset(math.cos(angle) * r * 0.78, math.sin(angle) * r * 0.78);
      canvas.drawLine(p1, p2, cuspPaint);
    }

    // 행성 점 + 라벨.
    final planetPaint = Paint()..color = AppColors.ink;
    for (final p in chart.planets) {
      final angle = _toCanvasAngle(p.degree);
      final pos = c + Offset(math.cos(angle) * r * 0.66, math.sin(angle) * r * 0.66);
      canvas.drawCircle(pos, 3, planetPaint);
      _drawText(
        canvas,
        _glyph(p.name),
        pos + const Offset(0, -14),
        size: 11,
        weight: FontWeight.w700,
      );
    }

    // 어스펙트 선 (안쪽 원에서 행성 두 점을 잇는다).
    final aspectPaint = Paint()
      ..color = AppColors.inkSubtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (final a in chart.aspects) {
      final pa = chart.planets.where((p) => p.name == a.planetA).toList();
      final pb = chart.planets.where((p) => p.name == a.planetB).toList();
      if (pa.isEmpty || pb.isEmpty) continue;
      final angA = _toCanvasAngle(pa.first.degree);
      final angB = _toCanvasAngle(pb.first.degree);
      final p1 = c + Offset(math.cos(angA) * r * 0.55, math.sin(angA) * r * 0.55);
      final p2 = c + Offset(math.cos(angB) * r * 0.55, math.sin(angB) * r * 0.55);
      canvas.drawLine(p1, p2, aspectPaint);
    }
  }

  /// 점성술 degree(0=Aries 시작, 반시계) → Flutter Canvas 각도.
  /// Ascendant(0°) 를 9시 방향으로 두려고 -π 만큼 회전.
  double _toCanvasAngle(double zodiacDeg) {
    final rad = zodiacDeg * math.pi / 180.0;
    return math.pi - rad;
  }

  /// 일반적인 점성술 행성 약자(영문 첫글자). 폰트 의존도 줄이려고 텍스트로 표기.
  String _glyph(String planet) {
    switch (planet.toLowerCase()) {
      case 'sun':
        return '태';
      case 'moon':
        return '달';
      case 'mercury':
        return '수';
      case 'venus':
        return '금';
      case 'mars':
        return '화';
      case 'jupiter':
        return '목';
      case 'saturn':
        return '토';
      case 'uranus':
        return '천';
      case 'neptune':
        return '해';
      case 'pluto':
        return '명';
      default:
        return planet.substring(0, math.min(1, planet.length));
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    double size = 11,
    FontWeight weight = FontWeight.w400,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: size,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant NatalChartPainter old) => old.chart != chart;
}
