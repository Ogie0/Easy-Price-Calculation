import 'dart:convert';
import 'dart:io';

import '../models/article.dart';

/// Sortiment als Text für einen QR-Code: Pfandwert und alle Artikel in ihrer
/// Reihenfolge (Name, Kategorie, Preis, Pfand, sichtbar, eigene Position,
/// Emoji). Fotos und Darstellung bleiben auf dem jeweiligen Gerät.
/// Kompakt als JSON, gzip-gepackt und Base64-kodiert.
class CatalogTransfer {
  static const _prefix = 'KNUELLE1:';

  /// Ungefähr so viel passt sicher in einen gut scanbaren QR-Code.
  static const int maxLength = 2300;

  final List<Article> articles;
  final int depositCents;

  const CatalogTransfer({required this.articles, required this.depositCents});

  String encode() {
    final data = {
      'd': depositCents,
      'a': [
        for (final a in articles)
          [
            a.id,
            a.name,
            a.category == ArticleCategory.food ? 0 : 1,
            a.priceCents,
            a.hasDeposit ? 1 : 0,
            a.visible ? 1 : 0,
            a.custom ? 1 : 0,
            a.emoji ?? '',
          ],
      ],
    };
    final packed = GZipCodec(level: 9).encode(utf8.encode(jsonEncode(data)));
    return '$_prefix${base64Url.encode(packed)}';
  }

  /// Liest einen gescannten Text. null, wenn es kein (gültiges) Sortiment ist.
  static CatalogTransfer? decode(String text) {
    if (!text.startsWith(_prefix)) return null;
    try {
      final json = utf8.decode(GZipCodec().decode(base64Url.decode(text.substring(_prefix.length))));
      final data = jsonDecode(json) as Map<String, Object?>;
      final deposit = data['d']! as int;
      final articles = [
        for (final raw in data['a']! as List)
          _article(raw as List),
      ];
      if (deposit < 0 || articles.any((a) => a.priceCents < 0 || a.name.trim().isEmpty)) {
        return null;
      }
      return CatalogTransfer(articles: articles, depositCents: deposit);
    } on Object {
      return null;
    }
  }

  static Article _article(List raw) {
    final emoji = raw[7] as String;
    return Article(
      id: raw[0] as String,
      name: raw[1] as String,
      category: raw[2] == 0 ? ArticleCategory.food : ArticleCategory.drink,
      priceCents: raw[3] as int,
      hasDeposit: raw[4] == 1,
      visible: raw[5] == 1,
      custom: raw[6] == 1,
      emoji: emoji.isEmpty ? null : emoji,
    );
  }
}
