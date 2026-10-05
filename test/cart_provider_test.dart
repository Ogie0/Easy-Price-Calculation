import 'package:easy_price_calculation/providers/cart_provider.dart';
import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CatalogProvider catalog;
  late CartProvider cart;

  setUp(() {
    catalog = CatalogProvider();
    cart = CartProvider(catalog);
  });

  test('Speise ohne Pfand', () {
    cart.addArticle(catalog.articleById('bratwurst'));
    expect(cart.items.length, 1);
    expect(cart.totalCents, 300);
  });

  test('Pfandgetränk legt automatisch Pfand dazu', () {
    cart.addArticle(catalog.articleById('softdrink'), variant: 'Cola');
    expect(cart.items.length, 2);
    expect(cart.items.first.label, 'Softdrink (Cola)');
    expect(cart.totalCents, 250 + 200);
  });

  test('Sorte ist bei Softdrink Pflicht', () {
    expect(() => cart.addArticle(catalog.articleById('softdrink')), throwsArgumentError);
  });

  test('Storno entfernt Getränk samt Pfand', () {
    cart.addArticle(catalog.articleById('wasser'));
    cart.addArticle(catalog.articleById('pommes'));
    cart.removeItem(cart.items.first.id);
    expect(cart.items.length, 1);
    expect(cart.totalCents, 300);
  });

  test('Pfandrückgabe nutzt aktuellen Pfandwert', () {
    catalog.setDeposit(300);
    cart.addDepositReturn();
    expect(cart.totalCents, -300);
  });

  test('Preisänderung wirkt auf neue Positionen', () {
    cart.addArticle(catalog.articleById('steak'));
    catalog.setPrice('steak', 650);
    cart.addArticle(catalog.articleById('steak'));
    expect(cart.totalCents, 500 + 650);
  });

  test('Rückgeld und Kaufabschluss', () {
    cart.addArticle(catalog.articleById('longdrink'));
    expect(cart.changeFor(1000), 1000 - 800);
    expect(cart.checkout(1000), 200);
    expect(cart.isEmpty, isTrue);
    cart.addArticle(catalog.articleById('sekt'));
    expect(() => cart.checkout(100), throwsStateError);
  });

  test('Geldformatierung und -eingabe', () {
    expect(formatCents(-250), '-2,50 €');
    expect(parseCents('2,5'), 250);
    expect(parseCents('abc'), isNull);
  });
}
