import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/catalog_provider.dart';
import '../widgets/article_art.dart';

/// Reihenfolge der Kacheln einer Kategorie per Ziehen festlegen. Die
/// Reihenfolge wird sofort gespeichert und gilt auch für ausgeblendete
/// Artikel.
class ReorderScreen extends StatelessWidget {
  final ArticleCategory category;

  const ReorderScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final articles = catalog.allOf(category);
    final title = category == ArticleCategory.food ? 'Speisen' : 'Getränke';

    return Scaffold(
      appBar: AppBar(title: Text('Reihenfolge: $title')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Am Griff '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(Icons.drag_handle, size: 20),
                      ),
                      TextSpan(
                        text: ' ziehen (oder lange drücken), um einen Artikel zu verschieben. '
                            'Die Kacheln erscheinen in dieser Reihenfolge.',
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  itemCount: articles.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      catalog.moveArticle(category, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(article.id),
                      index: index,
                      child: Material(
                        child: ListTile(
                          leading: ArticleArtView(ArticleArt.of(article), size: 36),
                          title: Text(article.name),
                          subtitle: article.visible ? null : const Text('ausgeblendet'),
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
