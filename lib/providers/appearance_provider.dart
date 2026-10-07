import 'dart:async';

import 'package:flutter/material.dart';

import '../services/app_storage.dart';

/// Darstellung und Bedienung: hell/dunkel (Standard: wie am Handy), Bilder
/// oder Emojis auf den Kacheln und ob zwischen Speisen und Getränken
/// gewischt werden darf. Wird gespeichert.
class AppearanceProvider extends ChangeNotifier {
  final AppStorage? _storage;
  ThemeMode _themeMode;
  bool _swipeTabs;
  bool _showImages;

  AppearanceProvider({AppStorage? storage})
      : _storage = storage,
        _themeMode = ThemeMode.values.asNameMap()[storage?.loadThemeMode()] ?? ThemeMode.system,
        _swipeTabs = storage?.loadSwipeTabs() ?? true,
        _showImages = storage?.loadShowImages() ?? true;

  ThemeMode get themeMode => _themeMode;

  /// Wechsel zwischen Speisen und Getränken auch per Wischen. Aus: nur über
  /// die Reiter oben, damit beim Verkaufen nichts versehentlich umspringt.
  bool get swipeTabs => _swipeTabs;

  /// Bilder (gezeichnet oder eigenes Foto) statt Emojis auf den Kacheln.
  bool get showImages => _showImages;

  void setShowImages(bool value) {
    if (value == _showImages) return;
    _showImages = value;
    notifyListeners();
    _save(_storage?.saveShowImages(value));
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    _save(_storage?.saveThemeMode(mode.name));
  }

  void setSwipeTabs(bool value) {
    if (value == _swipeTabs) return;
    _swipeTabs = value;
    notifyListeners();
    _save(_storage?.saveSwipeTabs(value));
  }

  /// Ein Fehler beim Schreiben soll die Kasse nicht stören.
  void _save(Future<void>? write) {
    if (write == null) return;
    unawaited(write.catchError((Object e) => debugPrint('Speichern fehlgeschlagen: $e')));
  }
}
