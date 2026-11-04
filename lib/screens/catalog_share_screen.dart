import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/catalog_provider.dart';
import '../services/article_image_store.dart';
import '../services/catalog_transfer.dart';
import '../services/qr_image_decoder.dart';
import '../utils/money.dart';

/// Zeigt das Sortiment dieses Geräts als QR-Code. Ein anderes Gerät scannt
/// ihn unter „Sortiment übernehmen“ oder liest ihn aus einem Screenshot –
/// ohne Internet.
class CatalogShareScreen extends StatelessWidget {
  const CatalogShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final code = CatalogTransfer(articles: catalog.all, depositCents: catalog.depositCents).encode();
    final tooBig = code.length > CatalogTransfer.maxLength;

    return Scaffold(
      appBar: AppBar(title: const Text('Sortiment teilen')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                if (tooBig)
                  const Text(
                    'Das Sortiment ist zu groß für einen QR-Code. Bitte einige eigene '
                    'Positionen kürzer benennen oder löschen.',
                    textAlign: TextAlign.center,
                  )
                else
                  // QR-Codes immer schwarz auf weiß, auch im Dunkelmodus.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      key: const ValueKey('catalog-qr'),
                      data: code,
                      errorCorrectionLevel: QrErrorCorrectLevel.L,
                      backgroundColor: Colors.white,
                      size: 320,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  '${catalog.all.length} Artikel, Pfand und Reihenfolge',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Auf dem anderen Gerät in den Einstellungen „Sortiment übernehmen“ wählen und '
                  'den Code scannen. Eigene Fotos werden nicht übertragen.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.screenshot_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tipp: Jetzt einen Screenshot machen. Aus dem Bild lässt sich das '
                            'Sortiment später jederzeit wiederherstellen, z. B. wenn ein Handy '
                            'zurückgesetzt wurde.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Source { liveCamera, photo, image }

/// Fragt, woher das Sortiment kommt (Kamera, Foto, Screenshot), und liest es
/// ein. null bei Abbruch oder wenn kein Sortiment-Code gefunden wurde (dann
/// mit Hinweis). In Tests austauschbar.
@visibleForTesting
Future<CatalogTransfer?> Function(BuildContext context) chooseCatalogSource = _chooseCatalogSource;

Future<CatalogTransfer?> _chooseCatalogSource(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final source = await showModalBottomSheet<_Source>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Sortiment übernehmen', style: Theme.of(context).textTheme.titleMedium),
          ),
          // Live-Scanner nur in der App; im Browser (iPhone) bräuchte er Internet.
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Mit der Kamera scannen'),
              onTap: () => Navigator.pop(context, _Source.liveCamera),
            )
          else
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('QR-Code fotografieren'),
              onTap: () => Navigator.pop(context, _Source.photo),
            ),
          ListTile(
            key: const ValueKey('import-from-image'),
            leading: const Icon(Icons.screenshot_outlined),
            title: const Text('Aus Screenshot oder Bild laden'),
            subtitle: const Text('z. B. ein gespeicherter Screenshot von „Sortiment teilen“'),
            onTap: () => Navigator.pop(context, _Source.image),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;
  if (source == _Source.liveCamera) {
    return navigator.push<CatalogTransfer>(
      MaterialPageRoute(builder: (_) => const CatalogScanScreen()),
    );
  }

  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: source == _Source.photo ? ImageSource.camera : ImageSource.gallery,
    );
  } on Object catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Bild konnte nicht geöffnet werden ($e).')));
    return null;
  }
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  // Kurz anzeigen, dass gelesen wird (große Bilder brauchen einen Moment).
  messenger.showSnackBar(const SnackBar(content: Text('QR-Code wird gelesen …')));
  await Future<void>.delayed(const Duration(milliseconds: 50));
  final text = await compute(decodeQrFromImage, bytes);
  messenger.hideCurrentSnackBar();
  final transfer = text == null ? null : CatalogTransfer.decode(text);
  if (transfer == null) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Im Bild wurde kein Sortiment-Code gefunden. Bitte einen Screenshot von '
          '„Sortiment teilen“ verwenden.',
        ),
      ),
    );
  }
  return transfer;
}

/// „Sortiment übernehmen“: Quelle wählen, nachfragen, übernehmen.
Future<void> importCatalog(BuildContext context) async {
  final catalog = context.read<CatalogProvider>();
  final store = context.read<ArticleImageStore>();
  final messenger = ScaffoldMessenger.of(context);
  final transfer = await chooseCatalogSource(context);
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

/// Kamera-Scanner (nur App) für den QR-Code eines anderen Geräts. Gibt das
/// erkannte Sortiment zurück.
class CatalogScanScreen extends StatefulWidget {
  const CatalogScanScreen({super.key});

  @override
  State<CatalogScanScreen> createState() => _CatalogScanScreenState();
}

class _CatalogScanScreenState extends State<CatalogScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;
  bool _wrongCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final transfer = CatalogTransfer.decode(barcode.rawValue ?? '');
      if (transfer != null) {
        _done = true;
        Navigator.of(context).pop(transfer);
        return;
      }
    }
    if (!_wrongCode) setState(() => _wrongCode = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sortiment übernehmen')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Ohne Kamerazugriff kann der Code nicht gescannt werden. Bitte in den '
                            'Android-Einstellungen der App die Kamera erlauben – oder den Code aus '
                            'einem Screenshot laden.'
                        : 'Kamera nicht verfügbar. Der Code lässt sich auch aus einem Screenshot laden.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _wrongCode
                  ? 'Das ist kein Sortiment-Code. Auf dem anderen Gerät „Sortiment teilen“ öffnen.'
                  : 'Kamera auf den QR-Code unter „Sortiment teilen“ des anderen Geräts richten.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
