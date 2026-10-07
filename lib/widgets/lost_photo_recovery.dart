import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_provider.dart';
import '../services/article_image_store.dart';

/// Holt beim Start ein Foto nach, das aufgenommen wurde, während Android die
/// App aus Speichermangel beendet hat (passiert auf älteren Handys).
class LostPhotoRecovery extends StatefulWidget {
  final Widget child;

  const LostPhotoRecovery({super.key, required this.child});

  @override
  State<LostPhotoRecovery> createState() => _LostPhotoRecoveryState();
}

class _LostPhotoRecoveryState extends State<LostPhotoRecovery> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recover());
  }

  Future<void> _recover() async {
    final store = context.read<ArticleImageStore>();
    final catalog = context.read<CatalogProvider>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ({String articleId, String path})? lost;
    try {
      lost = await store.recoverLost();
    } on Object catch (e) {
      debugPrint('Foto nicht wiederhergestellt: $e');
      return;
    }
    if (lost == null) return;
    final article = catalog.articleOrNull(lost.articleId);
    if (article == null) {
      await store.delete(lost.path);
      return;
    }
    final old = article.imagePath;
    catalog.setImage(article.id, lost.path);
    await store.delete(old);
    messenger?.showSnackBar(SnackBar(content: Text('Foto für „${article.name}“ übernommen')));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
