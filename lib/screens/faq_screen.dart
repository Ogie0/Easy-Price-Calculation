import 'package:flutter/material.dart';

/// Kurze Hilfe für alle, die an der Kasse stehen.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _entries = [
    (
      'Wie buche ich einen Artikel?',
      'Kachel antippen. Jeder Tipp bucht eine Einheit, die Zahl auf der Kachel zeigt die Menge. '
          'Langes Drücken auf die Kachel nimmt die zuletzt gebuchte Einheit wieder heraus.',
    ),
    (
      'Wie storniere ich eine einzelne Position?',
      'Im Warenkorb auf ⊖ neben der Position tippen. Bei Getränken mit Pfand wird das Pfand '
          'automatisch mit entfernt. Der Mülleimer oben leert den ganzen Warenkorb.',
    ),
    (
      'Wie funktioniert das Pfand?',
      'Bei Getränken mit Pfand (z. B. Wasser, Softdrink, Longdrink, Bier) kommt das Pfand '
          'automatisch als eigene Position dazu. Bringt jemand einen Becher zurück, im Tab '
          '„Getränke“ auf „Pfandrückgabe“ tippen – das bucht den Pfandbetrag als Minusbetrag.',
    ),
    (
      'Wie berechne ich das Rückgeld?',
      'Auf dem Handy unten auf „Kasse“ tippen, auf dem Tablet steht der Ziffernblock rechts. '
          'Gegebenes Geld eintippen oder eine Schnelltaste (Passend, 5 €, 10 € …) wählen. '
          'Das Rückgeld erscheint grün; reicht das Geld nicht, steht dort rot „Es fehlen“.',
    ),
    (
      'Was passiert bei „Abschließen“?',
      'Der Warenkorb wird für den nächsten Kunden geleert. Ohne eingegebenes Bargeld gilt der '
          'Betrag als passend bezahlt. Vertippt? Unten erscheint kurz „Rückgängig“ – ein Tipp '
          'darauf holt den letzten Kauf zurück.',
    ),
    (
      'Wie ändere ich Preise oder lege neue Positionen an?',
      'Über das Zahnrad oben rechts. Die Einstellungen sind mit dem Master-Passwort geschützt '
          '(beim Vorstand erfragen). Dort lassen sich Preise und Pfandwert ändern, Artikel ein- '
          'und ausblenden, Pfand pro Artikel festlegen und eigene Positionen anlegen.',
    ),
    (
      'Werden Umsätze gespeichert?',
      'Nein. Die App merkt sich nur Preise, Pfandwert und Sortiment auf diesem Gerät. '
          'Verkäufe werden nicht protokolliert, und die App braucht kein Internet.',
    ),
    (
      'Geht der Bildschirm aus?',
      'Nein, solange die App geöffnet ist, bleibt der Bildschirm an. Den Akku im Blick behalten.',
    ),
    (
      'Was passiert, wenn ich die App schließe?',
      'Ist noch etwas im Warenkorb, fragt die App vorher nach. Ein offener Warenkorb geht beim '
          'Schließen verloren, Preise und Sortiment bleiben erhalten.',
    ),
    (
      'Wie installiere ich ein Update?',
      'Die neue APK aus dem GitHub-Release herunterladen und über die bestehende App '
          'installieren. Preise und eigene Positionen bleiben dabei erhalten. Die installierte '
          'Version steht ganz unten in den Einstellungen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hilfe & FAQ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (final (question, answer) in _entries)
                ExpansionTile(
                  title: Text(question, style: Theme.of(context).textTheme.titleMedium),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(answer)],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
