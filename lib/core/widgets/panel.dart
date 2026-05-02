// lib/core/widgets/panel.dart
//
// 흑백 카드/패널 공용 위젯 모음. 화면마다 직접 BoxDecoration을 작성하면
// 디자인이 슬금슬금 어긋나서 통일감이 깨지므로, 한 곳에서 관리한다.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 화면 안에서 정보를 묶어주는 흰색 카드 패널.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// 패널 안에서 작은 단락을 구분할 때 쓰는 헤더.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...(trailing != null ? [trailing!] : const <Widget>[]),
      ],
    );
  }
}

class WireframeHeader extends StatelessWidget {
  const WireframeHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.inkSubtle,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// 키-값을 한 줄로 보여주는 행. (출생 정보, 행성 위치 등 표시용)
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.inkMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 화면 상단에 화면 ID(예: ASTROLOGY-001)와 라벨을 작게 표시한다.
/// 기획서 화면 ID를 시각적으로 추적할 수 있어 시연/디버그에 유용하다.
class ScreenCodeChip extends StatelessWidget {
  const ScreenCodeChip({super.key, required this.code, required this.label});
  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: AppColors.paper,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 비동기 로딩 시 보여줄 흑백 스켈레톤 박스.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 6,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
