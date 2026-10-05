import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/catalog_provider.dart';
import '../utils/money.dart';
import '../utils/version.dart';
import '../widgets/article_emoji.dart';

/// Preise, Pfandwert und Sortiment: Artikel ein- und ausblenden, Pfand
/// pro Artikel, eigene Positionen anlegen und löschen. Änderungen gelten
/// sofort und werden gespeichert.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addCustom(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final result = await showDialog<_NewArticle>(
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
                const _SectionHeader('Speisen'),
                for (final a in catalog.allOf(ArticleCategory.food)) _ArticleSettings(article: a),
                const _SectionHeader('Getränke'),
                for (final a in catalog.allOf(ArticleCategory.drink)) _ArticleSettings(article: a),
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

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// Preis plus Schalter „Anzeigen“ und „Pfand“, bei eigenen Positionen
/// zusätzlich „Löschen“.
class _ArticleSettings extends StatelessWidget {
  final Article article;

  const _ArticleSettings({required this.article});

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
              if (article.custom)
                ActionChip(
                  avatar: const Icon(Icons.delete_outline),
                  label: const Text('Löschen'),
                  onPressed: () => _confirmDelete(context),
                ),
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: centsToInput(widget.initialCents));
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
    if (cents != null) widget.onChanged(cents);
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
          child: _PriceField(controller: _controller, error: _error, onChanged: _onChanged),
        ),
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;
  final String? label;

  const _PriceField({super.key, required this.controller, this.error, this.onChanged, this.label});

  static final _allowedInput = RegExp(r'^\d{0,4}([.,]\d{0,2})?$');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) => _allowedInput.hasMatch(newValue.text) ? newValue : oldValue,
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
        isDense: true,
        errorText: error,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

typedef _NewArticle = ({
  String name,
  ArticleCategory category,
  int priceCents,
  bool hasDeposit,
  String? emoji,
});

/// Dialog für eine frei gestaltete Position.
class _CustomArticleDialog extends StatefulWidget {
  const _CustomArticleDialog();

  @override
  State<_CustomArticleDialog> createState() => _CustomArticleDialogState();
}

class _CustomArticleDialogState extends State<_CustomArticleDialog> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _emoji = TextEditingController();
  var _category = ArticleCategory.food;
  var _hasDeposit = false;
  String? _nameError;
  String? _priceError;

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
    Navigator.pop<_NewArticle>(context, (
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
      title: const Text('Neue Position'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const ValueKey('custom-name'),
              controller: _name,
              autofocus: true,
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
            _PriceField(
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
              controller: _emoji,
              decoration: const InputDecoration(
                labelText: 'Emoji (optional)',
                hintText: 'z. B. 🍰',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(onPressed: _submit, child: const Text('Hinzufügen')),
      ],
    );
  }
}
