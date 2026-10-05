import 'package:flutter/material.dart';

import '../models/article.dart';

const Map<String, IconData> _articleIcons = {
  'bratwurst': Icons.outdoor_grill,
  'currywurst': Icons.kebab_dining,
  'krakauer': Icons.lunch_dining,
  'steak': Icons.set_meal,
  'pommes': Icons.fastfood,
  'nuggets': Icons.bakery_dining,
  'wasser': Icons.water_drop,
  'softdrink': Icons.local_drink,
  'longdrink': Icons.local_bar,
  'sekt': Icons.wine_bar,
  'shot': Icons.liquor,
};

IconData iconFor(Article article) =>
    _articleIcons[article.id] ??
    (article.category == ArticleCategory.food ? Icons.restaurant : Icons.local_cafe);
