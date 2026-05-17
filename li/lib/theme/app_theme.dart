import 'package:flutter/material.dart';

// ── Palette ────────────────────────────────────────────────────────────────
class LiovaColors {
  LiovaColors._();

  static const rose       = Color(0xFFE8A598);
  static const roseDark   = Color(0xFFD4796A);
  static const rosePale   = Color(0xFFFDF0EE);
  static const roseMid    = Color(0xFFF5D5CF);

  static const cream      = Color(0xFFFFF8F5);
  static const card       = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFFDF5F2);

  static const teal       = Color(0xFF2CB5A0);
  static const tealDark   = Color(0xFF1A8F7D);
  static const tealPale   = Color(0xFFE0F5F2);

  static const textDark   = Color(0xFF1A1A2E);
  static const textMid    = Color(0xFF5A5A72);
  static const textLight  = Color(0xFF9B9BAE);

  static const good       = Color(0xFF4CAF82);
  static const goodBg     = Color(0xFFE8F7F0);
  static const moderate   = Color(0xFFF0A03A);
  static const moderateBg = Color(0xFFFFF3E0);
  static const notGood    = Color(0xFFE05C5C);
  static const notGoodBg  = Color(0xFFFFEBEB);

  static const divider    = Color(0xFFF0E8E5);
  static const shadow     = Color(0x14000000);
}

// ── Typography ─────────────────────────────────────────────────────────────
class LiovaText {
  LiovaText._();

  static const heading1 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: LiovaColors.textDark, letterSpacing: -0.5,
  );
  static const heading2 = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: LiovaColors.textDark,
  );
  static const heading3 = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: LiovaColors.textDark,
  );
  static const body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: LiovaColors.textMid, height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: LiovaColors.textLight,
  );
  static const label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// ── Shared decorations ────────────────────────────────────────────────────
class LiovaDecorations {
  LiovaDecorations._();

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
    color: LiovaColors.card,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: LiovaColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
    ],
  );

  static BoxDecoration input = BoxDecoration(
    color: LiovaColors.rosePale,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: LiovaColors.roseMid),
  );
}

// ── Theme ─────────────────────────────────────────────────────────────────
ThemeData liovaTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: LiovaColors.bg,
    fontFamily: 'Nunito',
    colorScheme: ColorScheme.fromSeed(
      seedColor: LiovaColors.rose,
      brightness: Brightness.light,
    ).copyWith(
      primary: LiovaColors.rose,
      secondary: LiovaColors.teal,
      surface: LiovaColors.card,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: LiovaColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: LiovaColors.textDark),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: LiovaColors.textDark,
        fontFamily: 'Nunito',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LiovaColors.rose,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LiovaColors.rose,
        side: const BorderSide(color: LiovaColors.roseMid, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LiovaColors.rosePale,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LiovaColors.roseMid),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LiovaColors.roseMid),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: LiovaColors.rose, width: 1.5),
      ),
      labelStyle: const TextStyle(color: LiovaColors.textMid, fontFamily: 'Nunito'),
      hintStyle: const TextStyle(color: LiovaColors.textLight, fontFamily: 'Nunito'),
    ),
    dividerColor: LiovaColors.divider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: LiovaColors.card,
      selectedItemColor: LiovaColors.rose,
      unselectedItemColor: LiovaColors.textLight,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// ── Suitability badge helpers ─────────────────────────────────────────────
Color suitabilityColor(String suitability) {
  switch (suitability.toLowerCase()) {
    case 'good': return LiovaColors.good;
    case 'not good':
    case 'not recommended': return LiovaColors.notGood;
    default: return LiovaColors.moderate;
  }
}

Color suitabilityBgColor(String suitability) {
  switch (suitability.toLowerCase()) {
    case 'good': return LiovaColors.goodBg;
    case 'not good':
    case 'not recommended': return LiovaColors.notGoodBg;
    default: return LiovaColors.moderateBg;
  }
}

String suitabilityEmoji(String suitability) {
  switch (suitability.toLowerCase()) {
    case 'good': return '✅';
    case 'not good':
    case 'not recommended': return '🚫';
    default: return '⚠️';
  }
}
