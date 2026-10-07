
import 'package:easy_price_calculation/main.dart';
import 'package:easy_price_calculation/models/article.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/screens/checkout_screen.dart';
import 'package:easy_price_calculation/screens/settings_screen.dart';
import 'package:easy_price_calculation/services/app_storage.dart';
import 'package:easy_price_calculation/services/article_image_store.dart';
import 'package:easy_price_calculation/services/catalog_transfer.dart';
import 'package:easy_price_calculation/utils/money.dart';
import 'package:easy_price_calculation/widgets/article_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Einstellungen'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const ValueKey('master-password')), '1960');
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(target.hitTestable(), 300, scrollable: list);
}

String textOf(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key)).first).data!;

void main() {
  test('Rückgeld-Stückelung', () {
    expect(changeBreakdown(0), '');
    expect(changeBreakdown(1550), '10 € + 5 € + 50 ct');
    expect(changeBreakdown(4000), '2 × 20 €');
    expect(changeBreakdown(390), '2 € + 1 € + 50 ct + 2 × 20 ct');
    expect(changeBreakdown(388), '2 € + 1 € + 50 ct + 20 ct + 10 ct + 5 ct + 2 ct + 1 ct');
    expect(changeBreakdown(12000), '2 × 50 € + 20 €');
  });

  testWidgets('Stückelung erscheint unter dem Rückgeld', (tester) async {
    setScreen(tester, const Size(1280, 800));
    await tester.pumpWidget(const KassenRoot());
    await tester.tap(find.widgetWithText(ArticleTile, 'Steak'));
    await tester.pump();
    expect(textOf(tester, 'change-breakdown').trim(), isEmpty);
    await tester.tap(find.text('20 €'));
    await tester.pump();
    expect(textOf(tester, 'change-breakdown'), '10 € + 5 €');
  });

  testWidgets('Smartphone: nach dem Leeren zurück zu den Kacheln', (tester) async {
    setScreen(tester, const Size(400, 800));
    await tester.pumpWidget(const KassenRoot());
    await tester.tap(find.widgetWithText(ArticleTile, 'Steak'));
    await tester.pump();
    await tester.tap(find.text('Kasse'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Warenkorb leeren'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-clear')));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutScreen), findsNothing);
    expect(find.byType(ArticleTile), findsWidgets);
    expect(find.text('Rückgängig'), findsOneWidget);
  });

  group('Sortiment per QR-Code', () {
    test('Hin und zurück, ungültige Codes werden abgelehnt', () {
      final catalog = CatalogProvider()
        ..setPrice('bier', 350)
        ..setVisible('sekt', false)
        ..setDeposit(250);
      catalog.addCustom(name: 'Waffel 🧇', category: ArticleCategory.food, priceCents: 200, emoji: '🧇');
      catalog.moveArticle(ArticleCategory.drink, 3, 0);

      final code = CatalogTransfer(articles: catalog.all, depositCents: catalog.depositCents).encode();
      expect(code.length, lessThan(CatalogTransfer.maxLength));
      final back = CatalogTransfer.decode(code)!;
      expect(back.depositCents, 250);
      expect(back.articles.map((a) => (a.id, a.name, a.priceCents, a.visible, a.emoji)),
          catalog.all.map((a) => (a.id, a.name, a.priceCents, a.visible, a.emoji)));

      expect(CatalogTransfer.decode('https://example.org'), isNull);
      expect(CatalogTransfer.decode('KNUELLE1:kaputt'), isNull);
    });

    test('Übernehmen ersetzt das Sortiment, eigene Fotos bleiben', () async {
      SharedPreferences.setMockInitialValues({});
      final source = CatalogProvider()..setPrice('bier', 400);
      source.addCustom(name: 'Kuchen', category: ArticleCategory.food, priceCents: 250);

      final target = CatalogProvider(storage: await AppStorage.open());
      final waffel = target.addCustom(name: 'Waffel', category: ArticleCategory.food, priceCents: 200);
      target
        ..setImage('bier', '/fotos/bier.jpg')
        ..setImage(waffel.id, '/fotos/waffel.jpg');

      final unused = target.replaceAll(source.all, 150);
      expect(unused, ['/fotos/waffel.jpg']);
      expect(target.articleById('bier').priceCents, 400);
      expect(target.articleById('bier').imagePath, '/fotos/bier.jpg');
      expect(target.allOf(ArticleCategory.food).map((a) => a.name), contains('Kuchen'));
      expect(target.articleOrNull(waffel.id), isNull);
      expect(target.depositCents, 150);

      final restarted = CatalogProvider(storage: await AppStorage.open());
      expect(restarted.articleById('bier').priceCents, 400);
      expect(restarted.depositCents, 150);
    });

    testWidgets('Teilen zeigt den QR-Code, Übernehmen fragt nach', (tester) async {
      setScreen(tester, const Size(400, 800));
      final source = CatalogProvider()..setPrice('steak', 650);
      final transfer = CatalogTransfer(articles: source.all, depositCents: 300);
      final original = SettingsScreen.scan;
      SettingsScreen.scan = (_) async => transfer;
      addTearDown(() => SettingsScreen.scan = original);

      await tester.pumpWidget(const KassenRoot());
      final catalog = Provider.of<CatalogProvider>(
        tester.element(find.byType(Scaffold).first),
        listen: false,
      );
      await openSettings(tester);

      await scrollTo(tester, find.byKey(const ValueKey('share-catalog')));
      await tester.tap(find.byKey(const ValueKey('share-catalog')));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('import-catalog')));
      await tester.pumpAndSettle();
      expect(find.text('Sortiment übernehmen?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-import')));
      await tester.pumpAndSettle();
      expect(catalog.articleById('steak').priceCents, 650);
      expect(catalog.depositCents, 300);
      expect(find.textContaining('Sortiment übernommen'), findsOneWidget);
    });
  });

  testWidgets('Verlorenes Foto wird beim Start nachgeholt', (tester) async {
    setScreen(tester, const Size(400, 800));
    final store = _RecoveringStore();
    await tester.pumpWidget(KassenRoot(imageStore: store));
    await tester.pumpAndSettle();
    final catalog = Provider.of<CatalogProvider>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );
    expect(catalog.articleById('pommes').imagePath, '/fotos/pommes.jpg');
    expect(find.text('Foto für „Pommes“ übernommen'), findsOneWidget);
  });
}

class _RecoveringStore extends ArticleImageStore {
  @override
  Future<({String articleId, String path})?> recoverLost() async =>
      (articleId: 'pommes', path: '/fotos/pommes.jpg');

  @override
  Future<void> delete(String? path) async {}
}

