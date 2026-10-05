/// Geldbeträge werden durchgängig als ganze Cent-Werte (int) geführt,
/// um Rundungsfehler von double zu vermeiden.
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = abs ~/ 100;
  final rest = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$euros,$rest €';
}

final _amountPattern = RegExp(r'^(\d{0,7})(?:[.,](\d{0,2}))?$');

/// Wandelt eine Eingabe wie "2,50", "2.5", "3" oder "12," in Cent um.
/// Gibt null zurück, wenn die Eingabe ungültig ist (leer, negativ, mehr als
/// zwei Nachkommastellen, …). Rechnet ohne Gleitkommazahlen.
int? parseCents(String input) {
  final match = _amountPattern.firstMatch(input.replaceAll('€', '').trim());
  if (match == null) return null;
  final euros = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (euros.isEmpty && fraction.isEmpty) return null;
  return int.parse(euros.isEmpty ? '0' : euros) * 100 + int.parse(fraction.padRight(2, '0'));
}

/// Betrag für ein Eingabefeld, z. B. 250 → "2,50".
String centsToInput(int cents) =>
    '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';
