import 'package:flutter/material.dart';

/// Vereinsgrün aus dem Logo des Junggesellenclubs Ellierode.
const Color kClubGreen = Color(0xFF026F40);

const String kClubLogo = 'assets/logo/jgc_logo.png';

const String kAppName = 'Knülle Kalkulieren - JGC';

final ThemeData clubTheme = _clubTheme(Brightness.light);

/// Dunkelmodus: dunkle Flächen, Leisten in gedecktem Vereinsgrün.
final ThemeData clubDarkTheme = _clubTheme(Brightness.dark);

ThemeData _clubTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = light
      ? ColorScheme.fromSeed(seedColor: kClubGreen, primary: kClubGreen, onPrimary: Colors.white)
      : ColorScheme.fromSeed(seedColor: kClubGreen, brightness: Brightness.dark);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: light ? kClubGreen : scheme.primaryContainer,
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
}
