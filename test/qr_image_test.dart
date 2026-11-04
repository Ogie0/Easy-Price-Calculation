import 'dart:typed_data';

import 'package:easy_price_calculation/models/default_articles.dart';
import 'package:easy_price_calculation/services/catalog_transfer.dart';
import 'package:easy_price_calculation/services/qr_image_decoder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Zeichnet einen QR-Code wie auf dem Bildschirm, mitten in einen
/// "Screenshot" mit anderem Inhalt drumherum.
Uint8List screenshotWithQr(String data, {int module = 6, bool jpeg = false}) {
  final qr = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L));
  final size = qr.moduleCount * module;
  final shot = img.Image(width: 1179, height: 2556);
  img.fill(shot, color: img.ColorRgb8(240, 245, 240));
  img.fillRect(shot, x1: 0, y1: 0, x2: 1178, y2: 300, color: img.ColorRgb8(2, 111, 64));
  final left = (1179 - size) ~/ 2, top = 700;
  img.fillRect(shot, x1: left - 40, y1: top - 40, x2: left + size + 40, y2: top + size + 40,
      color: img.ColorRgb8(255, 255, 255));
  for (var y = 0; y < qr.moduleCount; y++) {
    for (var x = 0; x < qr.moduleCount; x++) {
      if (qr.isDark(y, x)) {
        img.fillRect(shot,
            x1: left + x * module, y1: top + y * module,
            x2: left + (x + 1) * module - 1, y2: top + (y + 1) * module - 1,
            color: img.ColorRgb8(0, 0, 0));
      }
    }
  }
  return jpeg ? img.encodeJpg(shot, quality: 80) : img.encodePng(shot);
}

void main() {
  final code = const CatalogTransfer(articles: kDefaultArticles, depositCents: 200).encode();

  test('Sortiment-Code aus einem Screenshot (PNG) lesen', () {
    final text = decodeQrFromImage(screenshotWithQr(code));
    expect(text, code);
    expect(CatalogTransfer.decode(text!)!.articles.length, kDefaultArticles.length);
  });

  test('auch aus einem komprimierten Foto (JPEG)', () {
    expect(decodeQrFromImage(screenshotWithQr(code, module: 9, jpeg: true)), code);
  });

  test('ohne QR-Code oder kein Bild: null', () {
    final plain = img.encodePng(img.Image(width: 300, height: 300));
    expect(decodeQrFromImage(plain), isNull);
    expect(decodeQrFromImage(Uint8List.fromList([1, 2, 3])), isNull);
  });
}
