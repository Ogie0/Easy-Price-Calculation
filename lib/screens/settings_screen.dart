import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/appearance_provider.dart';
import '../providers/catalog_provider.dart';
import '../utils/money.dart';
import '../utils/version.dart';
import '../widgets/article_emoji.dart';
import '../widgets/price_field.dart';
import 'reorder_screen.dart';

/// Preise, Pfandwert und Sortiment: Artikel ein- und ausblenden, Pfand
/// pro Artikel, Reihenfolge der Kacheln, eigene Positionen anlegen,
/// bearbeiten und löschen; dazu die Darstellung (hell/dunkel). Änderungen
/// gelten sofort und werden gespeichert.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addCustom(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final result = await showDialog<_ArticleInput>(
      context: context,
      builder: (_) => const _CustomArticleDialog(),
    );
    if (result == null) return;
    catalog.addCustom(
      name: result.name,
      category: result.category,
      priceCents: result.priceCents,
      hasDeposit: result.hasDeposit,
      emoji: result.emoji,
    );
  }

  void _openReorder(BuildContext context, ArticleCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ReorderScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Position hinzufügen'),
        onPressed: () => _addCustom(context),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              // Unten Platz, damit der Button nichts verdeckt.
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
              children: [
                const _SectionHeader('Pfand'),
                _PriceRow(
                  key: const ValueKey('deposit'),
                  label: 'Pfandwert',
                  emoji: kDepositEmoji,
                  initialCents: catalog.depositCents,
                  onChanged: catalog.setDeposit,
                ),
                for (final (category, title) in const [
                  (ArticleCategory.food, 'Speisen'),
                  (ArticleCategory.drink, 'Getränke'),
                ]) ...[
                  _SectionHeader(
                    title,
                    action: TextButton.icon(
                      key: ValueKey('reorder-${category.name}'),
                      icon: const Icon(Icons.swap_vert),
                      label: const Text('Reihenfolge'),
                      onPressed: () => _openReorder(context, category),
                    ),
                  ),
                  for (final a in catalog.allOf(category)) _ArticleSettings(article: a),
                ],
                const _SectionHeader('Darstellung'),
                const _ThemeModeSetting(),
                const Divider(height: 32),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  subtitle: Text(kAppVersion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, action == null ? 16 : 8, 8, action == null ? 4 : 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Hell, dunkel oder automatisch wie am Handy eingestellt.
class _ThemeModeSetting extends StatelessWidget {
  const _ThemeModeSetting();

  static const _options = [
    (ThemeMode.system, Icons.brightness_auto_outlined, 'Automatisch', 'Wie am Handy eingestellt'),
    (ThemeMode.light, Icons.light_mode_outlined, 'Hell', null),
    (ThemeMode.dark, Icons.dark_mode_outlined, 'Dunkel', null),
  ];

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppearanceProvider, ThemeMode>((a) => a.themeMode);
    return RadioGroup<ThemeMode>(
      groupValue: mode,
      onChanged: (value) {
        if (value != null) context.read<AppearanceProvider>().setThemeMode(value);
      },
      child: Column(
        children: [
          for (final (value, icon, title, subtitle) in _options)
            RadioListTile<ThemeMode>(
              value: value,
              secondary: Icon(icon),
              title: Text(title),
              subtitle: subtitle == null ? null : Text(subtitle),
            ),
        ],
      ),
    );
  }
}

/// Preis plus Schalter „Anzeigen“ und „Pfand“, bei eigenen Positionen
/// zusätzlich „Bearbeiten“ und „Löschen“.
class _ArticleSettings extends StatelessWidget {
  final Article article;

  const _ArticleSettings({required this.article});

  Future<void> _edit(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final result = await showDialog<_ArticleInput>(
      context: context,
      builder: (_) => _CustomArticleDialog(initial: article),
    );
    if (result == null) return;
    catalog.updateCustom(
      article.id,
      name: result.name,
      category: result.category,
      priceCents: result.priceCents,
      hasDeposit: result.hasDeposit,
      emoji: result.emoji,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('„${article.name}“ löschen?'),
        content: const Text('Die Position verschwindet aus der Kasse und den Einstellungen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (delete ?? false) catalog.removeCustom(article.id);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();
    return Column(
      key: ValueKey(article.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PriceRow(
          key: ValueKey('price-${article.id}'),
          label: article.name,
          emoji: emojiFor(article),
          initialCents: article.priceCents,
          dimmed: !article.visible,
          onChanged: (cents) => catalog.setPrice(article.id, cents),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(68, 0, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Anzeigen'),
                selected: article.visible,
                onSelected: (value) => catalog.setVisible(article.id, value),
              ),
              FilterChip(
                label: const Text('Pfand'),
                selected: article.hasDeposit,
                onSelected: (value) => catalog.setHasDeposit(article.id, value),
              ),
              if (article.custom) ...[
                ActionChip(
                  avatar: const Icon(Icons.edit_outlined),
                  label: const Text('Bearbeiten'),
                  onPressed: () => _edit(context),
                ),
                ActionChip(
                  avatar: const Icon(Icons.delete_outline),
                  label: const Text('Löschen'),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatefulWidget {
  final String label;
  final String emoji;
  final int initialCents;
  final ValueChanged<int> onChanged;

  /// Ausgegraut für ausgeblendete Artikel.
  final bool dimmed;

  const _PriceRow({
    super.key,
    required this.label,
    required this.emoji,
    required this.initialCents,
    required this.onChanged,
    this.dimmed = false,
  });

  @override
  State<_PriceRow> createState() => _PriceRowState();
}

class _PriceRowState extends State<_PriceRow> {
  late final TextEditingController _controller;
  late int _lastValid;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lastValid = widget.initialCents;
    _controller = TextEditingController(text: centsToInput(widget.initialCents));
  }

  @override
  void didUpdateWidget(_PriceRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Preis wurde anderswo geändert (z. B. über „Bearbeiten“): Feld anpassen.
    if (widget.initialCents != _lastValid) {
      _lastValid = widget.initialCents;
      _controller.text = centsToInput(widget.initialCents);
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final cents = parseCents(text);
    final error = cents == null ? 'Ungültiger Betrag' : null;
    if (error != _error) setState(() => _error = error);
    if (cents == null) return;
    _lastValid = cents;
    widget.onChanged(cents);
  }

  /// Beim Verlassen des Feldes steht dort wieder der gültige, gespeicherte
  /// Preis (z. B. „3,00“ statt „3“ oder eines leeren Feldes).
  void _onFocusChange(bool focused) {
    if (focused) return;
    setState(() {
      _controller.text = centsToInput(_lastValid);
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.dimmed ? 0.5 : 1,
      child: ListTile(
        leading: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
        title: Text(widget.label),
        trailing: SizedBox(
          width: 120,
          child: Focus(
            onFocusChange: _onFocusChange,
            child: PriceField(controller: _controller, error: _error, onChanged: _onChanged),
          ),
        ),
      ),
    );
  }
}

typedef _ArticleInput = ({
  String name,
  ArticleCategory category,
  int priceCents,
  bool hasDeposit,
  String? emoji,
});

/// Dialog für eine frei gestaltete Position: neu anlegen oder – mit
/// [initial] – bearbeiten.
class _CustomArticleDialog extends StatefulWidget {
  final Article? initial;

  const _CustomArticleDialog({this.initial});

  @override
  State<_CustomArticleDialog> createState() => _CustomArticleDialogState();
}

class _CustomArticleDialogState extends State<_CustomArticleDialog> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _price = TextEditingController(
    text: widget.initial == null ? null : centsToInput(widget.initial!.priceCents),
  );
  late final _emoji = TextEditingController(text: widget.initial?.emoji);
  late var _category = widget.initial?.category ?? ArticleCategory.food;
  late var _hasDeposit = widget.initial?.hasDeposit ?? false;
  String? _nameError;
  String? _priceError;

  bool get _editing => widget.initial != null;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _emoji.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final cents = parseCents(_price.text);
    setState(() {
      _nameError = name.isEmpty ? 'Bitte einen Namen eingeben' : null;
      _priceError = cents == null ? 'Bitte einen Preis eingeben' : null;
    });
    if (name.isEmpty || cents == null) return;
    Navigator.pop<_ArticleInput>(context, (
      name: name,
      category: _category,
      priceCents: cents,
      hasDeposit: _hasDeposit,
      emoji: _emoji.text.trim().isEmpty ? null : _emoji.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Position bearbeiten' : 'Neue Position'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('custom-name'),
              controller: _name,
              autofocus: !_editing,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'z. B. Kuchen',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ArticleCategory>(
              segments: const [
                ButtonSegment(value: ArticleCategory.food, label: Text('Speisen')),
                ButtonSegment(value: ArticleCategory.drink, label: Text('Getränke')),
              ],
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
            ),
            const SizedBox(height: 16),
            PriceField(
              key: const ValueKey('custom-price'),
              controller: _price,
              label: 'Preis',
              error: _priceError,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mit Pfand'),
              value: _hasDeposit,
              onChanged: (v) => setState(() => _hasDeposit = v),
            ),
            TextField(
              key: const ValueKey('custom-emoji'),
              controller: _emoji,
              // Ein Emoji (zählt als ein Zeichen, auch wenn es zusammengesetzt ist).
              maxLength: 1,
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                hintText: 'z. B. 🍰',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Speichern' : 'Hinzufügen'),
        ),
      ],
    );
  }
}
