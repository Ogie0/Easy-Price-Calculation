import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../utils/money.dart';

/// Warenkorb mit Positionsliste, Pfandrückgabe und Gesamtsumme.
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
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: const Text('Pfandrückgabe'),
                onPressed: cart.addDepositReturn,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Summe', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  Text(
                    formatCents(cart.totalCents),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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

/// Kompakte Leiste für Smartphones: Summe und Zugriff auf den Warenkorb.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({super.key});

  void _openCart(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: const SafeArea(child: CartPanel()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    final count = cart.items.where((i) => i.type == CartItemType.article).length;

    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () => _openCart(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_cart),
                ),
                const SizedBox(width: 16),
                Text('Warenkorb', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  formatCents(cart.totalCents),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.expand_less),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
