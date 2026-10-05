import 'package:flutter/foundation.dart';

/// Menge für den nächsten Tipp auf eine Kachel („Runde“). Gilt nur für
/// diesen einen Tipp und springt danach automatisch auf 1 zurück.
class QuantityProvider extends ChangeNotifier {
  static const List<int> options = [2, 3, 4, 5, 6, 10];

  int _quantity = 1;

  int get quantity => _quantity;

  /// Wählt eine Menge; nochmaliges Wählen derselben Menge hebt sie auf.
  void select(int quantity) {
    _quantity = _quantity == quantity ? 1 : quantity;
    notifyListeners();
  }

  /// Liefert die gewählte Menge und setzt sie auf 1 zurück.
  int take() {
    final quantity = _quantity;
    if (quantity != 1) {
      _quantity = 1;
      notifyListeners();
    }
    return quantity;
  }
}
