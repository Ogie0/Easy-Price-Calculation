import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../screens/checkout_screen.dart';
import '../utils/haptics.dart';
import '../utils/money.dart';
import 'amount_row.dart';

/// Warenkorb mit Positionsliste und Gesamtsumme.
class CartPanel extends StatelessWidget {
  /// Zeigt die Überschrift „Warenkorb“ mit dem Leeren-Button. Auf dem
  /// Kasse-Screen des Smartphones sitzt der Button stattdessen in der AppBar.
  final bool showHeader;

  /// Zeigt die Summe unter der Liste. Auf dem Smartphone steht sie
  /// stattdessen im Kassierbereich direkt über „Gegeben“.
  final bool showTotal;

  const CartPanel({super.key, this.showHeader = true, this.showTotal = true});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Warenkorb', style: theme.textTheme.titleLarge)),
                const ClearCartButton(),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Noch keine Artikel'))
              : ListView(
                  children: [
                    for (final item in cart.itemsNewestFirst) _CartItemTile(item: item),
                  ],
                ),
        ),
        if (showTotal) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: AmountRow(
              label: 'Summe',
              amount: formatCents(cart.totalCents),
              amountKey: const ValueKey('cart-total'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Leert den Warenkorb, z. B. wenn ein Kunde doch nichts kauft.
class ClearCartButton extends StatelessWidget {
  const ClearCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isEmpty = context.select<CartProvider, bool>((c) => c.isEmpty);
    return IconButton(
      tooltip: 'Warenkorb leeren',
      icon: const Icon(Icons.delete_sweep),
      onPressed: isEmpty ? null : context.read<CartProvider>().clear,
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDeposit = item.type == CartItemType.deposit;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.only(left: isDeposit ? 32 : 16, right: 4),
      title: Text(item.label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatCents(item.priceCents)),
          // Pfand wird zusammen mit dem zugehörigen Getränk storniert.
          if (isDeposit)
            const SizedBox(width: 48)
          else
            IconButton(
              tooltip: 'Stornieren',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                tapFeedback();
                context.read<CartProvider>().removeItem(item.id);
              },
            ),
        ],
      ),
    );
  }
}

/// Leiste für Smartphones: Live-Summe und Weg zur Kasse.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final count = cart.items.where((i) => i.type == CartItemType.article).length;

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  const SizedBox(width: 16),
                  Text('Summe', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatCents(cart.totalCents),
                        key: const ValueKey('cart-total'),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text('Kasse'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
