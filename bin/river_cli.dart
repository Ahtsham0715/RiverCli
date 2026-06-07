import 'package:river_cli/command/create/create_options.dart';
import 'package:river_cli/command/create/create_page.dart';
import 'package:river_cli/command/create/generators.dart';
import 'package:river_cli/command/create/init_options.dart';
import 'package:river_cli/command/create/project_init.dart';
import 'package:river_cli/command/doctor/doctor.dart';
import 'package:river_cli/command/generate/generate_routes.dart';
import 'package:river_cli/command/remove/remove_feature.dart';
import 'package:river_cli/command/skill/install_skill.dart';
import 'package:river_cli/utils/project.dart';
import 'package:river_cli/utils/utils.dart';
import 'package:river_cli/version.dart';

void main(List<String> arguments) {
  if (arguments.isEmpty) {
    Utils.printUsage();
    return;
  }

  final command = arguments[0];
  final rest = arguments.sublist(1);

  switch (command) {
    case 'create':
      _runCreate(arguments, rest);
      break;
    case 'init':
      runInit(InitOptions.parse(rest));
      break;
    case 'skill':
      runSkill(rest);
      break;
    case 'doctor':
      runDoctor();
      break;
    case 'generate':
    case 'gen':
      _runGenerate(rest);
      break;
    case 'remove':
    case 'rm':
      runRemove(rest);
      break;
    case '--version':
    case '-v':
    case 'version':
      print('river_cli $kRiverCliVersion');
      break;
    case '--help':
    case '-h':
    case 'help':
      Utils.printUsage();
      break;
    default:
      print('Unknown command "$command".\n');
      Utils.printUsage();
  }
}

/// Dispatches the `create <kind>:<name>` family. `page`/`screen` keep their
/// original behavior; the new kinds (`model`, `repository`, `widget`,
/// `feature`) use the shared option parser and generators.
void _runCreate(List<String> arguments, List<String> rest) {
  final opts = CreateOptions.parse(rest);

  if (!opts.isValid) {
    print('Error: missing target. '
        'Usage: river_cli create <page|screen|model|repository|widget|feature>:<name>');
    return;
  }

  if (!ProjectContext.isFlutterRoot) {
    print('Error: pubspec.yaml not found. '
        'Run this command in the root of a Flutter project.');
    return;
  }

  switch (opts.kind) {
    case 'page':
    case 'screen':
      // Preserve the original page/screen code path and route handling.
      Utils.ensureDependencies();
      CreatePage().createPageWithRoute(opts.name, opts.path, arguments);
      break;
    case 'model':
      createModel(opts, ProjectContext.detect());
      break;
    case 'repository':
    case 'repo':
      createRepository(opts, ProjectContext.detect());
      break;
    case 'widget':
      createWidget(opts, ProjectContext.detect());
      break;
    case 'feature':
      createFeature(opts, ProjectContext.detect());
      break;
    default:
      print('Unknown create target "${opts.kind}". '
          'Valid targets: page, screen, model, repository, widget, feature.');
  }
}

/// Dispatches `generate <what>`. Currently supports `routes`.
void _runGenerate(List<String> rest) {
  final what = rest.isNotEmpty ? rest.first : '';
  switch (what) {
    case 'routes':
    case 'route':
      runGenerateRoutes(rest.sublist(1));
      break;
    default:
      print('Usage: river_cli generate routes [--dry-run]');
  }
}
