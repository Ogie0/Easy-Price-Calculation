import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/article.dart';
import '../providers/catalog_provider.dart';
import '../utils/money.dart';

/// Anpassung aller Artikelpreise und des Pfandwerts. Änderungen werden
/// sofort übernommen, sobald die Eingabe gültig ist.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const _SectionHeader('Pfand'),
                _PriceRow(
                  label: 'Pfandwert',
                  icon: Icons.recycling,
                  initialCents: catalog.depositCents,
                  onChanged: catalog.setDeposit,
                ),
                const _SectionHeader('Speisen'),
                for (final a in catalog.food) _articleRow(catalog, a),
                const _SectionHeader('Getränke'),
                for (final a in catalog.drinks) _articleRow(catalog, a),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _articleRow(CatalogProvider catalog, Article article) {
    return _PriceRow(
      key: ValueKey(article.id),
      label: article.hasVariants
          ? '${article.name} (${article.variants.join('/')})'
          : article.name,
      icon: article.category == ArticleCategory.food ? Icons.restaurant : Icons.local_bar,
      initialCents: article.priceCents,
      onChanged: (cents) => catalog.setPrice(article.id, cents),
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

class _PriceRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final int initialCents;
  final ValueChanged<int> onChanged;

  const _PriceRow({
    super.key,
    required this.label,
    required this.icon,
    required this.initialCents,
    required this.onChanged,
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
    _controller = TextEditingController(text: _toInput(widget.initialCents));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static final _allowedInput = RegExp(r'^\d{0,4}([.,]\d{0,2})?$');

  static String _toInput(int cents) =>
      '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')}';

  void _onChanged(String text) {
    final cents = parseCents(text);
    final error = cents == null ? 'Ungültiger Betrag' : null;
    if (error != _error) setState(() => _error = error);
    if (cents != null) widget.onChanged(cents);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.label),
      trailing: SizedBox(
        width: 120,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.right,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  _allowedInput.hasMatch(newValue.text) ? newValue : oldValue,
            ),
          ],
          decoration: InputDecoration(
            suffixText: '€',
            isDense: true,
            errorText: _error,
            border: const OutlineInputBorder(),
          ),
          onChanged: _onChanged,
        ),
      ),
    );
  }
}
