import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/providers/cart_provider.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
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

    test('Leerer Warenkorb löscht die Bargeldeingabe', () {
      final catalog = CatalogProvider();
      final cart = CartProvider(catalog);
      final checkout = CheckoutProvider(cart: cart);

      cart.addArticle(catalog.articleById('steak'));
      checkout.pressDigit(2);
      cart.addArticle(catalog.articleById('pommes'));
      expect(checkout.givenCents, 200, reason: 'Hinzufügen löscht nichts');

      cart.clear();
      expect(checkout.givenCents, isNull);

      cart.addArticle(catalog.articleById('steak'));
      checkout.pressDigit(5);
      cart.removeLastOf('steak');
      expect(checkout.givenCents, isNull, reason: 'letzte Position storniert');
    });

    test('PaymentStatus', () {
      final waiting = PaymentStatus.of(totalCents: 450, givenCents: null);
      expect((waiting.state, waiting.canComplete), (PaymentState.awaitingCash, false));
      expect(PaymentStatus.of(totalCents: 0, givenCents: null).canComplete, isTrue);
      final change = PaymentStatus.of(totalCents: 450, givenCents: 1000);
      expect((change.state, change.cents), (PaymentState.change, 550));
      final missing = PaymentStatus.of(totalCents: 450, givenCents: 200);
      expect((missing.state, missing.cents, missing.canComplete), (PaymentState.missing, 250, false));
      final payout = PaymentStatus.of(totalCents: -400, givenCents: null);
      expect((payout.state, payout.cents, payout.canComplete), (PaymentState.payout, 400, true));
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
    expect(textOf(tester, 'given-display'), '0,00 €');
    expect(textOf(tester, 'change-display'), '0,00 €');
    expect(find.text('Abgeschlossen – Rückgeld 5,50 €'), findsOneWidget);
  });

  testWidgets('Rückgängig nach dem Abschließen stellt Kauf wieder her', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Steak'));
    await tester.pump();
    await press(tester, '2 0');
    await tester.tap(find.byKey(const ValueKey('complete')));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '0,00 €');

    await tester.pump(const Duration(milliseconds: 500)); // Snackbar fährt ein
    await tester.tap(find.text('Rückgängig'));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '5,00 €');
    expect(textOf(tester, 'given-display'), '20 €');
    expect(textOf(tester, 'change-display'), '15,00 €');
  });

  testWidgets('Tablet: Warenkorb leeren löscht auch das Bargeld', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Steak'));
    await tester.pump();
    await press(tester, '2 0');
    expect(textOf(tester, 'given-display'), '20 €');

    await tester.tap(find.byTooltip('Warenkorb leeren'));
    await tester.pump();
    expect(textOf(tester, 'given-display'), '0,00 €');
    expect(textOf(tester, 'change-display'), '0,00 €');
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

  // Smartphones inkl. Status- (24 dp) und Navigationsleiste (48 dp). Auf
  // üblichen Geräten mind. 48 dp große Tasten, auf sehr kleinen etwas weniger;
  // Summe und „Abschließen“ sind immer ohne Scrollen sichtbar.
  for (final (size, minKey) in const [
    (Size(412, 915), 48.0),
    (Size(360, 780), 48.0),
    (Size(360, 740), 48.0),
    (Size(360, 640), 40.0),
  ]) {
    for (final textScale in const [1.0, 1.3]) {
      testWidgets(
          'Kasse ${size.width.toInt()}x${size.height.toInt()}, Schrift x$textScale: '
          'Tasten mind. ${minKey.toInt()} dp', (tester) async {
        tester.view
          ..physicalSize = size * 2
          ..devicePixelRatio = 2
          ..padding = const FakeViewPadding(top: 24 * 2, bottom: 48 * 2);
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(const KassenRoot());
        await tester.tap(find.text('Bratwurst'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kasse'));
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byKey(const ValueKey('numpad-5'))).height,
          greaterThanOrEqualTo(minKey),
        );
        expect(find.byKey(const ValueKey('cart-total')).hitTestable(), findsOneWidget);
        expect(find.byKey(const ValueKey('complete')).hitTestable(), findsOneWidget);
      });
    }
  }

  testWidgets('Schnelltasten: Passend und fester Betrag', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());
    final passend = find.ancestor(of: find.text('Passend'), matching: find.byType(OutlinedButton));
    expect(tester.widget<OutlinedButton>(passend).onPressed, isNull);

    await tester.tap(find.text('Steak'));
    await tester.pump();
    await tester.tap(find.text('Pommes'));
    await tester.pump();
    await tester.tap(find.text('Passend'));
    await tester.pump();
    expect(textOf(tester, 'given-display'), '8 €');
    expect(textOf(tester, 'change-display'), '0,00 €');

    await tester.tap(find.text('20 €'));
    await tester.pump();
    expect(textOf(tester, 'change-display'), '12,00 €');
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('complete'))).onPressed, isNotNull);
  });

  testWidgets('Warenkorb leeren lässt sich rückgängig machen', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Steak'));
    await tester.pump();
    await press(tester, '1 0');
    await tester.tap(find.byTooltip('Warenkorb leeren'));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '0,00 €');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Rückgängig'));
    await tester.pump();
    expect(textOf(tester, 'cart-total'), '5,00 €');
    expect(textOf(tester, 'given-display'), '10 €');
  });

  testWidgets('Rückgängig nach neuer Buchung wird abgelehnt', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await tester.tap(find.text('Steak'));
    await tester.pump();
    await tester.tap(find.text('Passend'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('complete')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Pommes')); // nächster Kunde
    await tester.pump(const Duration(milliseconds: 500)); // Meldung ganz eingeblendet

    await tester.tap(find.text('Rückgängig'));
    await tester.pump(const Duration(seconds: 1)); // alte Meldung geht, Hinweis kommt
    await tester.pump(const Duration(seconds: 1));
    expect(textOf(tester, 'cart-total'), '3,00 €');
    expect(find.textContaining('nicht möglich'), findsOneWidget);
  });

  testWidgets('Taste 00 und Auszahlung beim Abschließen', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());

    await press(tester, '5 00');
    expect(textOf(tester, 'given-display'), '500 €');
    await press(tester, 'C');

    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pfandrückgabe'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('complete')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Abgeschlossen – Auszahlung 2,00 €'), findsOneWidget);
  });
}
