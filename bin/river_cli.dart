import 'package:river_cli/command/create/create_page.dart';
import 'package:river_cli/command/create/project_init.dart';
import 'package:river_cli/utils/utils.dart';

void main(List<String> arguments) {
  print('Arguments received: $arguments');

  if (arguments.isEmpty) {
    Utils.printUsage();
    return;
  }

  final command = arguments[0];

  if (command == 'create') {
    final pageArgument = arguments.firstWhere(
      (arg) => arg.startsWith('page:') || arg.startsWith('screen:'),
      orElse: () => '',
    );

    if (pageArgument.isEmpty) {
      print(
          'Error: Missing page command. Usage: riverpod_cli create page:<page_name> --path <path>');
      return;
    }

    final pageName = pageArgument.split(':')[1];
    if (pageName.isEmpty) {
      print(
          'Error: Page name is missing. Usage: riverpod_cli create page:<page_name> --path <path>');
      return;
    }

    // Check for optional --path argument
    String path = 'lib/presentation';
    final pathIndex = arguments.indexOf('--path');
    if (pathIndex != -1 && arguments.length > pathIndex + 1) {
      path = arguments[pathIndex + 1];
    }
    Utils.ensureDependencies();
    CreatePage createPage = CreatePage();
    createPage.createPageWithRoute(pageName, path, arguments);
  } else if (command == 'init') {
    // Initialize the default project structure
    Utils.ensureDependencies();
    createInitialStructure();
    print('Project initialized successfully!');
  } else {
    print(
        'Unknown command. Use "riverpod_cli create page:<page_name> --path <path>"');
  }
}
