import 'package:flutter/material.dart';

import '../widgets/cart_panel.dart';
import '../widgets/checkout_panel.dart';

/// Kassierbildschirm für Smartphones: Warenkorb oben, Ziffernblock unten.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kasse')),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(flex: 4, child: CartPanel()),
            const Divider(height: 1),
            Expanded(
              flex: 6,
              child: CheckoutPanel(onCompleted: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}
