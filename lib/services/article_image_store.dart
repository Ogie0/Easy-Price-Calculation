import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_storage.dart';

/// Eigene Fotos für Kacheln: aus Galerie oder Kamera, verkleinert und als
/// Kopie im App-Ordner abgelegt (bleibt auch, wenn das Original gelöscht
/// wird). Die Fotos verlassen das Gerät nicht.
class ArticleImageStore {
  final ImagePicker _picker;
  final AppStorage? _storage;

  ArticleImageStore({ImagePicker? picker, AppStorage? storage})
      : _picker = picker ?? ImagePicker(),
        _storage = storage;

  /// Pfad der gespeicherten Kopie oder null, wenn abgebrochen wurde.
  Future<String?> pick(String articleId, ImageSource source) async {
    // Merken, für welchen Artikel fotografiert wird: Beendet Android die App
    // währenddessen (wenig Speicher), holt [recoverLost] das Foto nach.
    await _storage?.savePendingImage(articleId);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      return picked == null ? null : await _saveCopy(picked, articleId);
    } finally {
      await _storage?.savePendingImage(null);
    }
  }

  /// Nach einem Neustart: Foto, das vor dem Beenden der App noch aufgenommen
  /// wurde, samt Artikel-ID. Nur Android kennt diesen Fall.
  Future<({String articleId, String path})?> recoverLost() async {
    final articleId = _storage?.loadPendingImage();
    if (articleId == null || !Platform.isAndroid) return null;
    try {
      final response = await _picker.retrieveLostData();
      final file = response.file;
      if (response.isEmpty || file == null) return null;
      return (articleId: articleId, path: await _saveCopy(file, articleId));
    } finally {
      await _storage?.savePendingImage(null);
    }
  }

  Future<String> _saveCopy(XFile picked, String articleId) async {
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
