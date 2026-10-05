import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Eingabefeld für Euro-Beträge (max. 4 Stellen vor und 2 nach dem Komma).
class PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;
  final String? label;
  final bool autofocus;

  const PriceField({
    super.key,
    required this.controller,
    this.error,
    this.onChanged,
    this.label,
    this.autofocus = false,
  });

  static final _allowedInput = RegExp(r'^\d{0,4}([.,]\d{0,2})?$');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
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
