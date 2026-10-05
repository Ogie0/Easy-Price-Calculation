import 'package:flutter/foundation.dart';

import '../utils/money.dart';
import 'cart_provider.dart';

enum PaymentState { awaitingCash, change, missing, payout }

/// Ergebnis der Rückgeldberechnung für die Anzeige.
class PaymentStatus {
  final PaymentState state;
  final int cents;

  const PaymentStatus(this.state, this.cents);

  bool get canComplete => state != PaymentState.missing;

  factory PaymentStatus.of({required int totalCents, required int? givenCents}) {
    if (givenCents == null) {
      return totalCents < 0
          ? PaymentStatus(PaymentState.payout, -totalCents)
          : const PaymentStatus(PaymentState.awaitingCash, 0);
    }
    final diff = givenCents - totalCents;
    return diff >= 0
        ? PaymentStatus(PaymentState.change, diff)
        : PaymentStatus(PaymentState.missing, -diff);
  }
}

/// Eingabe des gegebenen Bargelds über den Ziffernblock. Mit [cart] wird
/// die Eingabe automatisch gelöscht, sobald der Warenkorb leer ist
/// (Abschließen, Leeren oder letzte Position storniert).
class CheckoutProvider extends ChangeNotifier {
  static final _validInput = RegExp(r'^\d{1,4}(,\d{0,2})?$');

  final CartProvider? _cart;
  String _input = '';

  CheckoutProvider({CartProvider? cart}) : _cart = cart {
    _cart?.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (_cart!.isEmpty) reset();
  }

  @override
  void dispose() {
    _cart?.removeListener(_onCartChanged);
    super.dispose();
  }

  /// Rohe Eingabe, z. B. "20" oder "12,5".
  String get input => _input;

  /// Gegebenes Geld in Cent oder null, wenn nichts eingegeben wurde.
  int? get givenCents => _input.isEmpty ? null : parseCents(_input);

  void pressDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    var next = '$_input$digit';
    if (next.length > 1 && next.startsWith('0') && !next.startsWith('0,')) {
      next = next.substring(1);
    }
    _apply(next);
  }

  void pressDecimal() {
    if (_input.contains(',')) return;
    _apply(_input.isEmpty ? '0,' : '$_input,');
  }

  void backspace() {
    if (_input.isEmpty) return;
    _input = _input.substring(0, _input.length - 1);
    notifyListeners();
  }

  /// Setzt einen festen Betrag (z. B. Schnellwahl 20 € oder "Passend").
  void setAmount(int cents) {
    if (cents < 0) return;
    final euros = cents ~/ 100;
    final rest = cents % 100;
    _input = rest == 0 ? '$euros' : '$euros,${rest.toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void reset() {
    if (_input.isEmpty) return;
    _input = '';
    notifyListeners();
  }

  void _apply(String next) {
    if (!_validInput.hasMatch(next)) return;
    _input = next;
    notifyListeners();
  }
}
