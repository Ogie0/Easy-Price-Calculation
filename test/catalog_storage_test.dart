import 'package:easy_price_calculation/models/article.dart';
import 'package:easy_price_calculation/models/default_articles.dart';
import 'package:easy_price_calculation/providers/appearance_provider.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/services/app_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Preise und Pfand überstehen einen Neustart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CatalogProvider(storage: await AppStorage.open());
    expect(first.depositCents, 200);
    first
      ..setDeposit(250)
      ..setPrice('bratwurst', 350);

    final restarted = CatalogProvider(storage: await AppStorage.open());
    expect(restarted.depositCents, 250);
    expect(restarted.articleById('bratwurst').priceCents, 350);
    expect(restarted.articleById('steak').priceCents, 500);
  });

  test('Eigene Positionen, Sichtbarkeit und Pfand werden gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CatalogProvider(storage: await AppStorage.open());
    final kuchen = first.addCustom(
      name: ' Kuchen ',
      category: ArticleCategory.food,
      priceCents: 150,
      emoji: '🍰',
    );
    first
      ..setVisible('krakauer', false)
      ..setHasDeposit('sekt', true);
    expect(first.food.map((a) => a.name), isNot(contains('Krakauer')));
    expect(first.food.last.name, 'Kuchen');

    final restarted = CatalogProvider(storage: await AppStorage.open());
    final restored = restarted.articleById(kuchen.id);
    expect((restored.name, restored.priceCents, restored.emoji, restored.custom),
        ('Kuchen', 150, '🍰', true));
    expect(restarted.articleById('krakauer').visible, isFalse);
    expect(restarted.allOf(ArticleCategory.food).map((a) => a.name), contains('Krakauer'));
    expect(restarted.articleById('sekt').hasDeposit, isTrue);

    restarted.removeCustom(kuchen.id);
    restarted.removeCustom('bratwurst'); // Standardartikel lassen sich nicht löschen.
    final again = CatalogProvider(storage: await AppStorage.open());
    expect(again.food.map((a) => a.id), isNot(contains(kuchen.id)));
    expect(again.articleById('bratwurst').name, 'Bratwurst');
  });

  test('Preise aus der Vorversion werden übernommen', () async {
    SharedPreferences.setMockInitialValues({'price_cents_bratwurst': 420, 'deposit_cents': 100});
    final catalog = CatalogProvider(storage: await AppStorage.open());
    expect(catalog.articleById('bratwurst').priceCents, 420);
    expect(catalog.depositCents, 100);
    expect(catalog.articleById('bier').priceCents, 300);
  });

  test('Unlesbare Einträge werden übersprungen statt alles zu verwerfen', () async {
    SharedPreferences.setMockInitialValues({
      'articles_v2': '[{"id":"bratwurst","name":"Bratwurst","category":"food","priceCents":390},'
          '{"kaputt":true},'
          '{"id":"custom_1","name":"Kuchen","category":"food","priceCents":150,"custom":true}]',
    });
    final catalog = CatalogProvider(storage: await AppStorage.open());
    expect(catalog.articleById('bratwurst').priceCents, 390);
    expect(catalog.articleById('custom_1').name, 'Kuchen');

    SharedPreferences.setMockInitialValues({'articles_v2': 'kein json'});
    final fallback = CatalogProvider(storage: await AppStorage.open());
    expect(fallback.articleById('bratwurst').priceCents, 300);
  });

  test('Eigene Position bearbeiten wird gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final catalog = CatalogProvider(storage: await AppStorage.open());
    final kuchen = catalog.addCustom(
      name: 'Kuchen',
      category: ArticleCategory.food,
      priceCents: 150,
      emoji: '🍰',
    );
    catalog.updateCustom(
      kuchen.id,
      name: 'Waffel',
      category: ArticleCategory.food,
      priceCents: 200,
      hasDeposit: false,
      emoji: '',
    );
    final waffel = catalog.articleById(kuchen.id);
    expect((waffel.name, waffel.priceCents, waffel.emoji), ('Waffel', 200, null));

    // Kategorie wechseln: landet hinten bei den Getränken.
    catalog.updateCustom(
      kuchen.id,
      name: 'Kakao',
      category: ArticleCategory.drink,
      priceCents: 250,
      hasDeposit: true,
      emoji: '☕',
    );
    expect(catalog.drinks.last.name, 'Kakao');
    expect(catalog.food.map((a) => a.id), isNot(contains(kuchen.id)));

    final restarted = CatalogProvider(storage: await AppStorage.open());
    final kakao = restarted.articleById(kuchen.id);
    expect((kakao.name, kakao.category, kakao.hasDeposit, kakao.emoji),
        ('Kakao', ArticleCategory.drink, true, '☕'));

    expect(
      () => restarted.updateCustom('bier',
          name: 'X', category: ArticleCategory.drink, priceCents: 1, hasDeposit: false),
      throwsArgumentError,
      reason: 'Standardartikel sind nicht umbenennbar',
    );
  });

  test('Reihenfolge wird gespeichert, neue Standardartikel kommen hinten dazu', () async {
    SharedPreferences.setMockInitialValues({});
    final catalog = CatalogProvider(storage: await AppStorage.open());
    final drinks = catalog.allOf(ArticleCategory.drink).map((a) => a.id).toList();
    final bierIndex = drinks.indexOf('bier');
    catalog
      ..setVisible('wasser', false)
      ..moveArticle(ArticleCategory.drink, bierIndex, 0);
    expect(catalog.allOf(ArticleCategory.drink).first.id, 'bier');
    expect(catalog.drinks.first.id, 'bier');
    // Speisen bleiben unverändert.
    expect(catalog.food.first.id, 'bratwurst');

    final restarted = CatalogProvider(storage: await AppStorage.open());
    expect(restarted.allOf(ArticleCategory.drink).first.id, 'bier');

    // Ein neuer Standardartikel (hier: einer, der im Speicher fehlt).
    final withNew = CatalogProvider(
      articles: [
        ...kDefaultArticles,
        const Article(id: 'radler', name: 'Radler', category: ArticleCategory.drink, priceCents: 300),
      ],
      storage: await AppStorage.open(),
    );
    expect(withNew.allOf(ArticleCategory.drink).first.id, 'bier');
    expect(withNew.allOf(ArticleCategory.drink).last.id, 'radler');
  });

  test('Darstellung wird gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AppearanceProvider(storage: await AppStorage.open());
    expect(first.themeMode, ThemeMode.system);
    first.setThemeMode(ThemeMode.dark);

    expect(first.swipeTabs, isTrue);
    first.setSwipeTabs(false);

    final restarted = AppearanceProvider(storage: await AppStorage.open());
    expect(restarted.themeMode, ThemeMode.dark);
    expect(restarted.swipeTabs, isFalse);

    SharedPreferences.setMockInitialValues({'theme_mode': 'unbekannt'});
    final fallback = AppearanceProvider(storage: await AppStorage.open());
    expect(fallback.themeMode, ThemeMode.system);
  });
}
