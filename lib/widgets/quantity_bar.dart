import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/quantity_provider.dart';
import '../utils/haptics.dart';

/// Schnellwahl der Menge für den nächsten Tipp auf eine Kachel, z. B. für
/// eine Runde Bier. Gilt für einen Tipp, danach wieder 1.
class QuantityBar extends StatelessWidget {
  const QuantityBar({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<QuantityProvider, int>((q) => q.quantity);
    final theme = Theme.of(context);

    // Eigene Zeichenebene, damit ein Tipp nicht den ganzen Bildschirm neu zeichnet.
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            Text('Menge', style: theme.textTheme.labelLarge),
            const SizedBox(width: 8),
            for (final quantity in QuantityProvider.options)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _QuantityButton(quantity: quantity, selected: quantity == selected),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final int quantity;
  final bool selected;

  const _QuantityButton({required this.quantity, required this.selected});

  @override
  Widget build(BuildContext context) {
    void onPressed() {
      tapFeedback();
      context.read<QuantityProvider>().select(quantity);
    }

    const style = ButtonStyle(
      padding: WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: WidgetStatePropertyAll(Size(0, 40)),
      visualDensity: VisualDensity.compact,
    );
    final label = FittedBox(child: Text('×$quantity', style: const TextStyle(fontWeight: FontWeight.bold)));

    return selected
        ? FilledButton(key: ValueKey('quantity-$quantity'), style: style, onPressed: onPressed, child: label)
        : OutlinedButton(key: ValueKey('quantity-$quantity'), style: style, onPressed: onPressed, child: label);
  }
}
