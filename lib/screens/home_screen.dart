import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_provider.dart';
import '../utils/layout.dart';
import '../widgets/article_grid.dart';
import '../widgets/cart_panel.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final tablet = isTablet(context);

    final tabView = TabBarView(
      children: [
        ArticleGrid(articles: catalog.food),
        ArticleGrid(articles: catalog.drinks),
      ],
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vereinskasse'),
          actions: [
            IconButton(
              tooltip: 'Einstellungen',
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.restaurant), text: 'Speisen'),
              Tab(icon: Icon(Icons.local_bar), text: 'Getränke'),
            ],
          ),
        ),
        body: tablet
            ? Row(
                children: [
                  Expanded(child: tabView),
                  const VerticalDivider(width: 1),
                  const SizedBox(width: 380, child: SafeArea(left: false, child: CartPanel())),
                ],
              )
            : tabView,
        bottomNavigationBar: tablet ? null : const CartSummaryBar(),
      ),
    );
  }
}
