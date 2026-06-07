import 'dart:io';

import '../../utils/field_spec.dart';

/// Parsed options common to every `create <kind>:<name>` generator.
class CreateOptions {
  /// The generator kind: `page`, `screen`, `model`, `repository`, `widget`,
  /// `feature` (empty if no `kind:name` token was supplied).
  final String kind;

  /// The target name as typed by the user (normalized per generator).
  final String name;

  /// Feature/page output root (`--path`), default `lib/presentation`.
  final String path;

  final bool force;
  final bool dryRun;

  /// Generate a matching round-trip test (`--with-test`).
  final bool withTest;

  /// Fields parsed from `--fields "a:String, b:int?"` (empty when absent).
  final List<FieldSpec> fields;

  /// Raw JSON sample (from `--json` or a `--from-json` file) used to infer a
  /// model, or null when not supplied.
  final String? jsonSample;

  const CreateOptions({
    required this.kind,
    required this.name,
    required this.path,
    required this.force,
    required this.dryRun,
    required this.withTest,
    required this.fields,
    required this.jsonSample,
  });

  bool get isValid => kind.isNotEmpty && name.isNotEmpty;

  /// Parses the args that follow the `create` command. Reads a `--from-json`
  /// file from disk if given (missing files are reported and ignored).
  factory CreateOptions.parse(List<String> args) {
    var kind = '';
    var name = '';
    var path = 'lib/presentation';
    var force = false;
    var dryRun = false;
    var withTest = false;
    String? fieldsRaw;
    String? jsonSample;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.contains(':') && !arg.startsWith('-') && kind.isEmpty) {
        final idx = arg.indexOf(':');
        kind = arg.substring(0, idx).trim();
        name = arg.substring(idx + 1).trim();
        continue;
      }
      switch (arg) {
        case '--path':
          if (i + 1 < args.length) path = args[++i];
          break;
        case '--fields':
          if (i + 1 < args.length) fieldsRaw = args[++i];
          break;
        case '--json':
          if (i + 1 < args.length) jsonSample = args[++i];
          break;
        case '--from-json':
          if (i + 1 < args.length) jsonSample = _readJsonFile(args[++i]);
          break;
        case '--with-test':
          withTest = true;
          break;
        case '--force':
        case '-f':
          force = true;
          break;
        case '--dry-run':
        case '-n':
          dryRun = true;
          break;
        default:
          if (arg.startsWith('--path=')) {
            path = arg.substring('--path='.length);
          } else if (arg.startsWith('--fields=')) {
            fieldsRaw = arg.substring('--fields='.length);
          } else if (arg.startsWith('--json=')) {
            jsonSample = arg.substring('--json='.length);
          } else if (arg.startsWith('--from-json=')) {
            jsonSample = _readJsonFile(arg.substring('--from-json='.length));
          }
          break;
      }
    }

    return CreateOptions(
      kind: kind,
      name: name,
      path: path,
      force: force,
      dryRun: dryRun,
      withTest: withTest,
      fields: parseFields(fieldsRaw),
      jsonSample: jsonSample,
    );
  }

  static String? _readJsonFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('Warning: --from-json file not found: $filePath');
      return null;
    }
    return file.readAsStringSync();
  }
}
