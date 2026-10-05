import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/default_articles.dart';
import '../services/catalog_storage.dart';

/// Verwaltet das Sortiment (Preise, Sichtbarkeit, Pfand, eigene Positionen)
/// und den Pfandwert. Mit [storage] werden Änderungen gespeichert und beim
/// Start wieder geladen.
class CatalogProvider extends ChangeNotifier {
  final List<Article> _articles;
  final CatalogStorage? _storage;
  int _depositCents;
  int _nextCustomId = 0;

  CatalogProvider({
    List<Article> articles = kDefaultArticles,
    int depositCents = kDefaultDepositCents,
    CatalogStorage? storage,
  })  : _storage = storage,
        _articles = _load(articles, storage),
        _depositCents = storage?.loadDeposit() ?? depositCents;

  /// Standardsortiment mit gespeicherten Änderungen; neue Standardartikel
  /// (z. B. nach einem Update) kommen automatisch dazu.
  static List<Article> _load(List<Article> defaults, CatalogStorage? storage) {
    final stored = storage?.loadArticles();
    if (stored == null) {
      return [
        for (final a in defaults)
          a.copyWith(priceCents: storage?.loadLegacyPrice(a.id) ?? a.priceCents),
      ];
    }
    final byId = {for (final a in stored) a.id: a};
    return [
      for (final a in defaults)
        if (byId[a.id] case final saved?)
          a.copyWith(priceCents: saved.priceCents, hasDeposit: saved.hasDeposit, visible: saved.visible)
        else
          a,
      ...stored.where((a) => a.custom),
    ];
  }

  /// Alle Artikel einer Kategorie, auch ausgeblendete (für die Einstellungen).
  List<Article> allOf(ArticleCategory category) =>
      _articles.where((a) => a.category == category).toList();

  /// Sichtbare Speisen bzw. Getränke für die Kacheln.
  List<Article> get food => _visible(ArticleCategory.food);

  List<Article> get drinks => _visible(ArticleCategory.drink);

  List<Article> _visible(ArticleCategory category) =>
      _articles.where((a) => a.category == category && a.visible).toList();

  int get depositCents => _depositCents;

  Article articleById(String id) => _articles.firstWhere((a) => a.id == id);

  void setPrice(String articleId, int priceCents) {
    if (priceCents < 0) {
      throw ArgumentError.value(priceCents, 'priceCents', 'darf nicht negativ sein');
    }
    _update(articleId, (a) => a.copyWith(priceCents: priceCents));
  }

  void setVisible(String articleId, bool visible) =>
      _update(articleId, (a) => a.copyWith(visible: visible));

  void setHasDeposit(String articleId, bool hasDeposit) =>
      _update(articleId, (a) => a.copyWith(hasDeposit: hasDeposit));

  /// Legt eine frei gestaltete Position an und gibt sie zurück.
  Article addCustom({
    required String name,
    required ArticleCategory category,
    required int priceCents,
    bool hasDeposit = false,
    String? emoji,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'darf nicht leer sein');
    if (priceCents < 0) {
      throw ArgumentError.value(priceCents, 'priceCents', 'darf nicht negativ sein');
    }
    final article = Article(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}_${_nextCustomId++}',
      name: trimmed,
      category: category,
      priceCents: priceCents,
      hasDeposit: hasDeposit,
      custom: true,
      emoji: (emoji == null || emoji.trim().isEmpty) ? null : emoji.trim(),
    );
    _articles.add(article);
    _persist();
    notifyListeners();
    return article;
  }

  /// Löscht eine selbst angelegte Position. Standardartikel lassen sich nur
  /// ausblenden.
  void removeCustom(String articleId) {
    final before = _articles.length;
    _articles.removeWhere((a) => a.id == articleId && a.custom);
    if (_articles.length == before) return;
    _persist();
    notifyListeners();
  }

  void setDeposit(int depositCents) {
    if (depositCents < 0) {
      throw ArgumentError.value(depositCents, 'depositCents', 'darf nicht negativ sein');
    }
    if (_depositCents == depositCents) return;
    _depositCents = depositCents;
    _save(_storage?.saveDeposit(depositCents));
    notifyListeners();
  }

  void _update(String articleId, Article Function(Article) change) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) {
      throw ArgumentError.value(articleId, 'articleId', 'unbekannter Artikel');
    }
    final updated = change(_articles[index]);
    final old = _articles[index];
    if (updated.priceCents == old.priceCents &&
        updated.hasDeposit == old.hasDeposit &&
        updated.visible == old.visible) {
      return;
    }
    _articles[index] = updated;
    _persist();
    notifyListeners();
  }

  void _persist() => _save(_storage?.saveArticles(_articles));

  /// Speichert im Hintergrund; ein Fehler beim Schreiben soll die Kasse
  /// nicht stören, der Wert gilt dann nur bis zum nächsten Neustart.
  void _save(Future<void>? write) {
    if (write == null) return;
    unawaited(write.catchError((Object e) => debugPrint('Speichern fehlgeschlagen: $e')));
  }
}
