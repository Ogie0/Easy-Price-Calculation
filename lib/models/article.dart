enum ArticleCategory { food, drink }

class Article {
  final String id;
  final String name;
  final ArticleCategory category;
  final int priceCents;
  final bool hasDeposit;

  /// Ausgeblendete Artikel erscheinen nicht als Kachel, bleiben aber in den
  /// Einstellungen erhalten.
  final bool visible;

  /// Selbst angelegte Position (kann wieder gelöscht werden).
  final bool custom;

  /// Optionales Emoji für selbst angelegte Positionen.
  final String? emoji;

  /// Eigenes Foto (Pfad im App-Ordner), ersetzt Bild bzw. Emoji.
  final String? imagePath;

  const Article({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    this.hasDeposit = false,
    this.visible = true,
    this.custom = false,
    this.emoji,
    this.imagePath,
  });

  /// Kopie mit geänderten Werten. [clearEmoji] bzw. [clearImage] entfernen
  /// ein eigenes Emoji bzw. Foto.
  Article copyWith({
    String? name,
    ArticleCategory? category,
    int? priceCents,
    bool? hasDeposit,
    bool? visible,
    String? emoji,
    bool clearEmoji = false,
    String? imagePath,
    bool clearImage = false,
  }) {
    return Article(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      priceCents: priceCents ?? this.priceCents,
      hasDeposit: hasDeposit ?? this.hasDeposit,
      visible: visible ?? this.visible,
      custom: custom,
      emoji: clearEmoji ? null : (emoji ?? this.emoji),
      imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'priceCents': priceCents,
        'hasDeposit': hasDeposit,
        'visible': visible,
        'custom': custom,
        if (emoji != null) 'emoji': emoji,
        if (imagePath != null) 'imagePath': imagePath,
      };

  factory Article.fromJson(Map<String, Object?> json) => Article(
        id: json['id']! as String,
        name: json['name']! as String,
        category: ArticleCategory.values.byName(json['category']! as String),
        priceCents: json['priceCents']! as int,
        hasDeposit: json['hasDeposit'] as bool? ?? false,
        visible: json['visible'] as bool? ?? true,
        custom: json['custom'] as bool? ?? false,
        emoji: json['emoji'] as String?,
        imagePath: json['imagePath'] as String?,
      );
}
