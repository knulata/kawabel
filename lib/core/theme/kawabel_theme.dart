import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Color tokens
// ---------------------------------------------------------------------------
class KColors {
  KColors._();

  static const green = Color(0xFF4CAF50);
  static const greenDark = Color(0xFF388E3C);
  static const greenLight = Color(0xFF81C784);
  static const orange = Color(0xFFFF9800);
  static const blue = Color(0xFF2196F3);
  static const red = Color(0xFFE53935);
  static const purple = Color(0xFF9C27B0);

  static const surface = Color(0xFFF5F9F5);
  static const surfaceWarm = Color(0xFFFFF8E1);
  static const surfaceOrange = Color(0xFFFFF3E0);

  static const textDark = Color(0xFF212121);
  static const textMedium = Color(0xFF616161);
  static const textLight = Color(0xFF9E9E9E);

  // Gradient used on login and splash
  static const greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [greenLight, green, greenDark],
  );
}

// ---------------------------------------------------------------------------
// Spacing
// ---------------------------------------------------------------------------
class KSpace {
  KSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ---------------------------------------------------------------------------
// Border radii
// ---------------------------------------------------------------------------
class KRadius {
  KRadius._();

  static final sm = BorderRadius.circular(8);
  static final md = BorderRadius.circular(12);
  static final lg = BorderRadius.circular(16);
  static final xl = BorderRadius.circular(20);
  static final xxl = BorderRadius.circular(24);
  static final full = BorderRadius.circular(999);
}

// ---------------------------------------------------------------------------
// Responsive breakpoints
// ---------------------------------------------------------------------------
enum ScreenSize { compact, medium, expanded, large }

class Responsive {
  Responsive._();

  static ScreenSize of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) return ScreenSize.compact;
    if (w < 840) return ScreenSize.medium;
    if (w < 1200) return ScreenSize.expanded;
    return ScreenSize.large;
  }

  static bool isCompact(BuildContext context) =>
      of(context) == ScreenSize.compact;

  static bool isTabletOrLarger(BuildContext context) {
    final s = of(context);
    return s == ScreenSize.medium ||
        s == ScreenSize.expanded ||
        s == ScreenSize.large;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.compact:
        return const EdgeInsets.all(16);
      case ScreenSize.medium:
        return const EdgeInsets.all(24);
      case ScreenSize.expanded:
      case ScreenSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
  }

  static int gridColumns(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.compact:
        return 2;
      case ScreenSize.medium:
        return 3;
      case ScreenSize.expanded:
      case ScreenSize.large:
        return 4;
    }
  }

  static int actionColumns(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.compact:
        return 1;
      case ScreenSize.medium:
        return 2;
      case ScreenSize.expanded:
      case ScreenSize.large:
        return 3;
    }
  }

  static double actionAspectRatio(BuildContext context) {
    switch (of(context)) {
      case ScreenSize.compact:
        return 2.4;
      case ScreenSize.medium:
        return 1.8;
      case ScreenSize.expanded:
      case ScreenSize.large:
        return 1.6;
    }
  }
}
