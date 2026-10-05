import 'package:flutter/material.dart';

/// Master-Passwort für die Einstellungen. Es schützt vor versehentlichen
/// Änderungen an der Kasse, ist aber keine echte Sicherung: Der Quellcode
/// (und damit das Passwort) ist im Repository einsehbar.
const String kMasterPassword = '1960';

/// Fragt das Master-Passwort ab. Liefert true, wenn es stimmt.
Future<bool> askMasterPassword(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => const _PasswordDialog(),
  );
  return ok ?? false;
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == kMasterPassword) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _error = 'Falsches Passwort');
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Einstellungen'),
      content: TextField(
        key: const ValueKey('master-password'),
        controller: _controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Master-Passwort',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        FilledButton(onPressed: _submit, child: const Text('Öffnen')),
      ],
    );
  }
}
