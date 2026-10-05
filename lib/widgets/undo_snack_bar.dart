import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/checkout_provider.dart';

/// Meldung mit „Rückgängig“, die einen gerade geleerten bzw. abgeschlossenen
/// Warenkorb samt Bargeldeingabe zurückholt – solange noch nicht neu
/// gebucht wurde.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required List<CartItem> items,
  String input = '',
}) {
  final cart = context.read<CartProvider>();
  final checkout = context.read<CheckoutProvider>();
  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      persist: false,
      action: SnackBarAction(
        label: 'Rückgängig',
        onPressed: () {
          if (cart.restore(items)) {
            checkout.restoreInput(input);
          } else {
            messenger.showSnackBar(const SnackBar(
              content: Text('Rückgängig nicht möglich – es wurde schon neu gebucht.'),
              duration: Duration(seconds: 3),
            ));
          }
        },
      ),
    ));
}
