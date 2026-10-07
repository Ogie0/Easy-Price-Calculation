import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/appearance_provider.dart';
import '../providers/catalog_provider.dart';
import '../utils/money.dart';
import '../utils/version.dart';
import '../services/article_image_store.dart';
import '../services/catalog_transfer.dart';
import '../widgets/article_art.dart';
import '../widgets/price_field.dart';
import 'catalog_share_screen.dart';
import 'reorder_screen.dart';

/// Preise, Pfandwert und Sortiment: Artikel ein- und ausblenden, Pfand
/// pro Artikel, Reihenfolge der Kacheln, eigene Positionen anlegen,
/// bearbeiten und löschen; dazu Darstellung (hell/dunkel) und Wischen. Änderungen
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

  /// Scannt den QR-Code eines anderen Geräts (in Tests austauschbar).
  @visibleForTesting
  static Future<CatalogTransfer?> Function(BuildContext context) scan = (context) =>
      Navigator.of(context).push<CatalogTransfer>(
        MaterialPageRoute(builder: (_) => const CatalogScanScreen()),
      );

  Future<void> _importCatalog(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final store = context.read<ArticleImageStore>();
    final messenger = ScaffoldMessenger.of(context);
    final transfer = await scan(context);
    if (transfer == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sortiment übernehmen?'),
        content: Text(
          '${transfer.articles.length} Artikel, Pfand ${formatCents(transfer.depositCents)}.\n\n'
          'Preise, Pfand, Reihenfolge, Sichtbarkeit und eigene Positionen dieses Geräts werden '
          'ersetzt. Eigene Fotos bleiben bei den Artikeln, die es weiterhin gibt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(
            key: const ValueKey('confirm-import'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Übernehmen'),
          ),
        ],
      ),
    );
    if (!(ok ?? false)) return;
    final unused = catalog.replaceAll(transfer.articles, transfer.depositCents);
    messenger.showSnackBar(
      SnackBar(content: Text('Sortiment übernommen (${transfer.articles.length} Artikel)')),
    );
    for (final path in unused) {
      await store.delete(path);
    }
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
                  art: kDepositArt,
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
                const _SectionHeader('Mehrere Kassen'),
                ListTile(
                  key: const ValueKey('share-catalog'),
                  leading: const Icon(Icons.qr_code_2),
                  title: const Text('Sortiment teilen'),
                  subtitle: const Text('QR-Code für ein anderes Gerät anzeigen'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CatalogShareScreen()),
                  ),
                ),
                ListTile(
                  key: const ValueKey('import-catalog'),
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Sortiment übernehmen'),
                  subtitle: const Text('QR-Code eines anderen Geräts scannen'),
                  onTap: () => _importCatalog(context),
                ),
                const _SectionHeader('Darstellung'),
                const _ThemeModeSetting(),
                const _ShowImagesSetting(),
                const _SwipeTabsSetting(),
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

/// Wischen zwischen Speisen und Getränken erlauben oder sperren.
class _SwipeTabsSetting extends StatelessWidget {
  const _SwipeTabsSetting();

  @override
  Widget build(BuildContext context) {
    final swipe = context.select<AppearanceProvider, bool>((a) => a.swipeTabs);
    return SwitchListTile(
      key: const ValueKey('swipe-tabs'),
      secondary: const Icon(Icons.swipe),
      title: const Text('Wischen zwischen Speisen und Getränken'),
      subtitle: Text(swipe ? 'An' : 'Aus – Wechsel nur über die Reiter oben'),
      value: swipe,
      onChanged: context.read<AppearanceProvider>().setSwipeTabs,
    );
  }
}

enum _ImageChoice { gallery, camera, reset }

/// Bilder (gezeichnet oder eigenes Foto) oder Emojis auf den Kacheln.
class _ShowImagesSetting extends StatelessWidget {
  const _ShowImagesSetting();

  @override
  Widget build(BuildContext context) {
    final images = context.select<AppearanceProvider, bool>((a) => a.showImages);
    return SwitchListTile(
      key: const ValueKey('show-images'),
      secondary: const Icon(Icons.image_outlined),
      title: const Text('Bilder statt Emojis'),
      subtitle: Text(images ? 'Eigene Fotos oder gezeichnete Bilder' : 'Emojis wie bisher'),
      value: images,
      onChanged: context.read<AppearanceProvider>().setShowImages,
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
    if (!(delete ?? false) || !context.mounted) return;
    final store = context.read<ArticleImageStore>();
    catalog.removeCustom(article.id);
    await store.delete(article.imagePath);
  }

  /// Eigenes Foto aus Galerie oder Kamera, oder zurück zum Standardbild.
  Future<void> _chooseImage(BuildContext context) async {
    final catalog = context.read<CatalogProvider>();
    final store = context.read<ArticleImageStore>();
    final messenger = ScaffoldMessenger.of(context);
    final choice = await showModalBottomSheet<_ImageChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Bild für „${article.name}“',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Foto aus der Galerie'),
              onTap: () => Navigator.pop(context, _ImageChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () => Navigator.pop(context, _ImageChoice.camera),
            ),
            if (article.imagePath != null)
              ListTile(
                key: const ValueKey('image-reset'),
                leading: const Icon(Icons.restore),
                title: Text(article.custom ? 'Foto entfernen' : 'Standardbild verwenden'),
                onTap: () => Navigator.pop(context, _ImageChoice.reset),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final old = catalog.articleById(article.id).imagePath;
    if (choice == _ImageChoice.reset) {
      catalog.setImage(article.id, null);
      await store.delete(old);
      return;
    }
    try {
      final path = await store.pick(
        article.id,
        choice == _ImageChoice.camera ? ImageSource.camera : ImageSource.gallery,
      );
      if (path == null) return;
      catalog.setImage(article.id, path);
      await store.delete(old);
    } on Object catch (e) {
      // Keine Berechtigung, Speicher voll o. Ä.: Bild bleibt wie es war.
      final detail = e is PlatformException ? (e.message ?? e.code) : '$e';
      messenger.showSnackBar(
        SnackBar(content: Text('Foto konnte nicht übernommen werden ($detail).')),
      );
    }
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
          art: ArticleArt.of(article),
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
              ActionChip(
                key: ValueKey('image-${article.id}'),
                avatar: const Icon(Icons.image_outlined),
                label: const Text('Bild'),
                onPressed: () => _chooseImage(context),
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
  final ArticleArt art;
  final int initialCents;
  final ValueChanged<int> onChanged;

  /// Ausgegraut für ausgeblendete Artikel.
  final bool dimmed;

  const _PriceRow({
    super.key,
    required this.label,
    required this.art,
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
        leading: ArticleArtView(widget.art, size: 36),
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
