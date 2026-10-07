import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/default_articles.dart';
import '../services/app_storage.dart';

/// Verwaltet das Sortiment (Preise, Sichtbarkeit, Pfand, eigene Positionen)
/// und den Pfandwert. Mit [storage] werden Änderungen gespeichert und beim
/// Start wieder geladen.
class CatalogProvider extends ChangeNotifier {
  final List<Article> _articles;
  final List<Article> _defaults;
  final AppStorage? _storage;
  int _depositCents;
  int _nextCustomId = 0;

  CatalogProvider({
    List<Article> articles = kDefaultArticles,
    int depositCents = kDefaultDepositCents,
    AppStorage? storage,
  })  : _storage = storage,
        _defaults = articles,
        _articles = _load(articles, storage),
        _depositCents = storage?.loadDeposit() ?? depositCents;

  /// Gespeichertes Sortiment in gespeicherter Reihenfolge; Standardartikel
  /// behalten Namen und Emoji aus dem Code, neue Standardartikel (z. B. nach
  /// einem Update) kommen hinten dazu.
  static List<Article> _load(List<Article> defaults, AppStorage? storage) {
    final stored = storage?.loadArticles();
    if (stored == null) {
      return [
        for (final a in defaults)
          a.copyWith(priceCents: storage?.loadLegacyPrice(a.id) ?? a.priceCents),
      ];
    }
    return _merge(defaults, stored);
  }

  static List<Article> _merge(List<Article> defaults, List<Article> stored) {
    final defaultsById = {for (final a in defaults) a.id: a};
    final result = <Article>[];
    for (final saved in stored) {
      if (saved.custom) {
        result.add(saved);
      } else if (defaultsById.remove(saved.id) case final def?) {
        result.add(def.copyWith(
          priceCents: saved.priceCents,
          hasDeposit: saved.hasDeposit,
          visible: saved.visible,
          imagePath: saved.imagePath,
        ));
      }
    }
    return result..addAll(defaultsById.values);
  }

  /// Übernimmt ein Sortiment von einem anderen Gerät (QR-Code): Preise,
  /// Pfand, Sichtbarkeit, Reihenfolge und eigene Positionen. Eigene Fotos
  /// dieses Geräts bleiben bei den Artikeln, die es weiterhin gibt. Liefert
  /// die Fotos, die nicht mehr gebraucht werden.
  List<String> replaceAll(List<Article> imported, int depositCents) {
    if (depositCents < 0) {
      throw ArgumentError.value(depositCents, 'depositCents', 'darf nicht negativ sein');
    }
    final photos = {
      for (final a in _articles)
        if (a.imagePath != null) a.id: a.imagePath!,
    };
    final merged = [
      for (final a in _merge(_defaults, imported))
        switch (photos.remove(a.id)) {
          final photo? => a.copyWith(imagePath: photo),
          null => a.copyWith(clearImage: true),
        },
    ];
    _articles
      ..clear()
      ..addAll(merged);
    _depositCents = depositCents;
    _persist();
    _save(_storage?.saveDeposit(depositCents));
    notifyListeners();
    return photos.values.toList();
  }

  /// Alle Artikel in ihrer Reihenfolge (z. B. zum Teilen per QR-Code).
  List<Article> get all => List.unmodifiable(_articles);

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

  /// Artikel oder null, wenn es ihn (nicht mehr) gibt.
  Article? articleOrNull(String id) {
    for (final a in _articles) {
      if (a.id == id) return a;
    }
    return null;
  }

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

  /// Setzt ein eigenes Foto für die Kachel oder entfernt es ([path] null).
  void setImage(String articleId, String? path) {
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) {
      throw ArgumentError.value(articleId, 'articleId', 'unbekannter Artikel');
    }
    final old = _articles[index];
    if (old.imagePath == path) return;
    _articles[index] = old.copyWith(imagePath: path, clearImage: path == null);
    _persist();
    notifyListeners();
  }

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

  /// Ändert eine selbst angelegte Position. Ein leeres [emoji] entfernt das
  /// eigene Emoji.
  void updateCustom(
    String articleId, {
    required String name,
    required ArticleCategory category,
    required int priceCents,
    required bool hasDeposit,
    String? emoji,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'darf nicht leer sein');
    if (priceCents < 0) {
      throw ArgumentError.value(priceCents, 'priceCents', 'darf nicht negativ sein');
    }
    final index = _articles.indexWhere((a) => a.id == articleId && a.custom);
    if (index == -1) {
      throw ArgumentError.value(articleId, 'articleId', 'keine eigene Position');
    }
    final cleanEmoji = emoji?.trim() ?? '';
    final old = _articles[index];
    final updated = old.copyWith(
      name: trimmed,
      category: category,
      priceCents: priceCents,
      hasDeposit: hasDeposit,
      emoji: cleanEmoji.isEmpty ? null : cleanEmoji,
      clearEmoji: cleanEmoji.isEmpty,
    );
    _articles.removeAt(index);
    if (updated.category == old.category) {
      _articles.insert(index, updated);
    } else {
      // Neue Kategorie: hinten anstellen.
      _articles.add(updated);
    }
    _persist();
    notifyListeners();
  }

  /// Verschiebt einen Artikel innerhalb seiner Kategorie (auch ausgeblendete
  /// zählen mit). [newIndex] ist die Zielposition nach dem Herausnehmen.
  void moveArticle(ArticleCategory category, int oldIndex, int newIndex) {
    final ordered = allOf(category);
    if (oldIndex < 0 || oldIndex >= ordered.length) return;
    final target = newIndex.clamp(0, ordered.length - 1);
    if (target == oldIndex) return;
    ordered.insert(target, ordered.removeAt(oldIndex));

    // Die Plätze der Kategorie in der Gesamtliste neu belegen.
    var next = 0;
    for (var i = 0; i < _articles.length; i++) {
      if (_articles[i].category == category) _articles[i] = ordered[next++];
    }
    _persist();
    notifyListeners();
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
