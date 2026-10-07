import 'package:easy_price_calculation/models/article.dart';
import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/screens/home_screen.dart';
import 'package:easy_price_calculation/widgets/article_grid.dart';
import 'package:easy_price_calculation/widgets/cart_panel.dart';
import 'package:easy_price_calculation/services/article_image_store.dart';
import 'package:easy_price_calculation/widgets/article_art.dart';
import 'package:easy_price_calculation/widgets/checkout_panel.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  const drinks = ['Wasser', 'Softdrink', 'Longdrink', 'Bier/Radler', 'Sekt', 'Shot', 'Pfandrückgabe'];

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
    expect(find.text('Knülle Kalkulieren - JGC'), findsWidgets);
  });

  testWidgets('Langes Drücken nimmt eine Einheit heraus', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Steak'));
    await tester.tap(find.text('Steak'));
    await tester.pump();
    Finder badge(String n) => find.descendant(of: find.byType(CircleAvatar), matching: find.text(n));
    expect(badge('2'), findsOneWidget);

    await tester.longPress(find.text('Steak').first);
    await tester.pump();
    expect(badge('1'), findsOneWidget);
  });

  testWidgets('Leerer Tab zeigt einen Hinweis, Pfandwert 0 blendet Pfand aus', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    for (final a in catalog.food) {
      catalog.setVisible(a.id, false);
    }
    catalog.setDeposit(0);
    await tester.pump();
    expect(find.textContaining('Hier ist gerade nichts sichtbar'), findsOneWidget);

    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();
    expect(find.text('Pfandrückgabe'), findsNothing);
    expect(find.textContaining('+ Pfand'), findsNothing);
  });

  testWidgets('Einstellungen: eigene Position löschen, Preisfeld korrigiert sich', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    catalog.addCustom(name: 'Kuchen', category: ArticleCategory.food, priceCents: 150);
    await openSettings(tester);

    // Preisfeld leeren und verlassen: Der gespeicherte Preis erscheint wieder.
    final bratwurstField = find.descendant(
      of: find.ancestor(of: find.text('Bratwurst'), matching: find.byType(ListTile)),
      matching: find.byType(TextField),
    );
    await tester.enterText(bratwurstField, '');
    await tester.pump();
    expect(find.text('Ungültiger Betrag'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.text('Ungültiger Betrag'), findsNothing);
    expect(tester.widget<TextField>(bratwurstField).controller!.text, '3,00');

    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Löschen').hitTestable(), 200, scrollable: settingsList);
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(catalog.food.map((a) => a.name), isNot(contains('Kuchen')));
  });

  testWidgets('Mengentaste: ×5 bucht eine Runde, danach wieder einzeln', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quantity-5')));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, '×5'), findsOneWidget);
    await tester.tap(find.text('Bier/Radler'));
    await tester.pump();
    expect(find.text('5 × Bier/Radler'), findsOneWidget);
    expect(find.text('5 × Pfand'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '×5'), findsNothing, reason: 'gilt nur einmal');

    await tester.tap(find.text('Bier/Radler'));
    await tester.pump();
    expect(find.text('6 × Bier/Radler'), findsOneWidget);

    // Nochmal tippen hebt die Auswahl wieder auf.
    await tester.tap(find.byKey(const ValueKey('quantity-3')));
    await tester.tap(find.byKey(const ValueKey('quantity-3')));
    await tester.pump();
    await tester.tap(find.text('Sekt'));
    await tester.pump();
    expect(find.text('Sekt'), findsNWidgets(2));

    // ⊖ storniert eine Einheit der Runde.
    final bierLine = find.ancestor(of: find.text('6 × Bier/Radler'), matching: find.byType(ListTile));
    await tester.tap(find.descendant(of: bierLine, matching: find.byTooltip('Stornieren')));
    await tester.pump();
    expect(find.text('5 × Bier/Radler'), findsOneWidget);
  });

  testWidgets('Freier Betrag mit Bezeichnung und als Abzug', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());

    await tester.tap(find.text('Freier Betrag'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hinzufügen'));
    await tester.pump();
    expect(find.text('Bitte einen Betrag eingeben'), findsOneWidget);

    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('free-amount')), matching: find.byType(TextField)),
      '5',
    );
    await tester.enterText(find.byKey(const ValueKey('free-label')), 'Spende');
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Spende'), findsOneWidget);

    await tester.tap(find.text('Freier Betrag'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('free-amount')), matching: find.byType(TextField)),
      '1',
    );
    await tester.tap(find.text('Als Abzug (minus)'));
    await tester.tap(find.text('Hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Abzug'), findsOneWidget);
    expect(find.text('-1,00 €'), findsOneWidget);
    expect(find.text('4,00 €'), findsWidgets);
  });

  testWidgets('Einstellungen: eigene Position bearbeiten', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    catalog.addCustom(name: 'Kuchen', category: ArticleCategory.food, priceCents: 150);
    await openSettings(tester);

    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Bearbeiten').hitTestable(), 200, scrollable: settingsList);
    await tester.tap(find.text('Bearbeiten'));
    await tester.pumpAndSettle();
    expect(find.text('Position bearbeiten'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('custom-name')), 'Waffel');
    await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('custom-price')), matching: find.byType(TextField)),
      '2,5',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final waffelField = find.descendant(
      of: find.ancestor(of: find.text('Waffel'), matching: find.byType(ListTile)),
      matching: find.byType(TextField),
    );
    expect(tester.widget<TextField>(waffelField).controller!.text, '2,50');

    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect(find.text('Waffel'), findsOneWidget);
    expect(find.text('Kuchen'), findsNothing);
  });

  testWidgets('Reihenfolge per Ziehen ändern', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    await openSettings(tester);

    // „Reihenfolge“ bei den Getränken (zweiter Abschnitt).
    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final reorderDrinks = find.byKey(const ValueKey('reorder-drink'));
    await tester.scrollUntilVisible(reorderDrinks.hitTestable(), 200, scrollable: settingsList);
    await tester.tap(reorderDrinks);
    await tester.pumpAndSettle();
    expect(find.text('Reihenfolge: Getränke'), findsOneWidget);

    final lastBefore = catalog.allOf(ArticleCategory.drink).last.id;
    await tester.drag(find.byIcon(Icons.drag_handle).last, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(catalog.allOf(ArticleCategory.drink).first.id, lastBefore);
  });

  testWidgets('Darstellung: Dunkel, Hell und automatisch wie am Handy', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(HomeScreen, skipOffstage: false))).brightness;
    expect(brightness(), Brightness.light);

    await openSettings(tester);
    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Dunkel').hitTestable(), 300, scrollable: settingsList);
    await tester.tap(find.text('Dunkel'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    // „Automatisch“ folgt der Einstellung des Handys.
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.tap(find.text('Automatisch'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('Hell'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('Tippen baut nur neu, was sich ändert', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(buildApp());
    final rebuilt = <Type>{};
    debugOnRebuildDirtyWidget = (element, _) => rebuilt.add(element.widget.runtimeType);
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    // Erster Tipp nach leerem Warenkorb, weitere Tipps, Bargeld eintippen.
    await tester.tap(find.widgetWithText(ArticleTile, 'Steak'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ArticleTile, 'Steak'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('numpad-5')));
    await tester.pump();
    debugOnRebuildDirtyWidget = null;

    expect(rebuilt, containsAll([CartPanel]));
    expect(rebuilt, isNot(contains(HomeScreen)));
    expect(rebuilt, isNot(contains(ArticleGrid)));
    expect(rebuilt, isNot(contains(ArticleTile)));
    expect(rebuilt, isNot(contains(CheckoutPanel)));
    expect(rebuilt, isNot(contains(Numpad)));
  });

  testWidgets('Smartphone: Abschließen erst nach Bargeldeingabe', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    await tester.tap(find.widgetWithText(ArticleTile, 'Bratwurst'));
    await tester.pump();
    await tester.tap(find.text('Kasse'));
    await tester.pumpAndSettle();

    ButtonStyleButton complete() =>
        tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('complete')));
    expect(complete().enabled, isFalse);
    await tester.tap(find.text('Passend'));
    await tester.pump();
    expect(complete().enabled, isTrue);
  });

  testWidgets('Smartphone: „Alle löschen“ neben Kasse, mit Rückgängig', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    final clearAll = find.byKey(const ValueKey('clear-all'));
    expect(tester.widget<ButtonStyleButton>(clearAll).enabled, isFalse);

    await tester.tap(find.widgetWithText(ArticleTile, 'Bratwurst'));
    await tester.tap(find.widgetWithText(ArticleTile, 'Steak'));
    await tester.pump();
    // Abbrechen lässt alles, wie es ist.
    await tester.tap(clearAll);
    await tester.pumpAndSettle();
    expect(find.text('Warenkorb leeren?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data, '8,00 €');

    await tester.tap(clearAll);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-clear')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data, '0,00 €');

    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Rückgängig'));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data, '8,00 €');
  });

  testWidgets('Wischen zwischen Speisen und Getränken lässt sich sperren', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    Future<void> swipeLeft() async {
      await tester.fling(find.byType(TabBarView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
    }

    await swipeLeft();
    expect(find.text('Bier/Radler'), findsOneWidget, reason: 'Wischen ist anfangs erlaubt');
    await tester.tap(find.text('Speisen'));
    await tester.pumpAndSettle();

    await openSettings(tester);
    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final toggle = find.byKey(const ValueKey('swipe-tabs'));
    await tester.scrollUntilVisible(toggle.hitTestable(), 300, scrollable: settingsList);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();

    await swipeLeft();
    expect(find.text('Bier/Radler'), findsNothing, reason: 'gesperrt: bleibt bei Speisen');
    await tester.tap(find.text('Getränke'));
    await tester.pumpAndSettle();
    expect(find.text('Bier/Radler'), findsOneWidget, reason: 'Reiter funktionieren weiter');
  });

  testWidgets('Kacheln zeigen gezeichnete Bilder, auf Wunsch Emojis', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(buildApp());
    Finder artOf(String name) =>
        find.descendant(of: find.widgetWithText(ArticleTile, name), matching: find.byType(ArticleArtView));
    Widget shown(String name) =>
        tester.widget(find.descendant(of: artOf(name), matching: find.byWidgetPredicate((w) => w is Image || w is Text)).first);

    expect(((shown('Bratwurst') as Image).image as AssetImage).assetName, 'assets/articles/bratwurst.png');

    await openSettings(tester);
    final settingsList =
        find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final toggle = find.byKey(const ValueKey('show-images'));
    await tester.scrollUntilVisible(toggle.hitTestable(), 300, scrollable: settingsList);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Zurück'));
    await tester.pumpAndSettle();
    expect((shown('Bratwurst') as Text).data, '🌭');
  });

  testWidgets('Eigenes Foto für eine Kachel und zurück zum Standardbild', (tester) async {
    setScreen(tester, const Size(400, 800));
    final dir = Directory.systemTemp.createTempSync('fotos');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = _FakeImageStore(dir);
    await tester.pumpWidget(KassenRoot(imageStore: store));
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );

    await openSettings(tester);
    await tester.tap(find.byKey(const ValueKey('image-bratwurst')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto aus der Galerie'));
    await tester.pumpAndSettle();
    final path = catalog.articleById('bratwurst').imagePath;
    expect(path, isNotNull);
    expect(store.sources, [ImageSource.gallery]);

    await tester.tap(find.byKey(const ValueKey('image-bratwurst')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('image-reset')));
    await tester.pumpAndSettle();
    expect(catalog.articleById('bratwurst').imagePath, isNull);
    expect(store.deleted, [path]);
  });
}

class _FakeImageStore extends ArticleImageStore {
  final Directory dir;
  final sources = <ImageSource>[];
  final deleted = <String?>[];

  _FakeImageStore(this.dir);

  @override
  Future<String?> pick(String articleId, ImageSource source) async {
    sources.add(source);
    return '${dir.path}/$articleId.png';
  }

  @override
  Future<void> delete(String? path) async {
    if (path != null) deleted.add(path);
  }
}
