import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/cart_provider.dart';
import '../utils/money.dart';
import 'article_icons.dart';

/// Kachelraster der Artikel einer Kategorie. Tippen legt den Artikel in den
/// Warenkorb, langes Drücken storniert die letzte Einheit.
class ArticleGrid extends StatelessWidget {
  final List<Article> articles;

  const ArticleGrid({super.key, required this.articles});

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
      itemCount: articles.length,
      itemBuilder: (context, index) => ArticleTile(article: articles[index]),
    );
  }
}

class ArticleTile extends StatelessWidget {
  final Article article;

  const ArticleTile({super.key, required this.article});

  Future<void> _add(BuildContext context) async {
    final cart = context.read<CartProvider>();
    if (!article.hasVariants) {
      cart.addArticle(article);
      return;
    }
    final variant = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${article.name} – Sorte wählen',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final v in article.variants)
              ListTile(
                leading: Icon(iconFor(article)),
                title: Text(v),
                onTap: () => Navigator.pop(context, v),
              ),
          ],
        ),
      ),
    );
    if (variant != null) cart.addArticle(article, variant: variant);
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((c) => c.countOf(article.id));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = count > 0;
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _add(context),
        onLongPress: selected ? () => context.read<CartProvider>().removeLastOf(article.id) : null,
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
                        child: Icon(iconFor(article), size: 64, color: foreground),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold, color: foreground),
                    ),
                    Text(
                      article.hasDeposit
                          ? '${formatCents(article.priceCents)} + Pfand'
                          : formatCents(article.priceCents),
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
