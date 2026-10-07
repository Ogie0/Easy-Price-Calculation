import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/appearance_provider.dart';

/// Emoji als Rückfall, wenn kein Bild da ist oder Bilder ausgeschaltet sind.
const Map<String, String> _articleEmoji = {
  'bratwurst': '🌭',
  'currywurst': '🍛',
  'krakauer': '🥓',
  'steak': '🥩',
  'pommes': '🍟',
  'nuggets': '🍗',
  'wasser': '💧',
  'softdrink': '🥤',
  'longdrink': '🍹',
  'bier': '🍺',
  'sekt': '🥂',
  'shot': '🥃',
};

/// Gezeichnete Bilder der festen Artikel (tool/article_art).
const String _assetDir = 'assets/articles';

/// Bild einer Kachel: eigenes Foto, gezeichnetes Bild oder Emoji – in dieser
/// Reihenfolge, je nachdem was vorhanden ist.
@immutable
class ArticleArt {
  final String emoji;
  final String? asset;
  final String? file;

  const ArticleArt({required this.emoji, this.asset, this.file});

  factory ArticleArt.of(Article article) => ArticleArt(
        emoji: article.emoji ??
            _articleEmoji[article.id] ??
            (article.category == ArticleCategory.food ? '🍽️' : '🥤'),
        asset: !article.custom && _articleEmoji.containsKey(article.id)
            ? '$_assetDir/${article.id}.png'
            : null,
        file: article.imagePath,
      );

  @override
  bool operator ==(Object other) =>
      other is ArticleArt && other.emoji == emoji && other.asset == asset && other.file == file;

  @override
  int get hashCode => Object.hash(emoji, asset, file);
}

const ArticleArt kDepositArt =
    ArticleArt(emoji: '♻️', asset: '$_assetDir/pfandrueckgabe.png');

const ArticleArt kFreeAmountArt =
    ArticleArt(emoji: '💶', asset: '$_assetDir/freier_betrag.png');

/// Alle gezeichneten Bilder, z. B. zum Vorladen beim Start.
Iterable<String> get kArticleAssets => [
      for (final id in _articleEmoji.keys) '$_assetDir/$id.png',
      kDepositArt.asset!,
      kFreeAmountArt.asset!,
    ];

/// Zeigt ein [ArticleArt]. Ohne [size] füllt es den verfügbaren Platz
/// (Kachel), mit [size] ein festes Quadrat (Listen).
class ArticleArtView extends StatelessWidget {
  final ArticleArt art;
  final double? size;

  const ArticleArtView(this.art, {super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final images = context.select<AppearanceProvider, bool>((a) => a.showImages);
    final emoji = ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(art.emoji, style: TextStyle(fontSize: size ?? 64)),
      ),
    );
    Widget fallback() {
      final asset = art.asset;
      return asset == null
          ? emoji
          : Image.asset(
              asset,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              // Der Name steht ohnehin auf der Kachel.
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => emoji,
            );
    }

    Widget child;
    if (!images) {
      child = emoji;
    } else if (art.file case final file?) {
      child = Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size == null ? 14 : 6),
            child: Image.file(
              File(file),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) => fallback(),
            ),
          ),
        ),
      );
    } else {
      child = fallback();
    }
    return size == null ? child : SizedBox.square(dimension: size, child: child);
  }
}

/// Lädt die gezeichneten Bilder einmal vor, damit die Kacheln beim Start
/// nicht nacheinander aufpoppen.
class ArticleArtPrecache extends StatefulWidget {
  final Widget child;

  const ArticleArtPrecache({super.key, required this.child});

  @override
  State<ArticleArtPrecache> createState() => _ArticleArtPrecacheState();
}

class _ArticleArtPrecacheState extends State<ArticleArtPrecache> {
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_done) return;
    _done = true;
    for (final asset in kArticleAssets) {
      precacheImage(AssetImage(asset), context, onError: (_, _) {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
