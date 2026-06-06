import 'dart:io';

import '../../utils/naming.dart';
import '../../utils/project.dart';
import '../create/route_codegen.dart';

/// `river_cli generate routes` — discovers every scaffolded feature and
/// regenerates `lib/app/routes/app_routes.dart` and `route_page.dart` from
/// scratch, so the route table always matches what is on disk.
///
/// This OVERWRITES the routing files. Custom guards/redirects/nested routes are
/// not preserved — use it as a repair/sync command. `--dry-run` previews only.
void runGenerateRoutes(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    print('Usage: river_cli generate routes [--dry-run]\n\n'
        'Regenerates lib/app/routes/ from the features found under '
        'lib/presentation and lib/features.\n'
        'WARNING: overwrites the routing files (no custom guards preserved).');
    return;
  }

  if (!ProjectContext.isFlutterRoot) {
    print('Error: pubspec.yaml not found. Run inside a Flutter project root.');
    exit(1);
  }

  final dryRun = args.contains('--dry-run') || args.contains('-n');
  final ctx = ProjectContext.detect();
  final pkg = ctx.packageName ?? 'app';

  final routes = featureRoutes(ProjectContext.findFeatures(), pkg);

  print('Found ${routes.length} feature route(s)'
      '${routes.isEmpty ? '' : ': ${routes.map((r) => r.routeName).join(', ')}'}');

  final appRoutes = buildAppRoutesFile(routes);
  final routePage = buildRoutePageFile(routes, pkg);

  const dir = 'lib/app/routes';
  if (dryRun) {
    print('\n--- $dir/app_routes.dart (dry-run) ---');
    print(appRoutes);
    print('--- $dir/route_page.dart (dry-run) ---');
    print(routePage);
    return;
  }

  Directory(dir).createSync(recursive: true);
  File('$dir/app_routes.dart').writeAsStringSync(appRoutes);
  File('$dir/route_page.dart').writeAsStringSync(routePage);

  print('\n  ~ $dir/app_routes.dart');
  print('  ~ $dir/route_page.dart');
  print('\nRoutes regenerated.');
}

/// Maps discovered feature directories (e.g. `lib/presentation/product`) to
/// [FeatureRoute]s using the project's package name for view imports.
List<FeatureRoute> featureRoutes(List<String> featureDirs, String pkg) {
  final routes = <FeatureRoute>[];
  for (final dir in featureDirs) {
    final base = dir.split('/').last;
    final snake = Naming.snake(base);
    final underLib = dir.replaceFirst(RegExp(r'^lib/'), '');
    routes.add(FeatureRoute(
      routeName: Naming.camel(base),
      className: '${Naming.pascal(base)}View',
      importPath: 'package:$pkg/$underLib/views/${snake}_view.dart',
    ));
  }
  return routes;
}
