/// Geldbeträge werden durchgängig als ganze Cent-Werte (int) geführt,
/// um Rundungsfehler von double zu vermeiden.
String formatCents(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = abs ~/ 100;
  final rest = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}$euros,$rest €';
}

/// Wandelt eine Eingabe wie "2,50", "2.5" oder "3" in Cent um.
/// Gibt null zurück, wenn die Eingabe ungültig ist.
int? parseCents(String input) {
  final normalized = input.trim().replaceAll('€', '').replaceAll(',', '.').trim();
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return (value * 100).round();
}
