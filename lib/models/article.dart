enum ArticleCategory { food, drink }

class Article {
  final String id;
  final String name;
  final ArticleCategory category;
  final int priceCents;
  final bool hasDeposit;

  /// Optionale Sorten (z. B. Cola/Fanta/Sprite), alle zum selben Preis.
  final List<String> variants;

  const Article({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    this.hasDeposit = false,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  Article copyWith({int? priceCents}) {
    return Article(
      id: id,
      name: name,
      category: category,
      priceCents: priceCents ?? this.priceCents,
      hasDeposit: hasDeposit,
      variants: variants,
    );
  }
}
