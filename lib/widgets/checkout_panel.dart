import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../utils/money.dart';

/// Bargeldeingabe per Ziffernblock, große Rückgeldanzeige und Abschluss.
class CheckoutPanel extends StatelessWidget {
  /// Wird nach dem Abschließen aufgerufen (z. B. um den Screen zu schließen).
  final VoidCallback? onCompleted;

  const CheckoutPanel({super.key, this.onCompleted});

  void _complete(BuildContext context, PaymentStatus status) {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final messenger = ScaffoldMessenger.of(context);

    cart.clear();
    checkout.reset();

    final message = switch (status.state) {
      PaymentState.change when status.cents > 0 =>
        'Abgeschlossen – Rückgeld ${formatCents(status.cents)}',
      PaymentState.payout => 'Abgeschlossen – Auszahlung ${formatCents(status.cents)}',
      _ => 'Abgeschlossen',
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
    onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final status = PaymentStatus.of(totalCents: cart.totalCents, givenCents: checkout.givenCents);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Gegeben', style: theme.textTheme.titleLarge),
              const Spacer(),
              Text(
                checkout.input.isEmpty ? '–' : '${checkout.input} €',
                key: const ValueKey('given-display'),
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChangeDisplay(status: status),
          const SizedBox(height: 8),
          _QuickAmounts(totalCents: cart.totalCents),
          const SizedBox(height: 8),
          const Expanded(child: Numpad()),
          const SizedBox(height: 8),
          FilledButton.icon(
            key: const ValueKey('complete'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 56),
              textStyle: theme.textTheme.titleLarge,
            ),
            icon: const Icon(Icons.check_circle),
            label: const Text('Abschließen'),
            onPressed: !cart.isEmpty && status.canComplete ? () => _complete(context, status) : null,
          ),
        ],
      ),
    );
  }
}

class _ChangeDisplay extends StatelessWidget {
  final PaymentStatus status;

  const _ChangeDisplay({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (label, background, foreground) = switch (status.state) {
      PaymentState.awaitingCash => ('Rückgeld', scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      PaymentState.change => ('Rückgeld', Colors.green.shade700, Colors.white),
      PaymentState.missing => ('Es fehlen', scheme.errorContainer, scheme.onErrorContainer),
      PaymentState.payout => ('Auszahlung', Colors.orange.shade700, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: theme.textTheme.titleLarge?.copyWith(color: foreground)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: Text(
                status.state == PaymentState.awaitingCash ? '–' : formatCents(status.cents),
                key: const ValueKey('change-display'),
                style: theme.textTheme.headlineMedium
                    ?.copyWith(color: foreground, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmounts extends StatelessWidget {
  final int totalCents;

  const _QuickAmounts({required this.totalCents});

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutProvider>();

    Widget button(String label, VoidCallback? onPressed) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
              ),
              onPressed: onPressed,
              child: FittedBox(child: Text(label)),
            ),
          ),
        );

    return Row(
      children: [
        button('Passend', totalCents > 0 ? () => checkout.setAmount(totalCents) : null),
        for (final euros in const [5, 10, 20, 50])
          button('$euros €', () => checkout.setAmount(euros * 100)),
      ],
    );
  }
}

/// Ziffernblock für die Bargeldeingabe. Passt sich der verfügbaren Höhe an.
class Numpad extends StatelessWidget {
  const Numpad({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutProvider>();

    Widget key(String id, Widget child, VoidCallback onPressed, {bool tonal = false}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: tonal
              ? FilledButton.tonal(
                  key: ValueKey('numpad-$id'),
                  style: _style,
                  onPressed: onPressed,
                  child: child,
                )
              : OutlinedButton(
                  key: ValueKey('numpad-$id'),
                  style: _style,
                  onPressed: onPressed,
                  child: child,
                ),
        ),
      );
    }

    Widget digit(int d) => key('$d', _label('$d'), () => checkout.pressDigit(d));

    Widget row(List<Widget> keys) =>
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: keys));

    return Column(
      children: [
        row([digit(7), digit(8), digit(9), key('C', _label('C'), checkout.reset, tonal: true)]),
        row([digit(4), digit(5), digit(6), key('back', const Icon(Icons.backspace_outlined), checkout.backspace, tonal: true)]),
        row([digit(1), digit(2), digit(3), key(',', _label(','), checkout.pressDecimal, tonal: true)]),
        row([
          const Spacer(),
          digit(0),
          key('00', _label('00'), () => checkout
            ..pressDigit(0)
            ..pressDigit(0)),
          const Spacer(),
        ]),
      ],
    );
  }

  static final ButtonStyle _style = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
    minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );

  static Widget _label(String text) => FittedBox(
        child: Text(text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
      );
}
