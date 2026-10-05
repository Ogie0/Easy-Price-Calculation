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
    cart.addArticle(catalog.articleById('softdrink'));
    expect(cart.items.length, 2);
    expect(cart.items.first.label, 'Softdrink');
    expect(cart.totalCents, 250 + 200);
  });

  test('Storno entfernt Getränk samt Pfand', () {
    cart.addArticle(catalog.articleById('wasser'));
    cart.addArticle(catalog.articleById('pommes'));
    cart.removeItem(cart.items.first.id);
    expect(cart.items.length, 1);
    expect(cart.totalCents, 300);
  });

  test('Anzeige: neueste zuerst, Pfand direkt unter dem Getränk', () {
    cart
      ..addArticle(catalog.articleById('wasser'))
      ..addArticle(catalog.articleById('pommes'))
      ..addArticle(catalog.articleById('softdrink'))
      ..addDepositReturn();
    expect(
      cart.lines.map((l) => l.label),
      ['Pfandrückgabe', 'Softdrink', 'Pfand', 'Pommes', 'Wasser', 'Pfand'],
    );
  });

  test('Gleiche Positionen werden zusammengefasst, Storno einzeln', () {
    cart
      ..addArticle(catalog.articleById('bier'), quantity: 6)
      ..addArticle(catalog.articleById('pommes'))
      ..addArticle(catalog.articleById('bier'));
    final lines = cart.lines;
    expect(
      lines.map((l) => (l.label, l.quantity, l.totalCents)),
      [('Bier', 7, 2100), ('Pfand', 7, 1400), ('Pommes', 1, 300)],
    );

    cart.removeOneOf(lines.first);
    expect(cart.countOf('bier'), 6);
    expect(cart.totalCents, 6 * 300 + 6 * 200 + 300);

    // Pfandzeilen lassen sich nicht einzeln stornieren.
    cart.removeOneOf(cart.lines.firstWhere((l) => l.isDeposit));
    expect(cart.totalCents, 6 * 300 + 6 * 200 + 300);
  });

  test('Geänderter Preis ergibt eine eigene Zeile', () {
    cart.addArticle(catalog.articleById('steak'));
    catalog.setPrice('steak', 600);
    cart.addArticle(catalog.articleById('steak'));
    expect(cart.lines.map((l) => (l.label, l.unitCents)), [('Steak', 600), ('Steak', 500)]);
  });

  test('Menge, Pfandrückgabe und freier Betrag', () {
    cart
      ..addDepositReturn(quantity: 3)
      ..addFreeAmount('Spende', 500, quantity: 2)
      ..addFreeAmount('Rabatt', -100);
    expect(cart.totalCents, -600 + 1000 - 100);
    expect(cart.freeAmountCount, 3);
    // Zähler am Warenkorb: nur Verkauftes, keine Rückgaben oder Abzüge.
    cart.addArticle(catalog.articleById('wasser'));
    expect(cart.soldCount, 3);
    cart.removeLastOf('wasser');
    expect(
      cart.lines.map((l) => (l.label, l.quantity)),
      [('Rabatt', 1), ('Spende', 2), ('Pfandrückgabe', 3)],
    );
    cart.removeLastFreeAmount();
    expect(cart.freeAmountCount, 2);
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

  test('Rückgängig nur in einen leeren Warenkorb', () {
    cart
      ..addArticle(catalog.articleById('wasser'))
      ..addArticle(catalog.articleById('steak'));
    final snapshot = List.of(cart.items);
    cart.clear();

    cart.addArticle(catalog.articleById('pommes'));
    expect(cart.restore(snapshot), isFalse, reason: 'neuer Kauf läuft schon');
    expect(cart.items.map((i) => i.label), ['Pommes']);

    cart.clear();
    expect(cart.restore(snapshot), isTrue);
    expect(cart.items.map((i) => i.label), ['Wasser', 'Pfand', 'Steak']);
    // Stornieren nach dem Wiederherstellen funktioniert weiter (inkl. Pfand).
    cart.removeLastOf('wasser');
    expect(cart.totalCents, 500);
  });

  test('Pfandwert 0: kein Pfandposten', () {
    catalog.setDeposit(0);
    cart.addArticle(catalog.articleById('bier'));
    expect(cart.items.map((i) => i.label), ['Bier']);
  });

  test('Lange Pfandrückgabe-Storno und letzte Einheit', () {
    cart
      ..addDepositReturn()
      ..addDepositReturn()
      ..removeLastDepositReturn();
    expect(cart.totalCents, -200);
    cart.removeLastDepositReturn();
    cart.removeLastDepositReturn(); // nichts mehr da: kein Fehler
    expect(cart.isEmpty, isTrue);
  });

  test('Geldformatierung und -eingabe', () {
    expect(formatCents(-250), '-2,50 €');
    expect(formatCents(5), '0,05 €');
    final valid = {'2,5': 250, '2.50': 250, '3': 300, ',5': 50, '12,': 1200, '0,05': 5, '3,00 €': 300};
    valid.forEach((input, cents) => expect(parseCents(input), cents, reason: input));
    for (final invalid in ['', ',', 'abc', '-2', '1e3', '2,505', '1,2,3']) {
      expect(parseCents(invalid), isNull, reason: invalid);
    }
    expect(centsToInput(250), '2,50');
  });
}
