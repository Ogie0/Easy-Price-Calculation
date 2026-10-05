import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/default_articles.dart';

/// Verwaltet Artikel, Preise und den Pfandwert.
class CatalogProvider extends ChangeNotifier {
  final List<Article> _articles;
  int _depositCents;

  CatalogProvider({
    List<Article> articles = kDefaultArticles,
    int depositCents = kDefaultDepositCents,
  })  : _articles = List.of(articles),
        _depositCents = depositCents;

  List<Article> get articles => List.unmodifiable(_articles);

  List<Article> get food =>
      _articles.where((a) => a.category == ArticleCategory.food).toList();

  List<Article> get drinks =>
      _articles.where((a) => a.category == ArticleCategory.drink).toList();

  int get depositCents => _depositCents;

  Article articleById(String id) => _articles.firstWhere((a) => a.id == id);

  void setPrice(String articleId, int priceCents) {
    if (priceCents < 0) {
      throw ArgumentError.value(priceCents, 'priceCents', 'darf nicht negativ sein');
    }
    final index = _articles.indexWhere((a) => a.id == articleId);
    if (index == -1) {
      throw ArgumentError.value(articleId, 'articleId', 'unbekannter Artikel');
    }
    if (_articles[index].priceCents == priceCents) return;
    _articles[index] = _articles[index].copyWith(priceCents: priceCents);
    notifyListeners();
  }

  void setDeposit(int depositCents) {
    if (depositCents < 0) {
      throw ArgumentError.value(depositCents, 'depositCents', 'darf nicht negativ sein');
    }
    if (_depositCents == depositCents) return;
    _depositCents = depositCents;
    notifyListeners();
  }
}
