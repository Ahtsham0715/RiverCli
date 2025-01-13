import 'dart:io';

import '../../static/files_json.dart';
import '../../static/folders_json.dart';

void createInitialStructure() {
  // Create folders
  for (var folder in folders) {
    final dir = Directory(folder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      print('Created folder: $folder');
    }
  }

  // Create or overwrite files
  files.forEach((path, content) {
    final file = File(path);
    file.writeAsStringSync(content); // Always overwrite with the latest content
    print('Created or updated file: $path');
  });
}
