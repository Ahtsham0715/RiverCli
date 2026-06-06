import 'dart:io';

/// Inspects the current Flutter project so generators can adapt their output to
/// the modules that are actually installed (e.g. use the widget library and
/// design tokens only when those modules exist).
class ProjectContext {
  final String? packageName;
  final bool hasConfig;
  final bool hasUtils;
  final bool hasExtensions;
  final bool hasWidgets;
  final bool hasNetwork;
  final bool hasStorage;

  const ProjectContext({
    this.packageName,
    this.hasConfig = false,
    this.hasUtils = false,
    this.hasExtensions = false,
    this.hasWidgets = false,
    this.hasNetwork = false,
    this.hasStorage = false,
  });

  /// Detects installed modules by the presence of their canonical folders.
  factory ProjectContext.detect() {
    bool dir(String p) => Directory(p).existsSync();
    return ProjectContext(
      packageName: _readPackageName(),
      hasConfig: dir('lib/app/config'),
      hasUtils: dir('lib/app/utils'),
      hasExtensions: dir('lib/app/extensions'),
      hasWidgets: dir('lib/app/shared_widgets'),
      hasNetwork: dir('lib/data/provider/network'),
      hasStorage: dir('lib/data/provider/local_storage'),
    );
  }

  /// True if a `pubspec.yaml` is present in the working directory.
  static bool get isFlutterRoot => File('pubspec.yaml').existsSync();

  /// Finds scaffolded features (folders containing a `views/` subfolder) under
  /// the common feature roots. Returns paths relative to the project root.
  static List<String> findFeatures() {
    final roots = ['lib/presentation', 'lib/features'];
    final features = <String>[];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync()) {
        if (entity is Directory &&
            Directory('${entity.path}/views').existsSync()) {
          features.add(entity.path);
        }
      }
    }
    features.sort();
    return features;
  }

  static String? _readPackageName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return null;
    for (final line in pubspec.readAsLinesSync()) {
      final match = RegExp(r'^name:\s*(.+)$').firstMatch(line.trimRight());
      if (match != null) return match.group(1)!.trim();
    }
    return null;
  }
}

/// Outcome of attempting to write a single file.
enum WriteResult { created, overwritten, skipped, wouldCreate, wouldOverwrite }

/// Centralizes file writing for the generators: respects `--force` (overwrite)
/// and `--dry-run` (report only), and accumulates a summary it can print at the
/// end so every command reports its work the same way.
class FileWriter {
  final bool force;
  final bool dryRun;
  final _created = <String>[];
  final _overwritten = <String>[];
  final _skipped = <String>[];

  FileWriter({this.force = false, this.dryRun = false});

  /// Creates [path]'s parent directory if needed (no-op in dry-run).
  void ensureDir(String path) {
    if (dryRun) return;
    Directory(path).createSync(recursive: true);
  }

  /// Writes [content] to [path] honoring force/dry-run, records the outcome,
  /// prints a per-file line, and returns what happened.
  WriteResult write(String path, String content) {
    final file = File(path);
    final exists = file.existsSync();

    if (exists && !force) {
      _skipped.add(path);
      print('  = $path (exists, use --force to overwrite)');
      return WriteResult.skipped;
    }

    if (dryRun) {
      final result =
          exists ? WriteResult.wouldOverwrite : WriteResult.wouldCreate;
      (exists ? _overwritten : _created).add(path);
      print('  ${exists ? '~' : '+'} $path (dry-run)');
      return result;
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
        content.startsWith('\n') ? content.substring(1) : content);
    (exists ? _overwritten : _created).add(path);
    print('  ${exists ? '~' : '+'} $path');
    return exists ? WriteResult.overwritten : WriteResult.created;
  }

  bool get wroteNothing => _created.isEmpty && _overwritten.isEmpty;

  /// Prints a compact summary of everything written.
  void printSummary() {
    final verb = dryRun ? 'would be created' : 'created';
    print('\n${_created.length} file(s) $verb'
        '${_overwritten.isNotEmpty ? ', ${_overwritten.length} overwritten' : ''}'
        '${_skipped.isNotEmpty ? ', ${_skipped.length} skipped' : ''}.');
  }
}
