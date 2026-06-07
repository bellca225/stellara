import 'package:flutter/material.dart';

import '../widgets/star_field.dart';

class AppColors {
  // 다크 우주 테마
  static const Color background = Color(0xFF0A0A1F);
  static const Color backgroundEnd = Color(0xFF08235F);
  static const Color surface = Color(0xFF0D1B3E);
  static const Color glass = Color(0x1F51A2FF);
  static const Color glassBorder = Color(0x3351A2FF);
  static const Color primary = Color(0xFF1A5FD4);
  static const Color primaryLight = Color(0xFF51A2FF);

  // 텍스트
  static const Color ink = Color(0xFFFFFFFF);
  static const Color inkMuted = Color(0xFFB0C4DE);
  static const Color inkSubtle = Color(0xFF6B8BB5);

  // 기존 호환
  static const Color line = Color(0x3351A2FF);
  static const Color paper = Color(0xFF0D1B3E);
  static const Color canvas = Color(0xFF0A0A1F);
  static const Color skeleton = Color(0xFF1A2E5A);
}

class AppRadius {
  static const double card = 16.0;
  static const double chip = 999.0;
  static const double button = 30.0;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

ThemeData buildAppTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.ink,
    secondary: AppColors.primaryLight,
    onSecondary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: const Color(0xFFFF6B6B),
    onError: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: NoSplash.splashFactory,
    fontFamily: null,

    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: AppColors.ink,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.15,
      ),
      titleLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(color: AppColors.ink, fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(
        color: AppColors.inkMuted,
        fontSize: 13,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.ink,
        elevation: 0,
        // Size.fromHeight(52) sets width=double.infinity, which breaks
        // buttons placed directly inside Row/Flex children.
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.glassBorder, width: 1),
        // Keep the 52px tap target height without forcing infinite width.
        minimumSize: const Size(64, 52),
        backgroundColor: AppColors.glass,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glass,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.inkSubtle),
      labelStyle: const TextStyle(color: AppColors.inkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.glassBorder,
      thickness: 1,
      space: 1,
    ),

    cardTheme: CardThemeData(
      color: AppColors.glass,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D1B3E),
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.inkSubtle,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0D1B3E),
      indicatorColor: AppColors.glass,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: AppColors.inkMuted, fontSize: 12),
      ),
    ),
  );
}

// 공통 배경 위젯
//
// 상위(예: AppShell)에 이미 StarBackground가 있으면 배경/별을 중복으로 그리지
// 않고 child만 통과시킨다. 덕분에 탭 페이지들이 각자 StarBackground를 써도
// 실제 별빛은 AppShell의 단일 레이어에서만 그려져, 모든 탭(마이페이지 포함)에
// 동일하게 보이고 성능도 절약된다.
class StarBackground extends StatelessWidget {
  const StarBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_StarBackgroundScope.of(context)) {
      // 이미 상위에 별 배경이 있음 → 그대로 통과 (투명)
      return child;
    }
    return _StarBackgroundScope(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A1F),
                Color(0xFF0F1729),
                Color(0xFF1E3A8A),
              ],
              stops: [0.0, 0.3, 1.0],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 은은한 트윙클 별 애니메이션 (전 페이지 공통)
              const Positioned.fill(child: StarField()),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// StarBackground 중첩 감지용 마커.
class _StarBackgroundScope extends InheritedWidget {
  const _StarBackgroundScope({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StarBackgroundScope>() != null;

  @override
  bool updateShouldNotify(_StarBackgroundScope oldWidget) => false;
}

// 글래스 카드 위젯
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: child,
    );
  }
}
