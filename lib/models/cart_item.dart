enum CartItemType { article, deposit, depositReturn, freeAmount }

/// Eine einzelne Position im Warenkorb (immer Menge 1, damit jede Position
/// einzeln storniert werden kann). Der Preis wird beim Hinzufügen
/// festgeschrieben.
class CartItem {
  final int id;
  final CartItemType type;
  final String label;
  final int priceCents;

  /// Artikel-ID bei [CartItemType.article], sonst null.
  final String? articleId;

  /// Bei [CartItemType.deposit]: ID der Getränkeposition, zu der das Pfand gehört.
  final int? parentId;

  const CartItem({
    required this.id,
    required this.type,
    required this.label,
    required this.priceCents,
    this.articleId,
    this.parentId,
  });
}

/// Eine Zeile in der Warenkorb-Anzeige: gleiche Positionen zusammengefasst,
/// z. B. „6 × Bier“. Die einzelnen Einheiten bleiben einzeln stornierbar.
class CartLine {
  final CartItemType type;
  final String label;
  final int unitCents;

  /// Die zusammengefassten Einheiten, älteste zuerst.
  final List<CartItem> items;

  const CartLine({
    required this.type,
    required this.label,
    required this.unitCents,
    required this.items,
  });

  int get quantity => items.length;

  int get totalCents => unitCents * quantity;

  /// Pfandzeilen gehören zum Getränk darüber und werden mit ihm storniert.
  bool get isDeposit => type == CartItemType.deposit;
}
