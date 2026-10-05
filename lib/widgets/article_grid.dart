import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../utils/money.dart';
import 'article_icons.dart';

/// Kachelraster der Artikel einer Kategorie. Tippen legt den Artikel in den
/// Warenkorb, langes Drücken storniert die letzte Einheit.
class ArticleGrid extends StatelessWidget {
  final List<Article> articles;

  /// Zeigt zusätzlich eine Kachel für die Pfandrückgabe.
  final bool showDepositReturn;

  const ArticleGrid({super.key, required this.articles, this.showDepositReturn = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: articles.length + (showDepositReturn ? 1 : 0),
      itemBuilder: (context, index) => index < articles.length
          ? ArticleTile(article: articles[index])
          : const DepositReturnTile(),
    );
  }
}

class ArticleTile extends StatelessWidget {
  final Article article;

  const ArticleTile({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.countOf(article.id));
    return _Tile(
      icon: iconFor(article),
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
      icon: Icons.recycling,
      title: 'Pfandrückgabe',
      subtitle: formatCents(-deposit),
      count: count,
      onTap: context.read<CartProvider>().addDepositReturn,
      onLongPress: context.read<CartProvider>().removeLastDepositReturn,
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _Tile({
    required this.icon,
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
        onTap: onTap,
        onLongPress: selected ? onLongPress : null,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        child: Icon(icon, size: 64, color: foreground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold, color: foreground),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
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
