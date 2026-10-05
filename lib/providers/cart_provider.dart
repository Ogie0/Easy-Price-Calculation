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

  /// Zeilen für die Anzeige: gleiche Positionen zusammengefasst („6 × Bier“),
  /// zuletzt gebuchte zuerst, Pfand jeweils direkt unter dem zugehörigen
  /// Getränk. Unterschiedliche Preise (z. B. nach einer Preisänderung) bleiben
  /// getrennte Zeilen.
  List<CartLine> get lines {
    final groups = <String, List<CartItem>>{};
    for (final item in _items) {
      if (item.type == CartItemType.deposit) continue;
      final key = '${item.type.name}|${item.articleId ?? item.label}|${item.priceCents}';
      (groups[key] ??= []).add(item);
    }
    final ordered = groups.values.toList()
      ..sort((a, b) => b.last.id.compareTo(a.last.id));

    final result = <CartLine>[];
    for (final group in ordered) {
      final first = group.first;
      result.add(CartLine(
        type: first.type,
        label: first.label,
        unitCents: first.priceCents,
        items: group,
      ));
      final ids = {for (final item in group) item.id};
      final deposits = <int, List<CartItem>>{};
      for (final d in _items.where((i) => i.type == CartItemType.deposit && ids.contains(i.parentId))) {
        (deposits[d.priceCents] ??= []).add(d);
      }
      for (final entry in deposits.entries) {
        result.add(CartLine(
          type: CartItemType.deposit,
          label: 'Pfand',
          unitCents: entry.key,
          items: entry.value,
        ));
      }
    }
    return result;
  }

  bool get isEmpty => _items.isEmpty;

  int get totalCents => _items.fold(0, (sum, item) => sum + item.priceCents);

  /// Anzahl verkaufter Einheiten eines Artikels im aktuellen Warenkorb.
  int countOf(String articleId) =>
      _items.where((i) => i.type == CartItemType.article && i.articleId == articleId).length;

  /// Legt einen Artikel [quantity]-mal in den Warenkorb. Bei Artikeln mit
  /// Pfand wird je Einheit automatisch eine Pfandposition zum aktuellen
  /// Pfandwert ergänzt.
  void addArticle(Article article, {int quantity = 1}) {
    final current = _catalog.articleById(article.id);
    for (var n = 0; n < quantity; n++) {
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
    }
    if (quantity > 0) notifyListeners();
  }

  /// Pfandrückgabe: je Einheit ein Minusbetrag in Höhe des aktuellen Pfandwerts.
  void addDepositReturn({int quantity = 1}) {
    for (var n = 0; n < quantity; n++) {
      _items.add(CartItem(
        id: _nextId++,
        type: CartItemType.depositReturn,
        label: 'Pfandrückgabe',
        priceCents: -_catalog.depositCents,
      ));
    }
    if (quantity > 0) notifyListeners();
  }

  /// Frei eingegebener Betrag (z. B. Spende, Los, Sonderpreis); ein Abzug
  /// wird als negativer Betrag übergeben.
  void addFreeAmount(String label, int cents, {int quantity = 1}) {
    for (var n = 0; n < quantity; n++) {
      _items.add(CartItem(
        id: _nextId++,
        type: CartItemType.freeAmount,
        label: label,
        priceCents: cents,
      ));
    }
    if (quantity > 0) notifyListeners();
  }

  /// Anzahl frei eingegebener Beträge im Warenkorb.
  int get freeAmountCount =>
      _items.where((i) => i.type == CartItemType.freeAmount).length;

  /// Verkaufte Einheiten: Artikel und freie Beträge, ohne Pfand und Abzüge.
  int get soldCount => _items
      .where((i) =>
          i.type == CartItemType.article ||
          (i.type == CartItemType.freeAmount && i.priceCents > 0))
      .length;

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

  /// Storniert die zuletzt gebuchte Einheit einer Zeile (inkl. Pfand).
  void removeOneOf(CartLine line) {
    if (line.isDeposit || line.items.isEmpty) return;
    removeItem(line.items.last.id);
  }

  /// Storniert die zuletzt hinzugefügte Pfandrückgabe.
  void removeLastDepositReturn() => _removeLastOfType(CartItemType.depositReturn);

  /// Storniert den zuletzt hinzugefügten freien Betrag.
  void removeLastFreeAmount() => _removeLastOfType(CartItemType.freeAmount);

  void _removeLastOfType(CartItemType type) {
    final index = _items.lastIndexWhere((i) => i.type == type);
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
