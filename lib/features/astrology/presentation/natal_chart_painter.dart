// lib/features/astrology/presentation/natal_chart_painter.dart
//
// 360° 출생 차트를 흑백으로 그리는 CustomPainter.
//
// 좌표계 메모
// - house 1 cusp(Ascendant)을 9시 방향에 고정하여 차트를 회전한다.
//   chart.houses 에 house==1 이 있으면 그 degree 를 _ascDeg 로 쓰고,
//   없으면 0(Aries 0°) 을 기준으로 그린다.
// - Flutter Canvas 의 0 rad 은 3시 방향.
//   _toCanvasAngle(zodiacDeg, ascDeg) = π - (zodiacDeg - ascDeg) * π/180
//   → zodiacDeg == ascDeg 이면 angle = π (9시) ✅
//   → 황도는 반시계 방향 증가 → (zodiacDeg - ascDeg) 가 클수록 angle 이 감소(반시계) ✅
// - 행성 라벨 겹침 방지: 인접 행성(±20° 이내)은 위/아래 라벨을 교대한다.
// - paint() 전체를 try-catch 로 감싸 Canvas 오류 시 빈 원만 표시.

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

  // 어스펙트 색상 구분 (AppColors 만 사용 — 디자인 파일 수정 없음).
  static const _aspectHarmony = {'trine', 'sextile'};
  static const _aspectTension = {'square', 'opposition'};

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    try {
      _doPaint(canvas, size);
    } catch (_) {
      // 렌더링 오류 시 원(frame)만 표시하여 빈 화면 방지.
      final c = Offset(size.width / 2, size.height / 2);
      final r = math.min(size.width, size.height) / 2 - 8;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = AppColors.line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  void _doPaint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 8;

    // Ascendant degree (house 1 cusp) 추출. 없으면 0(Aries 0° 기준).
    final ascDeg = _ascendantDeg();

    final outer = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final inner = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 외곽 / 중간 / 내곽 원.
    canvas.drawCircle(c, r, outer);
    canvas.drawCircle(c, r * 0.78, inner);
    canvas.drawCircle(c, r * 0.55, inner);

    // ── 12 별자리 구분선 + 약자 ──────────────────────────────────
    for (var i = 0; i < 12; i++) {
      final divAngle = _toCanvasAngle(i * 30.0, ascDeg);
      final p1 = c + Offset(math.cos(divAngle) * r * 0.78, math.sin(divAngle) * r * 0.78);
      final p2 = c + Offset(math.cos(divAngle) * r, math.sin(divAngle) * r);
      canvas.drawLine(p1, p2, inner);

      // 라벨은 각 칸의 중앙(+15°) 에 배치.
      final labelAngle = _toCanvasAngle(i * 30.0 + 15.0, ascDeg);
      _drawText(
        canvas,
        _zodiac[i],
        c + Offset(
          math.cos(labelAngle) * r * 0.88,
          math.sin(labelAngle) * r * 0.88,
        ),
        size: 10,
        weight: FontWeight.w600,
        color: AppColors.inkMuted,
      );
    }

    // ── 하우스 cusp 선 ───────────────────────────────────────────
    if (chart.houses.isNotEmpty) {
      final cuspPaint = Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (final h in chart.houses) {
        final angle = _toCanvasAngle(h.degree, ascDeg);
        final p1 = c + Offset(math.cos(angle) * r * 0.55, math.sin(angle) * r * 0.55);
        final p2 = c + Offset(math.cos(angle) * r * 0.78, math.sin(angle) * r * 0.78);
        canvas.drawLine(p1, p2, cuspPaint);

        // 4개 앵글 하우스(1, 4, 7, 10)만 번호 표시하여 밀도를 줄임.
        if (h.house % 3 == 1) {
          final numAngle = _toCanvasAngle(h.degree + 5.0, ascDeg);
          _drawText(
            canvas,
            '${h.house}',
            c + Offset(
              math.cos(numAngle) * r * 0.62,
              math.sin(numAngle) * r * 0.62,
            ),
            size: 8,
            color: AppColors.inkSubtle,
          );
        }
      }
    }

    // ── 어스펙트 선 ──────────────────────────────────────────────
    final planetMap = <String, Planet>{
      for (final p in chart.planets) p.name: p,
    };
    for (final a in chart.aspects) {
      final pa = planetMap[a.planetA];
      final pb = planetMap[a.planetB];
      if (pa == null || pb == null) continue;

      final kind = a.aspect.toLowerCase();
      final color = _aspectHarmony.contains(kind)
          ? AppColors.primaryLight.withOpacity(0.45)
          : _aspectTension.contains(kind)
              ? AppColors.inkSubtle.withOpacity(0.35)
              : AppColors.inkSubtle.withOpacity(0.22);

      final aspectPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7;

      final angA = _toCanvasAngle(pa.degree, ascDeg);
      final angB = _toCanvasAngle(pb.degree, ascDeg);
      final p1 = c + Offset(math.cos(angA) * r * 0.55, math.sin(angA) * r * 0.55);
      final p2 = c + Offset(math.cos(angB) * r * 0.55, math.sin(angB) * r * 0.55);
      canvas.drawLine(p1, p2, aspectPaint);
    }

    // ── 행성 점 + 라벨 ───────────────────────────────────────────
    if (chart.planets.isEmpty) {
      _drawText(canvas, '차트 데이터 없음', c, size: 12, color: AppColors.inkMuted);
      return;
    }

    // 라벨 겹침 방지: canvas angle 순으로 정렬 후 ±20° 이내 행성끼리 위/아래 교대.
    final sortedPlanets = [...chart.planets]
      ..sort((a, b) =>
          _toCanvasAngle(a.degree, ascDeg).compareTo(_toCanvasAngle(b.degree, ascDeg)));

    final planetDotPaint = Paint()..color = AppColors.ink;
    double? prevAngle;
    bool labelAbove = true;

    for (final p in sortedPlanets) {
      final angle = _toCanvasAngle(p.degree, ascDeg);
      final pos = c + Offset(
        math.cos(angle) * r * 0.66,
        math.sin(angle) * r * 0.66,
      );

      if (prevAngle != null) {
        final diff = (angle - prevAngle).abs();
        final wrapped = diff > math.pi ? 2 * math.pi - diff : diff;
        if (wrapped < 20 * math.pi / 180) {
          labelAbove = !labelAbove;
        } else {
          labelAbove = true;
        }
      }
      prevAngle = angle;

      canvas.drawCircle(pos, 3.5, planetDotPaint);

      _drawText(
        canvas,
        _glyph(p.name),
        pos + Offset(0, labelAbove ? -15.0 : 15.0),
        size: 11,
        weight: FontWeight.w700,
      );
    }

    // Ascendant 마커 (AC) — 9시 방향 바깥쪽.
    final acAngle = math.pi; // ascDeg - ascDeg = 0 → π, 항상 9시
    final acPos = c + Offset(math.cos(acAngle) * r * 1.04, math.sin(acAngle) * r * 1.04);
    _drawText(canvas, 'AC', acPos, size: 9, weight: FontWeight.w800);
  }

  // ── 헬퍼 ─────────────────────────────────────────────────────────

  /// house 1 cusp degree (0~360). 없으면 0.
  double _ascendantDeg() {
    for (final h in chart.houses) {
      if (h.house == 1) return h.degree;
    }
    return chart.houses.isNotEmpty ? chart.houses.first.degree : 0.0;
  }

  /// 점성술 degree + ascendant offset → Flutter Canvas 라디안.
  double _toCanvasAngle(double zodiacDeg, double ascDeg) {
    final rad = (zodiacDeg - ascDeg) * math.pi / 180.0;
    return math.pi - rad;
  }

  /// 행성 이름 → 한글 약자.
  String _glyph(String planet) {
    switch (planet.toLowerCase()) {
      case 'sun':       return '태';
      case 'moon':      return '달';
      case 'mercury':   return '수';
      case 'venus':     return '금';
      case 'mars':      return '화';
      case 'jupiter':   return '목';
      case 'saturn':    return '토';
      case 'uranus':    return '천';
      case 'neptune':   return '해';
      case 'pluto':     return '명';
      case 'ascendant': return 'AC';
      default:
        return planet.isNotEmpty ? planet[0].toUpperCase() : '?';
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    double size = 11,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color ?? AppColors.ink,
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
