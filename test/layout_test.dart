import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/providers/cart_provider.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/widgets/cart_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget buildApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CatalogProvider()),
      ChangeNotifierProxyProvider<CatalogProvider, CartProvider>(
        create: (context) => CartProvider(context.read<CatalogProvider>()),
        update: (_, catalog, cart) => cart!..updateCatalog(catalog),
      ),
    ],
    child: const KassenApp(),
  );
}

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fanta'));
    await tester.pumpAndSettle();
    expect(find.text('7,50 €'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Einstellungen'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1,50');
    await tester.enterText(fields.at(1), '3,20');
    await tester.pump();

    final catalog =
        Provider.of<CatalogProvider>(tester.element(find.byType(Scaffold).last), listen: false);
    expect(catalog.depositCents, 150);
    expect(catalog.articleById('bratwurst').priceCents, 320);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('3,20 €'), findsOneWidget);
  });
}
