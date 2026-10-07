import 'article.dart';

const int kDefaultDepositCents = 200;

const List<Article> kDefaultArticles = [
  // Speisen
  Article(id: 'bratwurst', name: 'Bratwurst', category: ArticleCategory.food, priceCents: 300),
  Article(id: 'currywurst', name: 'Currywurst', category: ArticleCategory.food, priceCents: 400),
  Article(id: 'krakauer', name: 'Krakauer', category: ArticleCategory.food, priceCents: 350),
  Article(id: 'steak', name: 'Steak', category: ArticleCategory.food, priceCents: 500),
  Article(id: 'pommes', name: 'Pommes', category: ArticleCategory.food, priceCents: 300),
  Article(id: 'nuggets', name: 'Nuggets', category: ArticleCategory.food, priceCents: 400),

  // Getränke
  Article(
    id: 'wasser',
    name: 'Wasser',
    category: ArticleCategory.drink,
    priceCents: 200,
    hasDeposit: true,
  ),
  Article(
    id: 'softdrink',
    name: 'Softdrink',
    category: ArticleCategory.drink,
    priceCents: 250,
    hasDeposit: true,
  ),
  Article(
    id: 'longdrink',
    name: 'Longdrink',
    category: ArticleCategory.drink,
    priceCents: 600,
    hasDeposit: true,
  ),
  Article(
    id: 'bier',
    name: 'Bier/Radler',
    category: ArticleCategory.drink,
    priceCents: 300,
    hasDeposit: true,
  ),
  Article(id: 'sekt', name: 'Sekt', category: ArticleCategory.drink, priceCents: 300),
  Article(id: 'shot', name: 'Shot', category: ArticleCategory.drink, priceCents: 200),
];
