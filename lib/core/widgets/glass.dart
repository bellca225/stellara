import 'package:flutter/material.dart';

/// 앱 전체 표준 글라스 그림자 (랜딩 버튼 기준 — 검정 2단, 파란 글로우 없음).
const List<BoxShadow> kGlassShadow = [
  BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 5)),
];

/// 표준 글라스 패널(카드/박스).
///
/// 어두운 반투명 글라스 + 옅은 테두리 + 표준 그림자.
/// 기존 화면들의 카드 디자인을 이 위젯으로 통일한다.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.612),
        boxShadow: kGlassShadow,
      ),
      child: child,
    );
  }
}

/// 표준 글라스 입력 쉘.
///
/// 입력/선택 컨트롤(TextField, 탭 표시 텍스트 등)을 감싸는 글라스 컨테이너.
/// 내부 컨트롤 로직은 호출부가 그대로 유지하고, 외형만 표준화한다.
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.child,
    this.height = 49,
    this.borderRadius = 16,
    this.hasError = false,
    this.alignment,
  });

  final Widget child;
  final double? height;
  final double borderRadius;
  final bool hasError;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x14FFFFFF), Color(0x08FFFFFF)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: hasError ? const Color(0xFFFF6B6B) : const Color(0x1FFFFFFF),
          width: 0.612,
        ),
        boxShadow: kGlassShadow,
      ),
      child: child,
    );
  }
}

/// 앱 전체 표준 글라스 버튼.
///
/// 랜딩(메인) 화면의 버튼 디자인을 기준(standard)으로 한다.
/// - primary: 진한 블루 반투명 글라스
/// - secondary: 어두운(흰색 저알파) 글라스
/// 테두리는 상단이 밝고 아래로 옅어지는 그라데이션 스트로크,
/// 드롭 섀도우 2단으로 깊이를 준다.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = true,
    this.isLoading = false,
    this.leading,
    this.height = 60,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w700,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isLoading;
  final Widget? leading;
  final double height;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isLoading ? 0.75 : 1,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isPrimary
                  ? const [Color(0x592B6FE6), Color(0x592B6FE6)]
                  : const [Color(0x1AFFFFFF), Color(0x1AFFFFFF)],
            ),
            borderRadius: BorderRadius.circular(9999),
            // 상단 밝고 하단 옅어지는 그라데이션 스트로크
            border: const GradientBoxBorder(
              width: 0.7,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x73FFFFFF), Color(0x0FFFFFFF), Color(0x33FFFFFF)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leading != null) ...[leading!, const SizedBox(width: 8)],
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: fontWeight,
                        letterSpacing: -0.2,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 그라데이션 외곽선(stroke)을 그리는 BoxBorder.
/// Flutter 기본 Border는 단색만 지원하므로 shader로 직접 그린다.
class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;
  const GradientBoxBorder({required this.gradient, this.width = 1.0});

  @override
  BorderSide get top => BorderSide.none;
  @override
  BorderSide get bottom => BorderSide.none;
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);
  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = gradient.createShader(rect);
    final rrect = (borderRadius ?? BorderRadius.zero)
        .toRRect(rect)
        .deflate(width / 2); // 외곽선이 영역 안쪽으로 그려지도록
    canvas.drawRRect(rrect, paint);
  }

  @override
  ShapeBorder scale(double t) =>
      GradientBoxBorder(gradient: gradient, width: width * t);
}
