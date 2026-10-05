import 'package:flutter/material.dart';

/// Vereinsgrün aus dem Logo des Junggesellenclubs Ellierode.
const Color kClubGreen = Color(0xFF026F40);

const String kClubLogo = 'assets/logo/jgc_logo.png';

final ThemeData clubTheme = () {
  final scheme = ColorScheme.fromSeed(
    seedColor: kClubGreen,
    primary: kClubGreen,
    onPrimary: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: kClubGreen,
      foregroundColor: Colors.white,
    ),
    // Tab-Leisten sitzen immer auf grünem Grund (AppBar bzw. Tablet-Leiste).
    tabBarTheme: const TabBarThemeData(
      labelColor: Colors.white,
      unselectedLabelColor: Color(0xCCFFFFFF),
      indicatorColor: Colors.white,
      dividerColor: Colors.transparent,
    ),
  );
}();
