import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';
import '../utils/haptics.dart';
import '../utils/money.dart';
import 'amount_row.dart';
import 'undo_snack_bar.dart';

/// Bargeldeingabe per Ziffernblock, große Rückgeldanzeige und Abschluss.
/// Die einzelnen Teile hören selbst auf Warenkorb und Eingabe, damit pro
/// Tastendruck nur neu gebaut wird, was sich ändert.
class CheckoutPanel extends StatelessWidget {
  /// Wird nach dem Abschließen aufgerufen (z. B. um den Screen zu schließen).
  final VoidCallback? onCompleted;

  /// Zeigt die Summe über „Gegeben“ (Smartphone).
  final bool showTotal;

  const CheckoutPanel({super.key, this.onCompleted, this.showTotal = false});

  @override
  Widget build(BuildContext context) {
    // Eigene Zeichenebene: Eingaben zeichnen nicht den ganzen Bildschirm neu.
    return RepaintBoundary(
      // Die Beträge sind ohnehin groß; eine stark vergrößerte Systemschrift
      // würde nur den Ziffernblock zusammendrücken.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTotal) ...[
                const _TotalRow(),
                const SizedBox(height: 8),
              ],
              const _GivenRow(),
              const SizedBox(height: 8),
              const _ChangeDisplay(),
              const SizedBox(height: 8),
              const _QuickAmounts(),
              const SizedBox(height: 8),
              const Expanded(child: Numpad()),
              const SizedBox(height: 8),
              _CompleteButton(onCompleted: onCompleted),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow();

  @override
  Widget build(BuildContext context) {
    final totalCents = context.select<CartProvider, int>((c) => c.totalCents);
    return AmountRow(
      label: 'Summe',
      amount: formatCents(totalCents),
      amountKey: const ValueKey('cart-total'),
    );
  }
}

class _GivenRow extends StatelessWidget {
  const _GivenRow();

  @override
  Widget build(BuildContext context) {
    final input = context.select<CheckoutProvider, String>((c) => c.input);
    return AmountRow(
      label: 'Gegeben',
      amount: input.isEmpty ? formatCents(0) : '$input €',
      amountKey: const ValueKey('given-display'),
      muted: input.isEmpty,
    );
  }
}

class _ChangeDisplay extends StatelessWidget {
  const _ChangeDisplay();

  @override
  Widget build(BuildContext context) {
    final status = PaymentStatus.of(
      totalCents: context.select<CartProvider, int>((c) => c.totalCents),
      givenCents: context.select<CheckoutProvider, int?>((c) => c.givenCents),
    );
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

/// „Abschließen“: wird nur neu gebaut, wenn sich ändert, ob abgeschlossen
/// werden kann.
class _CompleteButton extends StatelessWidget {
  final VoidCallback? onCompleted;

  const _CompleteButton({this.onCompleted});

  void _complete(BuildContext context) {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    final status = PaymentStatus.of(totalCents: cart.totalCents, givenCents: checkout.givenCents);
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

  /// Ob abgeschlossen werden kann, nach aktuellem Warenkorb und Eingabe.
  static bool _canComplete(CartProvider cart, CheckoutProvider checkout) =>
      !cart.isEmpty &&
      PaymentStatus.of(totalCents: cart.totalCents, givenCents: checkout.givenCents).canComplete;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final checkout = context.read<CheckoutProvider>();
    // Beide stellen dieselbe Frage: Neu gebaut wird nur, wenn sich die Antwort
    // ändert, egal ob durch eine Kachel oder eine Taste.
    final byCart = context.select<CartProvider, bool>((c) => _canComplete(c, checkout));
    final byInput = context.select<CheckoutProvider, bool>((k) => _canComplete(cart, k));
    final enabled = byCart && byInput;

    // Der Farbübergang beim Aktivieren zeichnet nur den Button selbst neu.
    return RepaintBoundary(
      child: FilledButton.icon(
        key: const ValueKey('complete'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: Theme.of(context).textTheme.titleLarge,
        ),
        icon: const Icon(Icons.check_circle),
        label: const Text('Abschließen'),
        onPressed: enabled ? () => _complete(context) : null,
      ),
    );
  }
}

/// Schnelltasten „Passend“, 5 €, 10 € … Nur „Passend“ hängt vom Warenkorb
/// ab, und auch nur davon, ob etwas zu zahlen ist.
class _QuickAmounts extends StatelessWidget {
  const _QuickAmounts();

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutProvider>();
    final hasTotal = context.select<CartProvider, bool>((c) => c.totalCents > 0);

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(child: Text(label)),
              ),
            ),
          ),
        );

    return RepaintBoundary(
      child: Row(
        children: [
          button(
            'Passend',
            hasTotal ? () => checkout.setAmount(context.read<CartProvider>().totalCents) : null,
          ),
          for (final euros in const [5, 10, 20, 50])
            button('$euros €', () => checkout.setAmount(euros * 100)),
        ],
      ),
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

      // Jede Taste zeichnet ihre Tipp-Animation für sich.
      return Expanded(
        child: RepaintBoundary(
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
