import 'dart:io';

class Utils {
  static void printUsage() {
    print('Usage: river_cli <command>\n'
        '\n'
        'Project:\n'
        '  init [options]               Scaffold reusable lib/ structure & packages\n'
        '  doctor                       Health-check the project, modules & deps\n'
        '  skill [--global|--print]     Install the Claude Code skill for AI workflows\n'
        '  generate routes              Rebuild routing from discovered features\n'
        '\n'
        'Generators (accept --path, --force, --dry-run):\n'
        '  create page:<name>           Feature page + go_router route\n'
        '  create screen:<name>         Feature page without a route\n'
        '  create feature:<name>        Full CRUD: model + repo + controller + view + route\n'
        '  create model:<name>          Data class (--fields "a:String, b:int?" or --json/--from-json)\n'
        '  create repository:<name>     Repository wired to the network layer\n'
        '  create widget:<name>         Reusable widget in the shared widgets folder\n'
        '  (model/feature also accept --with-test to emit a round-trip test)\n'
        '\n'
        'Maintenance:\n'
        '  remove feature:<name>        Delete a feature, its model/repo & route\n'
        '  remove page:<name>           Delete a page & its route\n'
        '\n'
        'Other:\n'
        '  version                      Print the CLI version\n'
        '  help                         Show this help\n'
        '\n'
        'Examples:\n'
        '  river_cli create model:todo --fields "title:String, done:bool, due:DateTime?"\n'
        '  river_cli create model:user --json \'{"id":1,"name":"Ada","roles":["admin"]}\'\n'
        '  river_cli create feature:product --fields "name:String, price:double" --with-test\n'
        '  river_cli generate routes\n'
        '  river_cli remove feature:product\n'
        '\n'
        'Run "river_cli init --help" for init options.');
  }

  /// Verifies a Flutter project root and adds the dependencies the `create`
  /// command relies on. (The `init` command manages its own packages.)
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

    final lines = content.split('\n');
    final depIndex = lines.indexWhere((line) => line.trim() == 'dependencies:');
    if (depIndex == -1) {
      print('Error: No dependencies section found in pubspec.yaml.');
      return;
    }

    for (var package in dependencies) {
      if (!lines.any((line) => line.trim().startsWith('$package:'))) {
        print('Adding $package to pubspec.yaml...');
        lines.insert(depIndex + 1, '  $package:');
        updated = true;
      }
    }

    if (updated) {
      pubspecFile.writeAsStringSync(lines.join('\n'));
      print(
          'Dependencies added to pubspec.yaml. Run "flutter pub get" to fetch dependencies.');
    } else {
      print('All dependencies are already present in pubspec.yaml.');
    }
  }

  /// Returns true if the `flutter` executable is available on PATH.
  static bool isFlutterAvailable() {
    try {
      final result = Process.runSync('flutter', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Reads the project name from `pubspec.yaml`, or null if absent.
  static String? readPackageName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return null;
    for (final line in pubspec.readAsLinesSync()) {
      final match = RegExp(r'^name:\s*(.+)$').firstMatch(line.trimRight());
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }

  /// Prompts the user with a yes/no question on stdin.
  static bool promptYesNo(String question, {bool defaultYes = true}) {
    final suffix = defaultYes ? '[Y/n]' : '[y/N]';
    stdout.write('$question $suffix ');
    final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
    if (input.isEmpty) return defaultYes;
    return input == 'y' || input == 'yes';
  }

  /// Adds the given runtime/dev packages to pubspec.yaml.
  ///
  /// When Flutter is on PATH and [runPubGet] is true, uses `flutter pub add`
  /// so pub resolves versions compatible with the project's SDK (and runs an
  /// implicit `pub get`). Otherwise inserts unversioned entries into the
  /// appropriate pubspec sections.
  static void addModulePackages(
    List<String> deps,
    List<String> devDeps, {
    required bool runPubGet,
  }) {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return;

    final existing = _existingTopLevelDeps(pubspec.readAsStringSync());
    final newDeps = deps.toSet().where((p) => !existing.contains(p)).toList()
      ..sort();
    final newDevDeps =
        devDeps.toSet().where((p) => !existing.contains(p)).toList()..sort();

    if (newDeps.isEmpty && newDevDeps.isEmpty) {
      print('All required packages are already present in pubspec.yaml.');
      return;
    }

    final flutterAvailable = isFlutterAvailable();

    if (runPubGet && flutterAvailable) {
      if (newDeps.isNotEmpty) {
        print('Adding packages: ${newDeps.join(', ')}');
        _runPubAdd(newDeps);
      }
      if (newDevDeps.isNotEmpty) {
        print('Adding dev packages: ${newDevDeps.join(', ')}');
        _runPubAdd(newDevDeps.map((d) => 'dev:$d').toList());
      }
      return;
    }

    _insertBareEntries(pubspec, newDeps, newDevDeps);
    if (!flutterAvailable) {
      print('Flutter not found on PATH — added unversioned entries to '
          'pubspec.yaml. Run "flutter pub get" to resolve versions.');
    } else {
      print('Added unversioned entries to pubspec.yaml (--no-pub-get set).');
    }
  }

  static void _runPubAdd(List<String> packageArgs) {
    final result = Process.runSync('flutter', ['pub', 'add', ...packageArgs]);
    if (result.stdout.toString().trim().isNotEmpty) {
      stdout.write(result.stdout);
    }
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      print('Warning: "flutter pub add ${packageArgs.join(' ')}" exited with '
          'code ${result.exitCode}.');
    }
  }

  /// Collects top-level package names already declared under `dependencies:`
  /// or `dev_dependencies:`.
  static Set<String> _existingTopLevelDeps(String content) {
    final deps = <String>{};
    var inDepsSection = false;

    for (final line in content.split('\n')) {
      final trimmedRight = line.trimRight();
      if (trimmedRight == 'dependencies:' ||
          trimmedRight == 'dev_dependencies:') {
        inDepsSection = true;
        continue;
      }
      if (!inDepsSection) continue;

      if (line.isNotEmpty && !line.startsWith(' ')) {
        inDepsSection = false;
        continue;
      }
      final match = RegExp(r'^  (\w[\w]*):').firstMatch(line);
      if (match != null) deps.add(match.group(1)!);
    }
    return deps;
  }

  static void _insertBareEntries(
    File pubspec,
    List<String> deps,
    List<String> devDeps,
  ) {
    var lines = pubspec.readAsStringSync().split('\n');

    if (deps.isNotEmpty) {
      lines = _insertUnderSection(lines, 'dependencies:', deps);
    }

    if (devDeps.isNotEmpty) {
      final hasDevSection =
          lines.any((l) => l.trimRight() == 'dev_dependencies:');
      if (hasDevSection) {
        lines = _insertUnderSection(lines, 'dev_dependencies:', devDeps);
      } else {
        lines
          ..add('')
          ..add('dev_dependencies:')
          ..addAll(devDeps.map((d) => '  $d:'));
      }
    }

    pubspec.writeAsStringSync(lines.join('\n'));
  }

  static List<String> _insertUnderSection(
    List<String> lines,
    String section,
    List<String> packages,
  ) {
    final index = lines.indexWhere((l) => l.trimRight() == section);
    if (index == -1) return lines;
    lines.insertAll(index + 1, packages.map((p) => '  $p:'));
    return lines;
  }
}
