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
}
