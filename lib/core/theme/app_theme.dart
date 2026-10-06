import 'package:flutter/material.dart';

/// Brand colors and Syriac typography for BET KANU Reader.
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xff1c568a);
  static const Color accentOrange = Color(0xfff7a521);
  static const Color softBlue = Color.fromARGB(255, 173, 203, 228);
  static const Color softOrange = Color.fromARGB(255, 240, 228, 208);
  static const Color mutedOrange = Color.fromARGB(255, 176, 147, 119);
  static const Color loaderBlue = Color.fromARGB(255, 83, 158, 212);
  static const Color mutedGray = Color.fromARGB(255, 139, 150, 160);
  static const Color deepGray = Color.fromARGB(255, 114, 123, 130);
  static const Color bodyGray = Color.fromARGB(255, 149, 163, 175);
  static const Color dividerGray = Color.fromARGB(255, 190, 189, 189);
  static const Color bottomIcon = Color.fromARGB(255, 207, 206, 206);
  static const Color disabledGray = Color.fromARGB(255, 226, 224, 222);
  static const Color facebookBg = Color.fromARGB(255, 177, 218, 252);
  static const Color youtubeBg = Color.fromARGB(255, 250, 179, 187);
  static const Color webBg = Color.fromARGB(255, 166, 229, 242);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: false,
      primaryColor: AppColors.primaryBlue,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: AppColors.primaryBlue,
        secondary: AppColors.accentOrange,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'ClassicSyriac',
    );
  }

  /// Font family for Syriac dialect flags from API/XML.
  static String syriacFontFamily(String? textLanguage) {
    switch (textLanguage?.toLowerCase()) {
      case 'western':
        return 'WesternSyriac';
      case 'eastern':
        return 'EasternSyriac';
      default:
        return 'ClassicSyriac';
    }
  }
}
