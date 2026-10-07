import 'package:flutter/material.dart';

/// Zeile mit Beschriftung links und großem Betrag rechts. Wird für Summe,
/// Gegeben und Rückgeld verwendet, damit alle Beträge gleich groß und
/// rechtsbündig untereinander stehen.
class AmountRow extends StatelessWidget {
  final String label;
  final String amount;
  final Key? amountKey;

  /// Hintergrund und Schriftfarbe, z. B. für die farbige Rückgeldanzeige.
  final Color? background;
  final Color? foreground;

  /// Ausgegrauter Betrag, solange noch nichts eingegeben wurde.
  final bool muted;

  /// Kleine Zusatzzeile unter dem Betrag (z. B. Stückelung des Rückgelds).
  /// Ein leerer Text hält den Platz frei, damit nichts springt.
  final String? note;
  final Key? noteKey;

  const AmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.amountKey,
    this.background,
    this.foreground,
    this.muted = false,
    this.note,
    this.noteKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelColor = foreground ?? scheme.onSurface;
    final amountColor = foreground ?? (muted ? scheme.onSurfaceVariant : scheme.onSurface);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: background == null
          ? null
          : BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: _withNote(theme, labelColor, LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            // Die Beschriftung darf höchstens gut die Hälfte belegen und wird
            // sonst verkleinert, damit der Betrag immer rechtsbündig bleibt.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: theme.textTheme.titleLarge?.copyWith(color: labelColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  key: amountKey,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: amountColor,
                    fontWeight: muted ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _withNote(ThemeData theme, Color color, Widget row) {
    final note = this.note;
    if (note == null) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        FittedBox(
          alignment: Alignment.centerRight,
          fit: BoxFit.scaleDown,
          child: Text(
            note.isEmpty ? ' ' : note,
            key: noteKey,
            style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
