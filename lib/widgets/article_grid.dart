import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../utils/haptics.dart';
import '../utils/money.dart';
import 'article_emoji.dart';

/// Kachelraster der Artikel einer Kategorie. Tippen legt den Artikel in den
/// Warenkorb, langes Drücken storniert die letzte Einheit. Die Kacheln werden
/// so groß gewählt, dass möglichst alle ohne Scrollen sichtbar sind.
class ArticleGrid extends StatelessWidget {
  final List<Article> articles;

  /// Zeigt zusätzlich eine Kachel für die Pfandrückgabe.
  final bool showDepositReturn;

  const ArticleGrid({super.key, required this.articles, this.showDepositReturn = false});

  static const double _padding = 12;
  static const double _spacing = 12;

  @override
  Widget build(BuildContext context) {
    final count = articles.length + (showDepositReturn ? 1 : 0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = GridFit.of(count, constraints.biggest, padding: _padding, spacing: _spacing);
        return GridView.builder(
          padding: const EdgeInsets.all(_padding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: fit.columns,
            mainAxisSpacing: _spacing,
            crossAxisSpacing: _spacing,
            childAspectRatio: fit.aspectRatio,
          ),
          itemCount: count,
          itemBuilder: (context, index) => index < articles.length
              ? ArticleTile(article: articles[index])
              : const DepositReturnTile(),
        );
      },
    );
  }
}

/// Spaltenzahl und Seitenverhältnis (Breite / Höhe) der Kacheln.
class GridFit {
  final int columns;
  final double aspectRatio;

  const GridFit(this.columns, this.aspectRatio);

  /// Unterhalb dieser Kantenlänge wird gescrollt statt weiter verkleinert.
  static const double minTileExtent = 90;

  /// Wählt die Spaltenzahl, bei der die Kacheln am größten werden und
  /// trotzdem alle in [size] passen. Würden sie dabei zu klein, gibt es
  /// stattdessen etwa quadratische Kacheln und das Raster scrollt.
  factory GridFit.of(int count, Size size, {required double padding, required double spacing}) {
    final width = size.width - 2 * padding;
    // 1 px Reserve gegen Rundungsfehler, damit nichts minimal scrollt.
    final height = size.height - 2 * padding - 1;

    var best = const GridFit(2, 1);
    var bestExtent = 0.0;
    if (count > 0 && width > 0 && height.isFinite && height > 0) {
      for (var columns = 1; columns <= count; columns++) {
        final rows = (count / columns).ceil();
        final tileWidth = (width - (columns - 1) * spacing) / columns;
        final tileHeight = (height - (rows - 1) * spacing) / rows;
        final extent = math.min(tileWidth, tileHeight);
        if (extent > bestExtent) {
          bestExtent = extent;
          best = GridFit(columns, (tileWidth / tileHeight).clamp(0.6, 2.0));
        }
      }
    }
    if (bestExtent >= minTileExtent) return best;

    final columns = math.max(2, ((width + spacing) / (1.5 * minTileExtent + spacing)).floor());
    return GridFit(columns, 1);
  }
}

class ArticleTile extends StatelessWidget {
  final Article article;

  const ArticleTile({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.countOf(article.id));
    return _Tile(
      emoji: emojiFor(article),
      title: article.name,
      subtitle: article.hasDeposit
          ? '${formatCents(article.priceCents)} + Pfand'
          : formatCents(article.priceCents),
      count: count,
      onTap: () => context.read<CartProvider>().addArticle(article),
      onLongPress: () => context.read<CartProvider>().removeLastOf(article.id),
    );
  }
}

/// Kachel für die Pfandrückgabe: legt einen Minusposten in Höhe des
/// aktuellen Pfandwerts in den Warenkorb.
class DepositReturnTile extends StatelessWidget {
  const DepositReturnTile({super.key});

  @override
  Widget build(BuildContext context) {
    final deposit = context.select<CatalogProvider, int>((c) => c.depositCents);
    final count = context.select<CartProvider, int>(
        (c) => c.items.where((i) => i.type == CartItemType.depositReturn).length);
    return _Tile(
      emoji: kDepositEmoji,
      title: 'Pfandrückgabe',
      subtitle: formatCents(-deposit),
      count: count,
      onTap: context.read<CartProvider>().addDepositReturn,
      onLongPress: context.read<CartProvider>().removeLastDepositReturn,
    );
  }
}

class _Tile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _Tile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = count > 0;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          tapFeedback();
          onTap();
        },
        onLongPress: selected
            ? () {
                tapFeedback();
                onLongPress();
              }
            : null,
        child: Stack(
          children: [
            // Feste Anteile für Bild und Text; beides verkleinert sich bei
            // kleinen Kacheln oder großer Systemschrift, statt überzulaufen.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(emoji, style: const TextStyle(fontSize: 64)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      flex: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold, color: foreground),
                            ),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary,
                  child: Text(
                    '$count',
                    style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
