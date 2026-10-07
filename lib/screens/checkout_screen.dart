import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/cart_panel.dart';
import '../widgets/checkout_panel.dart';

/// Kassierbildschirm für Smartphones: Warenkorb oben, Ziffernblock unten.
/// Der Kassierbereich hat Vorrang, damit die Tasten groß genug bleiben;
/// der Warenkorb bekommt den restlichen Platz und scrollt.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  /// Bevorzugte Höhe des Kassierbereichs (Tasten ca. 56 dp hoch).
  static const double _preferredCheckoutHeight = 550;

  /// Darunter würden die Tasten kleiner als 48 dp (auch bei großer Schrift).
  static const double _minCheckoutHeight = 540;

  /// Kleinster Kassierbereich auf sehr kleinen Displays.
  static const double _smallestCheckoutHeight = 470;

  static const double _minCartHeight = 100;

  @override
  Widget build(BuildContext context) {
    final checkout = CheckoutPanel(
      showTotal: true,
      onCompleted: () => Navigator.of(context).pop(),
    );
    const cart = CartPanel(showHeader: false, showTotal: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasse'),
        // Leerer Warenkorb: zurück zu den Kacheln für den nächsten Kunden.
        actions: [ClearCartButton(onCleared: () => Navigator.of(context).maybePop())],
      ),
      body: SafeArea(
        // Fester Rahmen (Relayout-Grenze) und eigene Zeichenebene: Sonst
        // würde jede kleine Animation darin, z. B. wenn „Abschließen“ aktiv
        // wird, den ganzen Bildschirm neu anordnen und neu zeichnen.
        child: SizedBox.expand(
          child: RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;

                if (height < _minCheckoutHeight + _minCartHeight) {
                  // Sehr kleine Displays: Der Kassierbereich füllt den Bildschirm,
                  // der Warenkorb liegt darüber und ist per Scrollen erreichbar.
                  return ListView(
                    reverse: true,
                    children: [
                      SizedBox(
                        height: height.clamp(_smallestCheckoutHeight, _minCheckoutHeight),
                        child: checkout,
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: _minCartHeight, child: cart),
                    ],
                  );
                }

                final checkoutHeight = math.min(_preferredCheckoutHeight, height - _minCartHeight);
                return Column(
                  children: [
                    const Expanded(child: cart),
                    const Divider(height: 1),
                    SizedBox(height: checkoutHeight, child: checkout),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
