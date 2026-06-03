import 'package:flutter/material.dart';

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
class StarBackground extends StatelessWidget {
  const StarBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1F), Color(0xFF08235F)],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(40, (i) {
            final x = (i * 137.5) % 100;
            final y = (i * 97.3) % 100;
            final size = (i % 3 + 1).toDouble();
            final opacity = (i % 5 + 3) / 10;
            return Positioned(
              left: x / 100 * 400,
              top: y / 100 * 900,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
          child,
        ],
      ),
    );
  }
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
