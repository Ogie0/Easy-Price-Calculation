enum CartItemType { article, deposit, depositReturn }

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
