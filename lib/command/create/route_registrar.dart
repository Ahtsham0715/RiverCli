import 'dart:io';

import '../../utils/naming.dart';
import '../../utils/project.dart';

/// Registers a go_router route for a generated view in `lib/app/routes/`,
/// creating the routing files if they are missing. Uses a package import for
/// the view so it works regardless of the feature's `--path`.
///
/// Returns `false` (and prints a notice) when a route for [name] already exists.
class RouteRegistrar {
  static const String routesPath = 'lib/app/routes';

  /// Registers the route for [name] whose view lives under [viewDir]
  /// (e.g. `lib/presentation/todo`). No-op in [dryRun].
  static bool register(
    String name, {
    required String viewDir,
    required ProjectContext ctx,
    bool dryRun = false,
  }) {
    final routeName = Naming.camel(name);
    final className = '${Naming.pascal(name)}View';
    final snake = Naming.snake(name);

    _ensureSetup(dryRun: dryRun);

    final appRoutesFile = File('$routesPath/app_routes.dart');
    final routePageFile = File('$routesPath/route_page.dart');

    if (appRoutesFile.existsSync()) {
      final existing = appRoutesFile.readAsStringSync();
      if (existing.contains('static const String $routeName ') ||
          existing.contains('static const String $routeName=')) {
        print(
            '  Route "$routeName" already registered — skipping route update.');
        return false;
      }
    }

    if (dryRun) {
      print('  ~ $routesPath/app_routes.dart (dry-run, +route $routeName)');
      print('  ~ $routesPath/route_page.dart (dry-run, +route $routeName)');
      return true;
    }

    // app_routes.dart: add the path constant.
    final appRoutes = appRoutesFile.readAsStringSync();
    appRoutesFile.writeAsStringSync(appRoutes.replaceFirst(
      RegExp(r'\}\s*$'),
      "  static const String $routeName = '/$routeName';\n}\n",
    ));

    // route_page.dart: add the import and the GoRoute entry.
    final pkg = ctx.packageName ?? 'app';
    // viewDir is like `lib/presentation/todo`; strip the leading `lib/`.
    final importPath = viewDir.replaceFirst(RegExp(r'^lib/'), '');
    final viewImport =
        "import 'package:$pkg/$importPath/views/${snake}_view.dart';";
    final route = '''
    GoRoute(
      name: AppRoutes.$routeName,
      path: AppRoutes.$routeName,
      builder: (context, state) => const $className(),
    ),
''';

    var routePage = routePageFile.readAsStringSync();
    if (!routePage.contains(viewImport)) {
      routePage = routePage.replaceFirst(
        RegExp(r'\nfinal GoRouter router = GoRouter\('),
        '\n$viewImport\n\nfinal GoRouter router = GoRouter(',
      );
    }
    routePage = routePage.replaceFirst('routes: [', 'routes: [\n$route');
    routePageFile.writeAsStringSync(routePage);

    print('  ~ $routesPath/app_routes.dart (+route $routeName)');
    print('  ~ $routesPath/route_page.dart (+route $routeName)');
    return true;
  }

  static void _ensureSetup({required bool dryRun}) {
    if (dryRun) return;
    final dir = Directory(routesPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final appRoutesFile = File('$routesPath/app_routes.dart');
    if (!appRoutesFile.existsSync()) {
      appRoutesFile.writeAsStringSync('''
class AppRoutes {
  static const String home = '/';
}
''');
    }

    final routePageFile = File('$routesPath/route_page.dart');
    if (!routePageFile.existsSync()) {
      routePageFile.writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      name: AppRoutes.home,
      path: AppRoutes.home,
      builder: (context, state) => const Placeholder(),
    ),
  ],
);
''');
    }
  }
}
