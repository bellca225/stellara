// lib/core/theme/app_theme.dart
//
// 9주차 흑백(monochrome) 테마.
//
// 설계 원칙
// 1. 컬러는 잉크(거의 검정), 페이퍼(거의 흰색), 라인(중간 회색) 3톤만.
//    → 배치/타이포만으로 정보 위계를 보여 주려는 의도.
// 2. 다크 모드는 9주차 범위에서 제외 (기획서에도 없음). ThemeMode.light 고정.
// 3. 컴포넌트별 테마(예: ElevatedButtonTheme)도 같이 정의해
//    화면에서 매번 스타일을 새로 쓰지 않도록 한다.
//
// 추후 13주차에 컬러 테마로 복구할 때는 이 파일만 교체하면 되도록
// 모든 색을 Theme.of(context) 또는 ColorScheme 으로 참조하는 것을 권장.

import 'package:flutter/material.dart';

class AppColors {
  // ── 흑백 팔레트 ──────────────────────────────
  /// 텍스트와 강조용 검정 (완전 #000은 너무 강하므로 #111).
  static const Color ink = Color(0xFF111111);

  /// 보조 텍스트용 짙은 회색.
  static const Color inkMuted = Color(0xFF6B6B6B);

  /// 비활성/부가 정보용 옅은 회색.
  static const Color inkSubtle = Color(0xFFA0A0A0);

  /// 카드/구분선용 라인 색.
  static const Color line = Color(0xFFE5E5E5);

  /// 카드/패널 배경.
  static const Color paper = Color(0xFFFFFFFF);

  /// 화면 전체 배경. 살짝 회색 톤이라 패널의 흰색이 떠 보이게 한다.
  static const Color canvas = Color(0xFFF6F6F6);

  /// 비활성/스켈레톤 배경.
  static const Color skeleton = Color(0xFFEDEDED);
}

class AppRadius {
  static const double card = 16.0;
  static const double chip = 999.0;
  static const double button = 12.0;
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
  // ColorScheme.fromSeed 로 만들면 Material 위젯들이 자동으로 흑백을 입는다.
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.ink,
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.paper,
    secondary: AppColors.ink,
    onSecondary: AppColors.paper,
    surface: AppColors.paper,
    onSurface: AppColors.ink,
    error: AppColors.ink, // 흑백이라 에러도 검정으로
    onError: AppColors.paper,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.canvas,
    splashFactory: NoSplash.splashFactory, // 흑백 미니멀 톤 유지
    fontFamily: null, // 시스템 폰트(SF/Roboto)로 깔끔하게

    // 텍스트 위계는 굵기와 크기만으로.
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
      bodyLarge: TextStyle(
        color: AppColors.ink,
        fontSize: 15,
        height: 1.45,
      ),
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
      backgroundColor: AppColors.canvas,
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
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink, width: 1),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      hintStyle: const TextStyle(color: AppColors.inkSubtle),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),

    cardTheme: CardThemeData(
      color: AppColors.paper,
      elevation: 0,
      surfaceTintColor: AppColors.paper,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
  );
}
