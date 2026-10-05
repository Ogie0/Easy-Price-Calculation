enum ArticleCategory { food, drink }

class Article {
  final String id;
  final String name;
  final ArticleCategory category;
  final int priceCents;
  final bool hasDeposit;

  const Article({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    this.hasDeposit = false,
  });

  Article copyWith({int? priceCents}) {
    return Article(
      id: id,
      name: name,
      category: category,
      priceCents: priceCents ?? this.priceCents,
      hasDeposit: hasDeposit,
    );
  }
}
