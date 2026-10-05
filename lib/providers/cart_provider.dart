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

  // Abgeleitete Werte (Summe, Zähler, Zeilen) werden nur einmal pro Änderung
  // berechnet: Bei jedem Tipp fragen viele Kacheln und Anzeigen sie ab.
  _Totals? _totals;
  List<CartLine>? _lines;

  CartProvider(this._catalog);

  List<CartItem> get items => UnmodifiableListView(_items);

  /// Zeilen für die Anzeige: gleiche Positionen zusammengefasst („6 × Bier“),
  /// zuletzt gebuchte zuerst, Pfand jeweils direkt unter dem zugehörigen
  /// Getränk. Unterschiedliche Preise (z. B. nach einer Preisänderung) bleiben
  /// getrennte Zeilen.
  List<CartLine> get lines => _lines ??= _buildLines();

  List<CartLine> _buildLines() {
    final groups = <String, List<CartItem>>{};
    final groupOf = <int, String>{};
    // Pfand je Gruppe, getrennt nach Pfandwert.
    final deposits = <String, Map<int, List<CartItem>>>{};
    for (final item in _items) {
      if (item.type == CartItemType.deposit) {
        final group = groupOf[item.parentId];
        if (group != null) ((deposits[group] ??= {})[item.priceCents] ??= []).add(item);
        continue;
      }
      final key = '${item.type.name}|${item.articleId ?? item.label}|${item.priceCents}';
      (groups[key] ??= []).add(item);
      groupOf[item.id] = key;
    }
    final ordered = groups.entries.toList()
      ..sort((a, b) => b.value.last.id.compareTo(a.value.last.id));

    return List.unmodifiable([
      for (final MapEntry(:key, value: group) in ordered) ...[
        CartLine(
          type: group.first.type,
          label: group.first.label,
          unitCents: group.first.priceCents,
          items: List.unmodifiable(group),
        ),
        for (final MapEntry(key: price, value: items) in (deposits[key] ?? const {}).entries)
          CartLine(
            type: CartItemType.deposit,
            label: 'Pfand',
            unitCents: price,
            items: List.unmodifiable(items),
          ),
      ],
    ]);
  }

  _Totals get _computed => _totals ??= _Totals.of(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalCents => _computed.cents;

  /// Anzahl verkaufter Einheiten eines Artikels im aktuellen Warenkorb.
  int countOf(String articleId) => _computed.perArticle[articleId] ?? 0;

  /// Anzahl der Pfandrückgaben im Warenkorb.
  int get depositReturnCount => _computed.depositReturns;

  /// Anzahl frei eingegebener Beträge im Warenkorb.
  int get freeAmountCount => _computed.freeAmounts;

  /// Verkaufte Einheiten: Artikel und freie Beträge, ohne Pfand und Abzüge.
  int get soldCount => _computed.sold;

  /// Nach jeder Änderung: Zwischenergebnisse verwerfen und benachrichtigen.
  void _changed() {
    _totals = null;
    _lines = null;
    notifyListeners();
  }

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
    if (quantity > 0) _changed();
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
    if (quantity > 0) _changed();
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
    if (quantity > 0) _changed();
  }

  /// Storniert eine einzelne Position. Wird ein Getränk storniert, wird das
  /// zugehörige Pfand mit entfernt.
  void removeItem(int itemId) {
    final before = _items.length;
    _items.removeWhere((i) => i.id == itemId || i.parentId == itemId);
    if (_items.length != before) _changed();
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
    _changed();
  }

  /// Legt zuvor entfernte Positionen wieder in den Warenkorb („Rückgängig“).
  /// Nur in einen leeren Warenkorb, damit ein inzwischen begonnener neuer
  /// Kauf nicht mit dem alten vermischt wird. Liefert false, wenn das nicht
  /// möglich war.
  bool restore(List<CartItem> items) {
    if (items.isEmpty || _items.isNotEmpty) return false;
    _items.addAll(items);
    _changed();
    return true;
  }
}

/// Summe und Zähler des Warenkorbs, in einem Durchlauf berechnet.
class _Totals {
  final int cents;
  final int sold;
  final int freeAmounts;
  final int depositReturns;
  final Map<String, int> perArticle;

  const _Totals(this.cents, this.sold, this.freeAmounts, this.depositReturns, this.perArticle);

  factory _Totals.of(List<CartItem> items) {
    var cents = 0, sold = 0, freeAmounts = 0, depositReturns = 0;
    final perArticle = <String, int>{};
    for (final item in items) {
      cents += item.priceCents;
      switch (item.type) {
        case CartItemType.article:
          sold++;
          perArticle.update(item.articleId!, (n) => n + 1, ifAbsent: () => 1);
        case CartItemType.freeAmount:
          freeAmounts++;
          if (item.priceCents > 0) sold++;
        case CartItemType.depositReturn:
          depositReturns++;
        case CartItemType.deposit:
          break;
      }
    }
    return _Totals(cents, sold, freeAmounts, depositReturns, perArticle);
  }
}
