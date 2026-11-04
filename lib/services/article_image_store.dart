import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_storage.dart';

/// Eigene Fotos für Kacheln: aus Galerie oder Kamera, verkleinert und als
/// Kopie gespeichert (bleibt auch, wenn das Original gelöscht wird) – in der
/// App als Datei im App-Ordner, im Browser (iPhone) im Speicher des Browsers.
/// Die Fotos verlassen das Gerät nicht.
class ArticleImageStore {
  /// Kennzeichnet Fotos im Browser-Speicher (statt eines Dateipfads).
  static const _webPrefix = 'web:';

  final ImagePicker _picker;
  final AppStorage? _storage;
  final Map<String, Uint8List> _webPhotos = {};

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
      if (picked == null) return null;
      return kIsWeb ? await _saveInBrowser(picked, articleId) : await _saveCopy(picked, articleId);
    } finally {
      await _storage?.savePendingImage(null);
    }
  }

  /// Nach einem Neustart: Foto, das vor dem Beenden der App noch aufgenommen
  /// wurde, samt Artikel-ID. Nur Android kennt diesen Fall.
  Future<({String articleId, String path})?> recoverLost() async {
    if (kIsWeb) return null;
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

  /// Bild zu einem gespeicherten Foto, oder null, wenn es fehlt.
  ImageProvider? imageFor(String path) {
    if (path.startsWith(_webPrefix)) {
      final key = path.substring(_webPrefix.length);
      final bytes = _webPhotos[key] ?? _loadFromBrowser(key);
      if (bytes == null) return null;
      _webPhotos[key] = bytes;
      return MemoryImage(bytes);
    }
    return kIsWeb ? null : FileImage(File(path));
  }

  Uint8List? _loadFromBrowser(String key) {
    final data = _storage?.loadPhoto(key);
    if (data == null) return null;
    try {
      return base64Decode(data);
    } on FormatException {
      return null;
    }
  }

  Future<String> _saveInBrowser(XFile picked, String articleId) async {
    final storage = _storage;
    if (storage == null) throw StateError('Kein Speicher verfügbar');
    final bytes = await picked.readAsBytes();
    final key = '${articleId}_${DateTime.now().millisecondsSinceEpoch}';
    await storage.savePhoto(key, base64Encode(bytes));
    _webPhotos[key] = bytes;
    return '$_webPrefix$key';
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
    if (path.startsWith(_webPrefix)) {
      final key = path.substring(_webPrefix.length);
      _webPhotos.remove(key);
      await _storage?.deletePhoto(key);
      return;
    }
    if (kIsWeb) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Schon weg.
    }
  }
}
