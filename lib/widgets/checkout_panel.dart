import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../utils/haptics.dart';
import '../utils/money.dart';
import 'amount_row.dart';
import 'undo_snack_bar.dart';

/// Bargeldeingabe per Ziffernblock, große Rückgeldanzeige und Abschluss.
class CheckoutPanel extends StatelessWidget {
  /// Wird nach dem Abschließen aufgerufen (z. B. um den Screen zu schließen).
  final VoidCallback? onCompleted;

  /// Zeigt die Summe über „Gegeben“ (Smartphone).
  final bool showTotal;

  const CheckoutPanel({super.key, this.onCompleted, this.showTotal = false});

  void _complete(BuildContext context, PaymentStatus status) {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final items = List.of(cart.items);
    final input = checkout.input;

    completeFeedback();
    cart.clear();
    checkout.reset();

    final message = switch (status.state) {
      PaymentState.change when status.cents > 0 =>
        'Abgeschlossen – Rückgeld ${formatCents(status.cents)}',
      PaymentState.payout => 'Abgeschlossen – Auszahlung ${formatCents(status.cents)}',
      _ => 'Abgeschlossen',
    };
    showUndoSnackBar(context, message: message, items: items, input: input);
    onCompleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final checkout = context.watch<CheckoutProvider>();
    final status = PaymentStatus.of(totalCents: cart.totalCents, givenCents: checkout.givenCents);
    final theme = Theme.of(context);

    // Die Beträge sind ohnehin groß; eine stark vergrößerte Systemschrift
    // würde nur den Ziffernblock zusammendrücken.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTotal) ...[
              AmountRow(
                label: 'Summe',
                amount: formatCents(cart.totalCents),
                amountKey: const ValueKey('cart-total'),
              ),
              const SizedBox(height: 8),
            ],
            AmountRow(
              label: 'Gegeben',
              amount: checkout.input.isEmpty ? formatCents(0) : '${checkout.input} €',
              amountKey: const ValueKey('given-display'),
              muted: checkout.input.isEmpty,
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
      ),
    );
  }
}

class _ChangeDisplay extends StatelessWidget {
  final PaymentStatus status;

  const _ChangeDisplay({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, background, foreground) = switch (status.state) {
      PaymentState.awaitingCash => ('Rückgeld', scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
      PaymentState.change => ('Rückgeld', scheme.primary, scheme.onPrimary),
      PaymentState.missing => ('Es fehlen', scheme.errorContainer, scheme.onErrorContainer),
      // Dunkles Orange: genug Kontrast für weiße Schrift (ca. 5:1).
      PaymentState.payout => ('Auszahlung', const Color(0xFFB45309), Colors.white),
    };

    return AmountRow(
      label: label,
      amount: formatCents(status.cents),
      amountKey: const ValueKey('change-display'),
      background: background,
      foreground: foreground,
      muted: status.state == PaymentState.awaitingCash,
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
              onPressed: onPressed == null
                  ? null
                  : () {
                      tapFeedback();
                      onPressed();
                    },
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

    Widget key(String id, Widget child, VoidCallback action, {bool tonal = false}) {
      void onPressed() {
        tapFeedback();
        action();
      }

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
