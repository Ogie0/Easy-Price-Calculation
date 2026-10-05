import 'package:flutter/material.dart';

import '../utils/money.dart';
import 'price_field.dart';

/// Ergebnis des Dialogs: Bezeichnung und Betrag in Cent (negativ bei Abzug).
typedef FreeAmount = ({String label, int cents});

/// Fragt einen frei gestalteten Betrag ab, z. B. Spende, Los oder Sonderpreis.
Future<FreeAmount?> askFreeAmount(BuildContext context) =>
    showDialog<FreeAmount>(context: context, builder: (_) => const _FreeAmountDialog());

class _FreeAmountDialog extends StatefulWidget {
  const _FreeAmountDialog();

  @override
  State<_FreeAmountDialog> createState() => _FreeAmountDialogState();
}

class _FreeAmountDialogState extends State<_FreeAmountDialog> {
  final _label = TextEditingController();
  final _amount = TextEditingController();
  var _deduction = false;
  String? _amountError;

  @override
  void dispose() {
    _label.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final cents = parseCents(_amount.text);
    if (cents == null || cents == 0) {
      setState(() => _amountError = 'Bitte einen Betrag eingeben');
      return;
    }
    final label = _label.text.trim();
    Navigator.pop<FreeAmount>(context, (
      label: label.isNotEmpty ? label : (_deduction ? 'Abzug' : 'Freier Betrag'),
      cents: _deduction ? -cents : cents,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Freier Betrag'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PriceField(
              key: const ValueKey('free-amount'),
              controller: _amount,
              label: 'Betrag',
              error: _amountError,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('free-label'),
              controller: _label,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Bezeichnung (optional)',
                hintText: 'z. B. Spende, Los, Sonderpreis',
                border: OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Als Abzug (minus)'),
              subtitle: const Text('z. B. Rabatt oder Gutschein'),
              value: _deduction,
              onChanged: (v) => setState(() => _deduction = v),
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
