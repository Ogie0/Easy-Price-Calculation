import 'package:shared_preferences/shared_preferences.dart';

/// Speichert die in den Einstellungen geänderten Preise und den Pfandwert
/// lokal auf dem Gerät, damit sie einen Neustart der App überstehen.
class PriceStorage {
  static const _depositKey = 'deposit_cents';
  static const _pricePrefix = 'price_cents_';

  final SharedPreferences _prefs;

  PriceStorage(this._prefs);

  static Future<PriceStorage> open() async =>
      PriceStorage(await SharedPreferences.getInstance());

  int? loadDeposit() => _prefs.getInt(_depositKey);

  int? loadPrice(String articleId) => _prefs.getInt('$_pricePrefix$articleId');

  Future<void> saveDeposit(int cents) => _prefs.setInt(_depositKey, cents);

  Future<void> savePrice(String articleId, int cents) =>
      _prefs.setInt('$_pricePrefix$articleId', cents);
}
