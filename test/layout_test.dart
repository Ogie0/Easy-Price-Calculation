import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/widgets/article_grid.dart';
import 'package:easy_price_calculation/widgets/cart_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget buildApp() => const KassenRoot();

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Öffnet die Einstellungen mit dem Master-Passwort.
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Einstellungen'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('master-password')), '1960');
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Smartphone: Tabs und Warenkorbleiste', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());

    expect(find.text('Speisen'), findsOneWidget);
    expect(find.text('Getränke'), findsOneWidget);
    expect(find.byType(CartSummaryBar), findsOneWidget);
    expect(find.byType(CartPanel), findsNothing);

    await tester.tap(find.text('Bratwurst'));
    await tester.pump();
    expect(find.text('3,00 €'), findsWidgets);

    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Softdrink'));
    await tester.pump();
    expect(find.text('7,50 €'), findsOneWidget);

    // Pfandrückgabe als Kachel bei den Getränken.
    await tester.tap(find.widgetWithText(DepositReturnTile, 'Pfandrückgabe'));
    await tester.pump();
    expect(find.text('5,50 €'), findsOneWidget);
  });

  testWidgets('Tablet: Warenkorb dauerhaft sichtbar', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());

    expect(find.byType(CartPanel), findsOneWidget);
    expect(find.byType(CartSummaryBar), findsNothing);

    await tester.tap(find.text('Steak'));
    await tester.pump();
    expect(find.text('Steak'), findsNWidgets(2));
  });

  testWidgets('Einstellungen ändern Preis und Pfand', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());

    await openSettings(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1,50');
    await tester.enterText(fields.at(1), '3,20');
    await tester.pump();

    final catalog =
        Provider.of<CatalogProvider>(tester.element(find.byType(Scaffold).last), listen: false);
    expect(catalog.depositCents, 150);
    expect(catalog.articleById('bratwurst').priceCents, 320);

    // Deutsche System-Texte: Der Zurück-Button heißt „Zurück“.
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('3,20 €'), findsOneWidget);
  });

  testWidgets('Tablet: Tab-Leiste nur über den Kacheln', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());

    final tabBar = tester.getRect(find.byType(TabBar));
    final cart = tester.getRect(find.byType(CartPanel));
    expect(tabBar.right, lessThanOrEqualTo(cart.left));
  });

  const drinks = ['Wasser', 'Softdrink', 'Longdrink', 'Bier', 'Sekt', 'Shot', 'Pfandrückgabe'];

  for (final size in const [Size(1024, 768), Size(1280, 800)]) {
    testWidgets('Tablet ${size.width.toInt()}: alle Getränke ohne Scrollen sichtbar',
        (tester) async {
      setScreen(tester, size);
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Getränke'));
      await tester.pumpAndSettle();

      for (final name in drinks) {
        expect(find.text(name).hitTestable(), findsOneWidget, reason: name);
      }
    });
  }

  testWidgets('Smartphone mit System-Leisten: alle Getränke ohne Scrollen sichtbar',
      (tester) async {
    tester.view
      ..physicalSize = const Size(360, 780) * 2
      ..devicePixelRatio = 2
      ..padding = const FakeViewPadding(top: 24 * 2, bottom: 48 * 2);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();

    for (final name in drinks) {
      expect(find.text(name).hitTestable(), findsOneWidget, reason: name);
    }
  });

  test('Kachelraster: größte Kacheln, die noch ganz passen', () {
    // Smartphone hoch: 2 Spalten x 3 Reihen.
    final phone = GridFit.of(6, const Size(360, 470), padding: 12, spacing: 12);
    expect(phone.columns, 2);
    // Kaum Platz: lieber scrollen als winzige Kacheln.
    final tiny = GridFit.of(6, const Size(360, 200), padding: 12, spacing: 12);
    expect((tiny.columns, tiny.aspectRatio), (2, 1.0));
    // Unbegrenzte Höhe (z. B. in einer Scroll-Ansicht) bricht nicht.
    expect(GridFit.of(6, const Size(360, double.infinity), padding: 12, spacing: 12).columns, 2);
  });

  testWidgets('Zurück-Taste fragt bei gefülltem Warenkorb nach', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Bratwurst'));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('App schließen?'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('App schließen?'), findsNothing);
    expect(find.text('Bratwurst'), findsOneWidget);
  });

  testWidgets('Einstellungen: ausblenden und eigene Position anlegen', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    expect(find.text('Krakauer'), findsOneWidget);

    await openSettings(tester);

    // Krakauer ausblenden (erster „Anzeigen“-Chip nach Bratwurst/Currywurst).
    final krakauer = find.ancestor(of: find.text('Krakauer'), matching: find.byType(Column)).first;
    await tester.tap(find.descendant(of: krakauer, matching: find.text('Anzeigen')));
    await tester.pump();

    await tester.tap(find.text('Position hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('custom-name')), 'Kuchen');
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('custom-price')), matching: find.byType(TextField)),
      '1,5',
    );
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Krakauer'), findsNothing);
    expect(find.text('Kuchen'), findsOneWidget);
    expect(find.text('1,50 €'), findsOneWidget);
  });

  testWidgets('Einstellungen nur mit Master-Passwort', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('master-password')), '1234');
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Falsches Passwort'), findsOneWidget);
    expect(find.text('Pfandwert'), findsNothing);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Pfandwert'), findsNothing);

    await openSettings(tester);
    expect(find.text('Pfandwert'), findsOneWidget);
  });

  testWidgets('FAQ ohne Passwort erreichbar', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byTooltip('Hilfe & FAQ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wie funktioniert das Pfand?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pfandrückgabe'), findsOneWidget);
  });

  testWidgets('FAQ: Impressum, Nutzungsbedingungen und Lizenzen', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.byTooltip('Hilfe & FAQ'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Open-Source-Lizenzen'), 200);
    await tester.tap(find.text('Impressum'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Junggesellenclub Ellierode v. 1960'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nutzungsbedingungen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ohne Gewähr'), findsOneWidget);
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open-Source-Lizenzen'));
    await tester.pumpAndSettle();
    expect(find.text('JGC Ellierode'), findsWidgets);
  });
}
