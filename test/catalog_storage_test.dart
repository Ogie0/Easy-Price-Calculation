import 'package:easy_price_calculation/models/article.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/services/catalog_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Preise und Pfand überstehen einen Neustart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CatalogProvider(storage: await CatalogStorage.open());
    expect(first.depositCents, 200);
    first
      ..setDeposit(250)
      ..setPrice('bratwurst', 350);

    final restarted = CatalogProvider(storage: await CatalogStorage.open());
    expect(restarted.depositCents, 250);
    expect(restarted.articleById('bratwurst').priceCents, 350);
    expect(restarted.articleById('steak').priceCents, 500);
  });

  test('Eigene Positionen, Sichtbarkeit und Pfand werden gespeichert', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CatalogProvider(storage: await CatalogStorage.open());
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

    final restarted = CatalogProvider(storage: await CatalogStorage.open());
    final restored = restarted.articleById(kuchen.id);
    expect((restored.name, restored.priceCents, restored.emoji, restored.custom),
        ('Kuchen', 150, '🍰', true));
    expect(restarted.articleById('krakauer').visible, isFalse);
    expect(restarted.allOf(ArticleCategory.food).map((a) => a.name), contains('Krakauer'));
    expect(restarted.articleById('sekt').hasDeposit, isTrue);

    restarted.removeCustom(kuchen.id);
    restarted.removeCustom('bratwurst'); // Standardartikel lassen sich nicht löschen.
    final again = CatalogProvider(storage: await CatalogStorage.open());
    expect(again.food.map((a) => a.id), isNot(contains(kuchen.id)));
    expect(again.articleById('bratwurst').name, 'Bratwurst');
  });

  test('Preise aus der Vorversion werden übernommen', () async {
    SharedPreferences.setMockInitialValues({'price_cents_bratwurst': 420, 'deposit_cents': 100});
    final catalog = CatalogProvider(storage: await CatalogStorage.open());
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
    final catalog = CatalogProvider(storage: await CatalogStorage.open());
    expect(catalog.articleById('bratwurst').priceCents, 390);
    expect(catalog.articleById('custom_1').name, 'Kuchen');

    SharedPreferences.setMockInitialValues({'articles_v2': 'kein json'});
    final fallback = CatalogProvider(storage: await CatalogStorage.open());
    expect(fallback.articleById('bratwurst').priceCents, 300);
  });
}
