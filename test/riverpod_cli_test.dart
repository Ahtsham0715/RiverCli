import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Riverpod CLI', () {
    const featureName = 'testFeature';
    final basePath = 'lib/presentation/$featureName';
    final folders = [
      '$basePath/providers',
      '$basePath/models',
      '$basePath/views',
    ];
    final files = {
      '$basePath/providers/${featureName}_provider.dart': 'Provider',
      '$basePath/models/${featureName}_model.dart': 'Model',
      '$basePath/views/${featureName}_view.dart': 'View',
    };

    tearDown(() {
      // Clean up generated files and folders after each test
      if (Directory('lib').existsSync()) {
        Directory('lib').deleteSync(recursive: true);
      }
    });

    test('Creates folders correctly', () {
      // Execute the script
      Process.runSync(
        'dart',
        ['run', 'bin/riverpod_cli.dart', featureName],
      );

      // Verify folders
      for (final folder in folders) {
        expect(Directory(folder).existsSync(), isTrue,
            reason: 'Expected folder $folder to exist.');
      }
    });

    test('Creates files with correct content', () {
      // Execute the script
      Process.runSync(
        'dart',
        ['run', 'bin/riverpod_cli.dart', featureName],
      );

      // Verify files
      files.forEach((path, expectedContent) {
        final file = File(path);
        expect(file.existsSync(), isTrue,
            reason: 'Expected file $path to exist.');
        expect(file.readAsStringSync(), contains(expectedContent),
            reason: 'Expected file $path to contain "$expectedContent".');
      });
    });
  });
}
