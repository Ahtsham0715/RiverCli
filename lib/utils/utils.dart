import 'dart:io';

class Utils {
  static void printUsage() {
    print('Usage: riverpod_cli create page:<page_name> --path <path>');
  }

  static void ensureDependencies() {
    final pubspecFile = File('pubspec.yaml');

    if (!pubspecFile.existsSync()) {
      print(
          'Error: pubspec.yaml not found. Please run this script in the root of a Flutter project.');
      exit(1);
    }

    final dependencies = [
      'flutter_riverpod',
      'go_router',
      'riverpod',
      'sizer',
      'intl',
    ];

    final content = pubspecFile.readAsStringSync();
    var updated = false;

    // Find the dependencies section
    final lines = content.split('\n');
    final depIndex = lines.indexWhere((line) => line.trim() == 'dependencies:');
    if (depIndex == -1) {
      print('Error: No dependencies section found in pubspec.yaml.');
      return;
    }

    // Add each missing dependency
    for (var package in dependencies) {
      if (!lines.any((line) => line.trim().startsWith('$package:'))) {
        print('Adding $package to pubspec.yaml...');
        lines.insert(depIndex + 1, '  $package:');
        updated = true;
      }
    }

    if (updated) {
      // Write back updated content to pubspec.yaml
      pubspecFile.writeAsStringSync(lines.join('\n'));
      print(
          'Dependencies added to pubspec.yaml. Run "flutter pub get" to fetch dependencies.');
    } else {
      print('All dependencies are already present in pubspec.yaml.');
    }
  }
}
