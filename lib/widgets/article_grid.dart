import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/cart_provider.dart';
import '../utils/money.dart';

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
        childAspectRatio: 1.3,
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
                leading: const Icon(Icons.local_drink),
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
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: count > 0 ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _add(context),
        onLongPress: count > 0 ? () => context.read<CartProvider>().removeLastOf(article.id) : null,
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      article.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(formatCents(article.priceCents)),
                    if (article.hasDeposit)
                      Text('+ Pfand', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 14,
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
