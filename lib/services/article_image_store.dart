import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Eigene Fotos für Kacheln: aus Galerie oder Kamera, verkleinert und als
/// Kopie im App-Ordner abgelegt (bleibt auch, wenn das Original gelöscht
/// wird). Die Fotos verlassen das Gerät nicht.
class ArticleImageStore {
  final ImagePicker _picker;

  ArticleImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Pfad der gespeicherten Kopie oder null, wenn abgebrochen wurde.
  Future<String?> pick(String articleId, ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/article_images');
    await dir.create(recursive: true);
    final dot = picked.name.lastIndexOf('.');
    final ext = dot == -1 ? '.jpg' : picked.name.substring(dot);
    final target = '${dir.path}/${articleId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await picked.saveTo(target);
    return target;
  }

  /// Löscht ein nicht mehr benötigtes Foto. Fehler sind egal.
  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Schon weg.
    }
  }
}
