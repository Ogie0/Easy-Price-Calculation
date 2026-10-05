import 'package:flutter/foundation.dart';

import '../models/article.dart';
import '../models/cart_item.dart';
import 'catalog_provider.dart';

/// Warenkorb inkl. Pfand-Logik und Rückgeldberechnung.
class CartProvider extends ChangeNotifier {
  CatalogProvider _catalog;
  final List<CartItem> _items = [];
  int _nextId = 1;

  CartProvider(this._catalog);

  /// Für ChangeNotifierProxyProvider: aktualisiert die Katalog-Referenz.
  void updateCatalog(CatalogProvider catalog) {
    _catalog = catalog;
  }

  List<CartItem> get items => List.unmodifiable(_items);

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

    if (current.hasDeposit) {
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

  /// Rückgeld = gegebenes Geld - Gesamtsumme. Negativ, wenn zu wenig gegeben.
  int changeFor(int givenCents) => givenCents - totalCents;

  /// Kaufabschluss bzw. Leeren des Warenkorbs.
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  /// Schließt den Kauf ab, gibt das Rückgeld zurück und leert den Warenkorb.
  int checkout(int givenCents) {
    final change = changeFor(givenCents);
    if (change < 0) {
      throw StateError('Gegebenes Geld reicht nicht aus');
    }
    clear();
    return change;
  }
}
