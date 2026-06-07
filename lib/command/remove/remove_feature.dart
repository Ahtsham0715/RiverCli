import 'dart:io';

import '../../utils/naming.dart';
import '../../utils/project.dart';
import '../../utils/utils.dart';
import '../create/route_codegen.dart';

/// `river_cli remove <feature|page|screen>:<name>` — deletes a scaffolded
/// feature directory and unregisters its go_router route. For `feature:` it also
/// removes the generated model and repository unless `--keep-data` is passed.
///
/// Destructive: prompts for confirmation unless `--yes`. `--dry-run` previews.
void runRemove(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printHelp();
    return;
  }

  final target = args.firstWhere(
    (a) => a.contains(':') && !a.startsWith('-'),
    orElse: () => '',
  );
  if (target.isEmpty) {
    print('Error: missing target. '
        'Usage: river_cli remove <feature|page|screen>:<name>');
    return;
  }
  final kind = target.substring(0, target.indexOf(':')).trim();
  final rawName = target.substring(target.indexOf(':') + 1).trim();
  if (rawName.isEmpty) {
    print('Error: missing name. Usage: river_cli remove $kind:<name>');
    return;
  }

  const validKinds = {'feature', 'page', 'screen'};
  if (!validKinds.contains(kind)) {
    print('Error: cannot remove "$kind". Valid: feature, page, screen.');
    return;
  }

  if (!ProjectContext.isFlutterRoot) {
    print('Error: pubspec.yaml not found. Run inside a Flutter project root.');
    exit(1);
  }

  final yes = args.contains('--yes') || args.contains('-y');
  final dryRun = args.contains('--dry-run') || args.contains('-n');
  final keepData = args.contains('--keep-data');

  var path = 'lib/presentation';
  final pi = args.indexOf('--path');
  if (pi != -1 && pi + 1 < args.length) path = args[pi + 1];
  for (final a in args) {
    if (a.startsWith('--path=')) path = a.substring('--path='.length);
  }

  final snake = Naming.snake(rawName);
  final routeName = Naming.camel(rawName);
  final featureDir = '$path/$snake';

  // Collect the targets that actually exist.
  final targets = <String>[];
  if (Directory(featureDir).existsSync()) targets.add(featureDir);
  final modelFile = 'lib/data/models/${snake}_model.dart';
  final repoFile = 'lib/data/repositories/${snake}_repository.dart';
  if (kind == 'feature' && !keepData) {
    if (File(modelFile).existsSync()) targets.add(modelFile);
    if (File(repoFile).existsSync()) targets.add(repoFile);
  }

  final touchesRoute = kind != 'screen';

  if (targets.isEmpty && !touchesRoute) {
    print('Nothing to remove for "$rawName".');
    return;
  }

  print('This will remove:');
  for (final t in targets) {
    print('  - $t');
  }
  if (touchesRoute) print('  - route "$routeName" from lib/app/routes/');

  if (dryRun) {
    print('\n(dry-run) no files were changed.');
    return;
  }

  if (!yes && !Utils.promptYesNo('\nProceed?', defaultYes: false)) {
    print('Aborted.');
    return;
  }

  for (final t in targets) {
    final dir = Directory(t);
    final file = File(t);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    } else if (file.existsSync()) {
      file.deleteSync();
    }
    print('  x $t');
  }

  if (touchesRoute) _unregisterRoute(routeName, snake);

  print('\nRemoved "$rawName".');
}

void _unregisterRoute(String routeName, String snake) {
  final appRoutes = File('lib/app/routes/app_routes.dart');
  final routePage = File('lib/app/routes/route_page.dart');

  if (appRoutes.existsSync()) {
    final updated =
        removeRouteConstant(appRoutes.readAsStringSync(), routeName);
    appRoutes.writeAsStringSync(updated);
    print('  ~ lib/app/routes/app_routes.dart (-const $routeName)');
  }
  if (routePage.existsSync()) {
    final updated =
        removeRouteEntry(routePage.readAsStringSync(), routeName, snake);
    routePage.writeAsStringSync(updated);
    print('  ~ lib/app/routes/route_page.dart (-route $routeName)');
  }
}

void _printHelp() {
  print('''
Usage: river_cli remove <feature|page|screen>:<name> [options]

Deletes a scaffolded feature and unregisters its route.

Options:
      --path <dir>   Feature root (default lib/presentation)
      --keep-data    Keep the generated model & repository (feature only)
  -y, --yes          Skip the confirmation prompt
  -n, --dry-run      Show what would be removed without deleting
  -h, --help         Show this help

Examples:
  river_cli remove feature:product
  river_cli remove page:login --yes
  river_cli remove feature:order --keep-data''');
}
