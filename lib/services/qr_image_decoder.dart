import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

/// Liest einen QR-Code aus einem Bild (Screenshot, Foto, PNG/JPEG …).
/// Reines Dart: funktioniert auf Android und im Browser gleich und ohne
/// Internet. Liefert den Text des QR-Codes oder null, wenn keiner gefunden
/// wurde.
String? decodeQrFromImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  // Große Screenshots verkleinern: schneller, und der Code bleibt lesbar.
  const maxSide = 1600;
  var image = decoded;
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxSide) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? maxSide : null,
      height: image.height > image.width ? maxSide : null,
      interpolation: img.Interpolation.average,
    );
  }

  // In ARGB-Pixel umwandeln; Transparenz zählt als Weiß.
  final pixels = Int32List(image.width * image.height);
  var i = 0;
  for (final p in image) {
    final a = p.aNormalized;
    int ch(num v) => (v * a + 255 * (1 - a)).round().clamp(0, 255);
    pixels[i++] = 0xFF000000 | (ch(p.r) << 16) | (ch(p.g) << 8) | ch(p.b);
  }

  final source = RGBLuminanceSource(image.width, image.height, pixels);
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);
  for (final bitmap in [
    BinaryBitmap(HybridBinarizer(source)),
    BinaryBitmap(GlobalHistogramBinarizer(source)),
  ]) {
    try {
      return QRCodeReader().decode(bitmap, hints: hints).text;
    } on ReaderException {
      // Nächsten Versuch.
    }
  }
  return null;
}
