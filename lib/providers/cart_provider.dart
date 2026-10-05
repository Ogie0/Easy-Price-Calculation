import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/cart_item.dart';
import 'catalog_provider.dart';

/// Warenkorb inkl. Pfand-Logik.
class CartProvider extends ChangeNotifier {
  final CatalogProvider _catalog;
  final List<CartItem> _items = [];
  int _nextId = 1;

  CartProvider(this._catalog);

  List<CartItem> get items => UnmodifiableListView(_items);

  /// Positionen für die Anzeige: neueste zuerst, Pfand jeweils direkt unter
  /// dem zugehörigen Getränk.
  List<CartItem> get itemsNewestFirst {
    final result = <CartItem>[];
    for (final item in _items.reversed) {
      if (item.type == CartItemType.deposit) continue;
      result
        ..add(item)
        ..addAll(_items.where((d) => d.parentId == item.id));
    }
    return result;
  }

  bool get isEmpty => _items.isEmpty;

  int get totalCents => _items.fold(0, (sum, item) => sum + item.priceCents);

  /// Anzahl verkaufter Einheiten eines Artikels im aktuellen Warenkorb.
  int countOf(String articleId) =>
      _items.where((i) => i.type == CartItemType.article && i.articleId == articleId).length;

  /// Legt einen Artikel in den Warenkorb. Bei pfandpflichtigen Getränken
  /// wird automatisch eine Pfandposition zum aktuellen Pfandwert ergänzt.
  void addArticle(Article article) {
    final current = _catalog.articleById(article.id);
    final item = CartItem(
      id: _nextId++,
      type: CartItemType.article,
      label: current.name,
      priceCents: current.priceCents,
      articleId: current.id,
    );
    _items.add(item);

    if (current.hasDeposit && _catalog.depositCents > 0) {
      _items.add(CartItem(
        id: _nextId++,
        type: CartItemType.deposit,
        label: 'Pfand',
        priceCents: _catalog.depositCents,
        parentId: item.id,
      ));
    }
    notifyListeners();
  }

  /// Pfandrückgabe: Minusbetrag in Höhe des aktuellen Pfandwerts.
  void addDepositReturn() {
    _items.add(CartItem(
      id: _nextId++,
      type: CartItemType.depositReturn,
      label: 'Pfandrückgabe',
      priceCents: -_catalog.depositCents,
    ));
    notifyListeners();
  }

  /// Storniert eine einzelne Position. Wird ein Getränk storniert, wird das
  /// zugehörige Pfand mit entfernt.
  void removeItem(int itemId) {
    final before = _items.length;
    _items.removeWhere((i) => i.id == itemId || i.parentId == itemId);
    if (_items.length != before) notifyListeners();
  }

  /// Storniert die zuletzt hinzugefügte Einheit eines Artikels (inkl. Pfand).
  void removeLastOf(String articleId) {
    final index = _items.lastIndexWhere(
        (i) => i.type == CartItemType.article && i.articleId == articleId);
    if (index == -1) return;
    removeItem(_items[index].id);
  }

  /// Storniert die zuletzt hinzugefügte Pfandrückgabe.
  void removeLastDepositReturn() {
    final index = _items.lastIndexWhere((i) => i.type == CartItemType.depositReturn);
    if (index == -1) return;
    removeItem(_items[index].id);
  }

  /// Kaufabschluss bzw. Leeren des Warenkorbs.
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// Legt zuvor entfernte Positionen wieder in den Warenkorb („Rückgängig“).
  /// Nur in einen leeren Warenkorb, damit ein inzwischen begonnener neuer
  /// Kauf nicht mit dem alten vermischt wird. Liefert false, wenn das nicht
  /// möglich war.
  bool restore(List<CartItem> items) {
    if (items.isEmpty || _items.isNotEmpty) return false;
    _items.addAll(items);
    notifyListeners();
    return true;
  }
}
