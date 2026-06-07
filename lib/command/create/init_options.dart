import '../../static/modules/modules.dart';

/// Parsed options for the `river_cli init` command.
///
/// Module selection precedence (highest first): `--minimal`, `--all`,
/// `--modules a,b`. If none of those are given and `--yes` is set, all optional
/// modules are selected. Otherwise the caller runs interactive prompts.
class InitOptions {
  final bool all;
  final bool minimal;
  final List<String> modules;
  final bool yes;
  final bool runPubGet;
  final bool force;
  final bool list;
  final bool help;

  /// Flag tokens that were not recognized (reported, non-fatal).
  final List<String> unknownFlags;

  const InitOptions({
    this.all = false,
    this.minimal = false,
    this.modules = const [],
    this.yes = false,
    this.runPubGet = true,
    this.force = false,
    this.list = false,
    this.help = false,
    this.unknownFlags = const [],
  });

  /// True when no explicit selector was given and prompts should be shown.
  bool get wantsInteractive => !minimal && !all && modules.isEmpty && !yes;

  /// Resolves the explicit selection, or `null` to signal "ask interactively".
  /// Returned keys are the *optional* module keys (core is always added later).
  List<String>? explicitSelection() {
    if (minimal) return const [];
    if (all) return kModules.keys.toList();
    if (modules.isNotEmpty) return modules;
    if (yes) return kModules.keys.toList();
    return null;
  }

  /// Parses the args that follow the `init` command.
  factory InitOptions.parse(List<String> args) {
    var all = false;
    var minimal = false;
    var yes = false;
    var runPubGet = true;
    var force = false;
    var list = false;
    var help = false;
    final modules = <String>[];
    final unknown = <String>[];

    void addModulesFromValue(String value) {
      for (final part in value.split(',')) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) modules.add(trimmed);
      }
    }

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--all':
        case '-a':
          all = true;
          break;
        case '--minimal':
          minimal = true;
          break;
        case '--yes':
        case '-y':
          yes = true;
          break;
        case '--no-pub-get':
          runPubGet = false;
          break;
        case '--force':
        case '-f':
          force = true;
          break;
        case '--list':
        case '-l':
          list = true;
          break;
        case '--help':
        case '-h':
          help = true;
          break;
        case '--modules':
        case '-m':
          if (i + 1 < args.length) {
            addModulesFromValue(args[++i]);
          }
          break;
        default:
          if (arg.startsWith('--modules=')) {
            addModulesFromValue(arg.substring('--modules='.length));
          } else if (arg.startsWith('-')) {
            unknown.add(arg);
          }
          break;
      }
    }

    return InitOptions(
      all: all,
      minimal: minimal,
      modules: modules,
      yes: yes,
      runPubGet: runPubGet,
      force: force,
      list: list,
      help: help,
      unknownFlags: unknown,
    );
  }
}
