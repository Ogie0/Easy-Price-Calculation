import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/catalog_provider.dart';
import '../services/catalog_transfer.dart';

/// Zeigt das Sortiment dieses Geräts als QR-Code. Ein anderes Gerät scannt
/// ihn unter „Sortiment übernehmen“ – ohne Internet.
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
                  'Auf dem anderen Gerät: Einstellungen, dann „Sortiment übernehmen“ und diesen Code '
                  'scannen. Eigene Fotos werden nicht übertragen.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kamera-Scanner für den QR-Code eines anderen Geräts. Gibt das erkannte
/// Sortiment zurück.
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
                            'Android-Einstellungen der App die Kamera erlauben.'
                        : 'Kamera nicht verfügbar.',
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
