import '../models/article.dart';

/// Emoji als Bild für die Artikel. Sie kommen aus der Systemschrift des
/// Geräts, funktionieren also offline und ohne zusätzliche Bilddateien.
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
  'sekt': '🥂',
  'shot': '🥃',
};

const String kDepositEmoji = '♻️';

String emojiFor(Article article) =>
    _articleEmoji[article.id] ?? (article.category == ArticleCategory.food ? '🍽️' : '🥤');
