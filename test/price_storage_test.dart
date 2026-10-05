import 'package:easy_price_calculation/providers/catalog_provider.dart';
import 'package:easy_price_calculation/providers/price_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Preise und Pfand überstehen einen Neustart', () async {
    SharedPreferences.setMockInitialValues({});
    final first = CatalogProvider(storage: await PriceStorage.open());
    expect(first.depositCents, 200);
    first
      ..setDeposit(250)
      ..setPrice('bratwurst', 350);

    final restarted = CatalogProvider(storage: await PriceStorage.open());
    expect(restarted.depositCents, 250);
    expect(restarted.articleById('bratwurst').priceCents, 350);
    expect(restarted.articleById('steak').priceCents, 500);
  });
}
