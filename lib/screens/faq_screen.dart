import 'package:flutter/material.dart';

import '../legal_texts.dart';
import '../theme.dart';
import '../utils/version.dart';
import '../widgets/club_logo.dart';

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
      'Wie buche ich eine Runde?',
      'Über den Kacheln die Menge wählen (×2 bis ×10) und dann die Kachel antippen, z. B. ×6 und '
          'Bier. Die Menge gilt nur für diesen einen Tipp, danach wieder einzeln. Nochmal auf die '
          'gewählte Menge tippen hebt sie auf. Im Warenkorb steht dann „6 × Bier“.',
    ),
    (
      'Wie buche ich etwas, das nicht im Sortiment ist?',
      'Kachel „Freier Betrag“ antippen, Betrag eingeben und optional eine Bezeichnung wie '
          '„Spende“ oder „Los“. Mit „Als Abzug“ wird der Betrag abgezogen, z. B. für einen Rabatt.',
    ),
    (
      'Wie storniere ich eine einzelne Position?',
      'Im Warenkorb auf ⊖ neben der Position tippen – bei „6 × Bier“ wird jeweils ein Bier '
          'storniert. Bei Getränken mit Pfand wird das Pfand automatisch mit entfernt. Der Mülleimer oben leert den ganzen Warenkorb – auch das '
          'lässt sich über „Rückgängig“ in der Meldung unten zurückholen.',
    ),
    (
      'Wie funktioniert das Pfand?',
      'Bei Getränken mit Pfand (z. B. Wasser, Softdrink, Longdrink, Bier) kommt das Pfand '
          'automatisch als eigene Position dazu. Bringt jemand einen Becher zurück, im Tab '
          '„Getränke“ auf „Pfandrückgabe“ tippen – das bucht den Pfandbetrag als Minusbetrag. '
          'Steht der Pfandwert in den Einstellungen auf 0,00 €, ist Pfand ganz ausgeschaltet.',
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
          'und ausblenden, Pfand pro Artikel festlegen, die Reihenfolge der Kacheln ändern '
          '(„Reihenfolge“) und eigene Positionen anlegen, bearbeiten und löschen.',
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
      'Gibt es einen Dunkelmodus?',
      'Ja. Die App richtet sich automatisch nach dem Handy: Ist dort das dunkle Design an, ist '
          'auch die Kasse dunkel. In den Einstellungen unter „Darstellung“ lässt sich „Hell“ oder '
          '„Dunkel“ fest einstellen. Dunkel blendet abends weniger und spart bei vielen Handys Akku.',
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

  void _openText(BuildContext context, String title, String text) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [SelectableText(text.trim())],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
              const Divider(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  'Rechtliches',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Impressum'),
                onTap: () => _openText(context, 'Impressum', kImpressum),
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Nutzungsbedingungen'),
                onTap: () => _openText(context, 'Nutzungsbedingungen', kNutzungsbedingungen),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Open-Source-Lizenzen'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: kAppName,
                  applicationVersion: kAppVersion,
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(8),
                    child: const ClubLogo(height: 72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
