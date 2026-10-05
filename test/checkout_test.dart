import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/providers/checkout_provider.dart';
import 'package:easy_price_calculation/screens/checkout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> press(WidgetTester tester, String keys) async {
  for (final k in keys.split(' ')) {
    await tester.tap(find.byKey(ValueKey('numpad-$k')));
  }
  await tester.pump();
}

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key)).first).data!;

void main() {
  group('CheckoutProvider', () {
    test('Ziffern, Komma und Löschen', () {
      final c = CheckoutProvider();
      expect(c.givenCents, isNull);
      c
        ..pressDigit(0)
        ..pressDigit(2)
        ..pressDigit(0)
        ..pressDecimal()
        ..pressDigit(5);
      expect(c.input, '20,5');
      expect(c.givenCents, 2050);
      c
        ..pressDigit(1)
        ..pressDigit(9);
      expect(c.input, '20,51');
      c.backspace();
      expect(c.givenCents, 2050);
      c.reset();
      expect(c.givenCents, isNull);
    });

    test('Komma am Anfang und Schnellbeträge', () {
      final c = CheckoutProvider()
        ..pressDecimal()
        ..pressDigit(5);
      expect(c.givenCents, 50);
      c.setAmount(1250);
      expect(c.input, '12,50');
      c.setAmount(2000);
      expect(c.input, '20');
    });

    test('PaymentStatus', () {
      expect(PaymentStatus.of(totalCents: 450, givenCents: null).state, PaymentState.awaitingCash);
      final change = PaymentStatus.of(totalCents: 450, givenCents: 1000);
      expect((change.state, change.cents), (PaymentState.change, 550));
      final missing = PaymentStatus.of(totalCents: 450, givenCents: 200);
      expect((missing.state, missing.cents, missing.canComplete), (PaymentState.missing, 250, false));
      final payout = PaymentStatus.of(totalCents: -400, givenCents: null);
      expect((payout.state, payout.cents), (PaymentState.payout, 400));
    });
  });

  testWidgets('Tablet: kassieren mit Ziffernblock', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Steak'));
    await tester.tap(find.text('Pommes'));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '8,00 €');

    await press(tester, '5');
    expect(textOf(tester, 'change-display'), '3,00 €');
    expect(find.text('Es fehlen'), findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('complete'))).enabled, isFalse);

    await press(tester, 'C 1 0 , 5');
    expect(textOf(tester, 'given-display'), '10,5 €');
    expect(textOf(tester, 'change-display'), '2,50 €');

    // Einzelstorno aktualisiert Rückgeld live.
    await tester.tap(find.byTooltip('Stornieren').first);
    await tester.pump();
    expect(textOf(tester, 'change-display'), '5,50 €');

    await tester.tap(find.byKey(const ValueKey('complete')));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '0,00 €');
    expect(textOf(tester, 'given-display'), '–');
    expect(find.text('Abgeschlossen – Rückgeld 5,50 €'), findsOneWidget);
  });

  testWidgets('Tablet: reine Pfandrückgabe wird ausgezahlt', (tester) async {
    setScreen(tester, const Size(1024, 768));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pfandrückgabe'));
    await tester.tap(find.text('Pfandrückgabe'));
    await tester.pump();
    expect(find.text('Auszahlung'), findsOneWidget);
    expect(textOf(tester, 'change-display'), '4,00 €');
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets('Smartphone ${size.width.toInt()}x${size.height.toInt()}: Kasse', (tester) async {
      setScreen(tester, size);
      await tester.pumpWidget(const KassenRoot());

      await tester.tap(find.text('Bratwurst'));
      await tester.tap(find.text('Getränke'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pfandrückgabe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pfandrückgabe'));
      await tester.pump();
      expect(textOf(tester, 'cart-total'), '1,00 €');

      await tester.tap(find.text('Kasse'));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsOneWidget);

      await tester.tap(find.text('5 €'));
      await tester.pump();
      expect(textOf(tester, 'change-display'), '4,00 €');

      await tester.tap(find.byKey(const ValueKey('complete')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(textOf(tester, 'cart-total'), '0,00 €');
    });
  }
}
