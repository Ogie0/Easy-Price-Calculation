import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

/// Speichert Sortiment (Preise, Sichtbarkeit, Pfand, eigene Positionen),
/// Pfandwert und Darstellung lokal auf dem Gerät, damit alles einen Neustart
/// übersteht.
class AppStorage {
  static const _articlesKey = 'articles_v2';
  static const _depositKey = 'deposit_cents';
  static const _themeModeKey = 'theme_mode';
  static const _swipeTabsKey = 'swipe_tabs';
  static const _showImagesKey = 'show_images';
  static const _pendingImageKey = 'pending_image_article';
  static const _setupHintKey = 'setup_hint_dismissed';

  /// Ältere Versionen haben nur die Preise einzeln gespeichert.
  static const _legacyPricePrefix = 'price_cents_';

  final SharedPreferences _prefs;

  AppStorage(this._prefs);

  static Future<AppStorage> open() async =>
      AppStorage(await SharedPreferences.getInstance());

  int? loadDeposit() => _prefs.getInt(_depositKey);

  /// Gespeichertes Sortiment oder null, wenn noch nichts gespeichert wurde
  /// (oder die Daten unlesbar sind). Einzelne unlesbare Einträge werden
  /// übersprungen, damit nicht das ganze Sortiment verloren geht.
  List<Article>? loadArticles() {
    final raw = _prefs.getString(_articlesKey);
    if (raw == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! List) return null;
    final articles = <Article>[];
    for (final entry in decoded) {
      try {
        articles.add(Article.fromJson((entry as Map).cast<String, Object?>()));
      } on Object {
        // Unlesbarer Eintrag: überspringen.
      }
    }
    return articles;
  }

  int? loadLegacyPrice(String articleId) => _prefs.getInt('$_legacyPricePrefix$articleId');

  Future<void> saveDeposit(int cents) => _prefs.setInt(_depositKey, cents);

  Future<void> saveArticles(List<Article> articles) =>
      _prefs.setString(_articlesKey, jsonEncode([for (final a in articles) a.toJson()]));

  /// Name des gewählten ThemeMode (`system`, `light`, `dark`) oder null.
  String? loadThemeMode() => _prefs.getString(_themeModeKey);

  Future<void> saveThemeMode(String name) => _prefs.setString(_themeModeKey, name);

  bool? loadSwipeTabs() => _prefs.getBool(_swipeTabsKey);

  Future<void> saveSwipeTabs(bool value) => _prefs.setBool(_swipeTabsKey, value);

  bool? loadShowImages() => _prefs.getBool(_showImagesKey);

  Future<void> saveShowImages(bool value) => _prefs.setBool(_showImagesKey, value);

  /// Ob der Hinweis „Sortiment übernehmen“ auf einem neuen Gerät weggeklickt
  /// wurde.
  bool loadSetupHintDismissed() => _prefs.getBool(_setupHintKey) ?? false;

  Future<void> saveSetupHintDismissed() => _prefs.setBool(_setupHintKey, true);

  /// Eigene Fotos im Browser (iPhone), Base64-kodiert, je Foto ein Eintrag.
  static const _photoPrefix = 'photo_';

  String? loadPhoto(String key) => _prefs.getString('$_photoPrefix$key');

  Future<void> savePhoto(String key, String base64) async {
    if (!await _prefs.setString('$_photoPrefix$key', base64)) {
      throw StateError('Foto konnte nicht gespeichert werden');
    }
  }

  Future<void> deletePhoto(String key) => _prefs.remove('$_photoPrefix$key');

  /// Artikel, für den gerade ein Foto ausgewählt wird (sonst null).
  String? loadPendingImage() => _prefs.getString(_pendingImageKey);

  Future<void> savePendingImage(String? articleId) => articleId == null
      ? _prefs.remove(_pendingImageKey)
      : _prefs.setString(_pendingImageKey, articleId);
}
