import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_storage.dart';

/// Darstellung: automatisch wie am Handy eingestellt (Standard), hell oder
/// dunkel. Die Wahl wird gespeichert.
class AppearanceProvider extends ChangeNotifier {
  final AppStorage? _storage;
  ThemeMode _themeMode;

  AppearanceProvider({AppStorage? storage})
      : _storage = storage,
        _themeMode = ThemeMode.values.asNameMap()[storage?.loadThemeMode()] ?? ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final write = _storage?.saveThemeMode(mode.name);
    if (write == null) return;
    // Ein Fehler beim Schreiben soll die Kasse nicht stören.
    unawaited(write.catchError((Object e) => debugPrint('Speichern fehlgeschlagen: $e')));
  }
}
