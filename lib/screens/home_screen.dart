import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/catalog_provider.dart';
import '../theme.dart';
import '../utils/layout.dart';
import '../widgets/article_grid.dart';
import '../widgets/cart_panel.dart';
import '../widgets/checkout_panel.dart';
import '../widgets/password_dialog.dart';
import '../widgets/quantity_bar.dart';
import 'faq_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tabBar = TabBar(
    tabs: [
      Tab(icon: Icon(Icons.restaurant), text: 'Speisen'),
      Tab(icon: Icon(Icons.local_bar), text: 'Getränke'),
    ],
  );

  /// Fragt nach, bevor die App mit gefülltem Warenkorb geschlossen wird.
  Future<void> _confirmClose(BuildContext context) async {
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App schließen?'),
        content: const Text('Im Warenkorb liegen noch Artikel. Sie gehen beim Schließen verloren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
    if (close ?? false) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final cartIsEmpty = context.select<CartProvider, bool>((c) => c.isEmpty);
    final tablet = isTablet(context);

    final tabView = TabBarView(
      children: [
        ArticleGrid(articles: catalog.food, showFreeAmount: true),
        ArticleGrid(
          articles: catalog.drinks,
          showDepositReturn: catalog.depositCents > 0,
          showFreeAmount: true,
        ),
      ],
    );

    return PopScope(
      canPop: cartIsEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmClose(context));
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(kClubLogo, height: 40),
                const SizedBox(width: 12),
                // Langer Name: lieber etwas kleiner als abgeschnitten.
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(kAppName),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Hilfe & FAQ',
                icon: const Icon(Icons.help_outline),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const FaqScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Einstellungen',
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  if (!await askMasterPassword(context)) return;
                  await navigator.push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
            // Auf dem Tablet sitzt die Tab-Leiste nur über den Kacheln.
            bottom: tablet ? null : _tabBar,
          ),
          body: tablet
              ? Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          const Material(color: kClubGreen, child: _tabBar),
                          const QuantityBar(),
                          Expanded(child: tabView),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    const Expanded(flex: 3, child: CartPanel()),
                    const VerticalDivider(width: 1),
                    const Expanded(flex: 3, child: SafeArea(left: false, child: CheckoutPanel())),
                  ],
                )
              : Column(
                  children: [
                    const QuantityBar(),
                    Expanded(child: tabView),
                  ],
                ),
          bottomNavigationBar: tablet ? null : const CartSummaryBar(),
        ),
      ),
    );
  }
}
