import 'dart:io';

class CreatePage {
  void createPageWithRoute(
      String pageName, String path, List<dynamic> arguments) {
    // final className = _capitalize(pageName);
    // final basePath = '$path/$pageName';
    final appFolder = 'lib/app';
    final routesPath = '$appFolder/routes';
    if (arguments[1].toString().startsWith('page:')) {
      // Ensure the app/routes folder and files exist
      _ensureRoutesSetup(routesPath);

      // Check if the route already exists
      if (_routeExists(pageName, routesPath)) {
        print(
            'Error: Route for "$pageName" already exists in the routing files.');
        return;
      }
    }

    // Proceed to create the page
    createPage(pageName, path, routesPath, arguments);
  }

  void _ensureRoutesSetup(String routesPath) {
    final appRoutesFile = File('$routesPath/app_routes.dart');
    final routePageFile = File('$routesPath/route_page.dart');

    if (!Directory(routesPath).existsSync()) {
      Directory(routesPath).createSync(recursive: true);
      print('Created routes directory: $routesPath');
    }

    if (!appRoutesFile.existsSync()) {
      appRoutesFile.writeAsStringSync('''
class AppRoutes {
  static const String home = '/';
}
''');
      print('Created app_routes.dart');
    }

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
      builder: (context, state) => const Placeholder(), // Default home page
    ),
  ],
);
''');
      print('Created route_page.dart');
    }
  }

  bool _routeExists(String pageName, String routesPath) {
    final appRoutesFile = File('$routesPath/app_routes.dart');
    final routePageFile = File('$routesPath/route_page.dart');

    // Check if the route constant or route is already present
    final appRoutesContent = appRoutesFile.readAsStringSync();
    final routePageContent = routePageFile.readAsStringSync();

    return appRoutesContent.contains('static const String $pageName') ||
        routePageContent.contains('name: AppRoutes.$pageName');
  }

  void createPage(String pageName, String path, String routesPath,
      List<dynamic> arguments) {
    final className = _capitalize(pageName);
    final basePath = '$path/$pageName';

    print('Creating page: $pageName at path: $basePath');

    // Define folder structure
    final folders = [
      basePath,
      '$basePath/controllers',
      '$basePath/views',
      '$basePath/bindings',
    ];

    // Define initial files to generate
    final files = {
      '$basePath/controllers/${pageName}_controller.dart': '''
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ${className}Controller extends StateNotifier<int> {
  ${className}Controller() : super(0){
  onInit();
  }

  void onInit() {
    // Perform initialization logic here
    print('Controller initialized');
  }

  // Increment the counter
  void increment() => state++;
  // Decrement the counter
  void decrement() {
    if (state > 0) state--;
  }
}
''',
      '$basePath/views/${pageName}_view.dart': '''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bindings/${pageName}_binding.dart';

class ${className}View extends StatelessWidget {
  const ${className}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$className View')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Counter display
            Consumer(
              builder: (context, ref, _) {
                final counter = ref.watch(${pageName}ControllerProvider);
                return Text(
                  'Counter: \$counter',
                  style: Theme.of(context).textTheme.headline4,
                );
              },
            ),
            const SizedBox(height: 16),
            // Buttons to update the counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final controller = ref.read(${pageName}ControllerProvider.notifier);
                    return ElevatedButton(
                      onPressed: controller.decrement,
                      child: const Text('-'),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final controller = ref.read(${pageName}ControllerProvider.notifier);
                    return ElevatedButton(
                      onPressed: controller.increment,
                      child: const Text('+'),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
''',
      '$basePath/bindings/${pageName}_binding.dart': '''
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/${pageName}_controller.dart';

/// StateNotifierProvider for $className
final ${pageName}ControllerProvider =
    StateNotifierProvider<${className}Controller, int>((ref) {
  return ${className}Controller();
});
''',
    };

    // Ensure folders are created
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
      file.writeAsStringSync(content); // Overwrite with new content
      print('Created or updated file: $path');
    });
    if (arguments[1].toString().startsWith('page:')) {
      // Update routing files
      _updateRoutingFiles(pageName, routesPath, arguments);
    }

    print('Page "$pageName" created successfully at "$basePath"!');
  }

  void _updateRoutingFiles(
      String pageName, String routesPath, List<dynamic> arguments) {
    final appRoutesFile = File('$routesPath/app_routes.dart');
    final routePageFile = File('$routesPath/route_page.dart');
    final className = _capitalize(pageName);

    // Update app_routes.dart
    final appRoutesContent = appRoutesFile.readAsStringSync();
    final updatedAppRoutes = appRoutesContent.replaceFirst(
      '}',
      '  static const String $pageName = \'/$pageName\';\n}',
    );
    appRoutesFile.writeAsStringSync(updatedAppRoutes);
    print('Updated app_routes.dart with $pageName route.');
    String pathName = "presentation";
    if (arguments.length > 3) {
      pathName = arguments[3].split('/').last;
    }
    // Update route_page.dart
    final pageImport =
        "import '../../$pathName/$pageName/views/${pageName}_view.dart';";
    final routeDefinition = '''
    GoRoute(
      name: AppRoutes.$pageName,
      path: AppRoutes.$pageName,
      builder: (context, state) => const ${className}View(),
    ),
''';

    final routePageContent = routePageFile.readAsStringSync();
    final updatedRoutePage = routePageContent
        .replaceFirst(
          '\nfinal GoRouter router = GoRouter(',
          '\n$pageImport\n\nfinal GoRouter router = GoRouter(',
        )
        .replaceFirst(
          'routes: [',
          'routes: [\n$routeDefinition',
        );
    routePageFile.writeAsStringSync(updatedRoutePage);
    print('Updated route_page.dart with $pageName route.');
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}
