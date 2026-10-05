import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../screens/checkout_screen.dart';
import '../utils/money.dart';

/// Warenkorb mit Positionsliste und Gesamtsumme.
class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(child: Text('Warenkorb', style: theme.textTheme.titleLarge)),
              IconButton(
                tooltip: 'Warenkorb leeren',
                icon: const Icon(Icons.delete_sweep),
                onPressed: cart.isEmpty ? null : cart.clear,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Noch keine Artikel'))
              : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[cart.items.length - 1 - index];
                    return _CartItemTile(item: item);
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Summe', style: theme.textTheme.titleLarge),
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
            ],
          ),
        ),
      ],
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
              onPressed: () => context.read<CartProvider>().removeItem(item.id),
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
