import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Vídeos das séries ficam só no aparelho, numa pasta do app, e somem após [retention].
class LocalVideoStore {
  const LocalVideoStore({this.retention = const Duration(days: 7)});
  final Duration retention;

  Future<Directory> _dir() async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/execution_videos');
    return dir.create(recursive: true);
  }

  /// Move o vídeo temporário da câmera para a pasta do app.
  Future<String> keep(String tempPath) async {
    final dir = await _dir();
    final ext = tempPath.contains('.') ? tempPath.substring(tempPath.lastIndexOf('.')) : '.mp4';
    final target = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}$ext';
    try {
      return (await File(tempPath).rename(target)).path;
    } on FileSystemException {
      final copy = await File(tempPath).copy(target);
      await File(tempPath).delete();
      return copy.path;
    }
  }

  Future<void> purgeExpired() async {
    try {
      final limit = DateTime.now().subtract(retention);
      await for (final f in (await _dir()).list()) {
        if (f is File && (await f.lastModified()).isBefore(limit)) await f.delete();
      }
    } catch (e) {
      debugPrint('execution video purge failed: $e');
    }
  }
}

/// Aceite (uma vez) de que o vídeo fica no aparelho e só alguns quadros vão para a IA.
class ExecutionConsentStore {
  ExecutionConsentStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'execution_analysis_consent_v1';

  Future<bool> hasConsent() async => (await _storage.read(key: _key)) == 'true';

  Future<void> accept() => _storage.write(key: _key, value: 'true');
}
