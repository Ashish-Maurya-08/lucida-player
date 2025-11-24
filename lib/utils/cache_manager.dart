import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CacheManager {
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500 MB

  static Future<void> cleanCache() async {
    final dir = await getApplicationCacheDirectory();
    final cacheDir = Directory('${dir.path}/tracks');

    if (!await cacheDir.exists()) return;

    final List<FileSystemEntity> files = cacheDir.listSync();
    int totalSize = 0;
    final List<File> audioFiles = [];

    for (var file in files) {
      if (file is File) {
        totalSize += await file.length();
        audioFiles.add(file);
      }
    }

    if (totalSize > _maxCacheSize) {
      // Sort by last modified (oldest first)
      audioFiles.sort((a, b) {
        return a.lastModifiedSync().compareTo(b.lastModifiedSync());
      });

      for (var file in audioFiles) {
        if (totalSize <= _maxCacheSize) break;
        final size = await file.length();
        await file.delete();
        totalSize -= size;
      }
    }
  }
}
