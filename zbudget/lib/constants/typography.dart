import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'System';

  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double base = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xl2 = 24.0;
  static const double xl3 = 28.0;
  static const double xl4 = 32.0;
  static const double xl5 = 40.0;
  static const double xl6 = 48.0;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.8;

  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 40 / 32,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 36 / 28,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    fontFamily: fontFamily,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
    fontFamily: fontFamily,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 22 / 16,
    fontFamily: fontFamily,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 24 / 16,
    fontFamily: fontFamily,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 20 / 14,
    fontFamily: fontFamily,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 16 / 12,
    fontFamily: fontFamily,
  );

  // Missing styles for compatibility
  static const TextStyle headingLarge = h1;
  static const TextStyle headingMedium = h2;
  static const TextStyle headingSmall = h3;
  static const TextStyle bodyLarge = body;
  static const TextStyle bodyMedium = bodySmall;

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 20 / 16,
    fontFamily: fontFamily,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    fontFamily: fontFamily,
  );

  // Text Theme for Material App
  static const TextTheme textTheme = TextTheme(
    displayLarge: h1,
    displayMedium: h2,
    displaySmall: h3,
    headlineLarge: h4,
    headlineMedium: h5,
    headlineSmall: h6,
    bodyLarge: body,
    bodyMedium: bodySmall,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: buttonSmall,
    labelSmall: caption,
  );
}
