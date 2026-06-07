import 'dart:convert';

import '../../utils/field_spec.dart';
import '../../utils/json_inference.dart';
import '../../utils/naming.dart';
import '../../utils/project.dart';
import 'create_options.dart';
import 'route_registrar.dart';
import 'templates.dart';

/// `river_cli create model:<name>` — from a `--fields` spec or a `--json`
/// sample (which can produce nested models).
void createModel(CreateOptions opts, ProjectContext ctx) {
  final snake = Naming.snake(opts.name);
  final writer = FileWriter(force: opts.force, dryRun: opts.dryRun);
  print('Creating model: ${Naming.pascal(opts.name)}');

  final String content;
  final inferred = _inferredModels(opts);
  if (inferred != null) {
    final names = inferred.map((m) => m.name).toList();
    print('  inferred ${names.length} model(s) from JSON: ${names.join(', ')}');
    content = modelsFileTemplate(inferred);
  } else {
    if (opts.fields.isEmpty) {
      print('  (no --fields given; generating a sample "id" field)');
    }
    content = modelTemplate(opts.name, opts.fields);
  }

  writer.write('lib/data/models/${snake}_model.dart', content);
  _maybeWriteModelTest(opts, ctx, writer,
      fieldsForTest: opts.fields, blockedByJson: inferred != null);
  writer.printSummary();
}

/// `river_cli create repository:<name>`
void createRepository(CreateOptions opts, ProjectContext ctx) {
  final snake = Naming.snake(opts.name);
  final writer = FileWriter(force: opts.force, dryRun: opts.dryRun);
  print('Creating repository: ${Naming.pascal(opts.name)}Repository');
  if (!ctx.hasNetwork) {
    print('  (network module not installed — generating a stub repository)');
  }
  writer.write(
    'lib/data/repositories/${snake}_repository.dart',
    repositoryTemplate(opts.name, ctx),
  );
  writer.printSummary();
}

/// `river_cli create widget:<name>`
void createWidget(CreateOptions opts, ProjectContext ctx) {
  final snake = Naming.snake(opts.name);
  final dir = ctx.hasWidgets ? 'lib/app/shared_widgets' : 'lib/widgets';
  final writer = FileWriter(force: opts.force, dryRun: opts.dryRun);
  print('Creating widget: ${Naming.pascal(opts.name)}');
  writer.write('$dir/$snake.dart', widgetTemplate(opts.name, ctx));
  writer.printSummary();
}

/// `river_cli create feature:<name> --fields "..."` (or `--json`)
///
/// The "amazing" generator: model + repository + AsyncNotifier controller +
/// list view + registered route, all wired together and adapted to the
/// installed modules.
void createFeature(CreateOptions opts, ProjectContext ctx) {
  final snake = Naming.snake(opts.name);
  final featureDir = '${opts.path}/$snake';
  final writer = FileWriter(force: opts.force, dryRun: opts.dryRun);

  print('Creating feature: ${Naming.pascal(opts.name)} at $featureDir\n');

  // Shared data layer (model may be inferred from JSON).
  final inferred = _inferredModels(opts);
  final modelContent = inferred != null
      ? modelsFileTemplate(inferred)
      : modelTemplate(opts.name, opts.fields);
  if (inferred != null) {
    print('  inferred ${inferred.length} model(s) from JSON');
  }
  writer.write('lib/data/models/${snake}_model.dart', modelContent);
  writer.write(
    'lib/data/repositories/${snake}_repository.dart',
    repositoryTemplate(opts.name, ctx),
  );

  // Feature layer.
  writer.write(
    '$featureDir/controllers/${snake}_controller.dart',
    crudControllerTemplate(opts.name, ctx),
  );
  writer.write(
    '$featureDir/bindings/${snake}_binding.dart',
    crudBindingTemplate(opts.name),
  );
  writer.write(
    '$featureDir/views/${snake}_view.dart',
    crudViewTemplate(opts.name, opts.fields, ctx),
  );

  _maybeWriteModelTest(opts, ctx, writer,
      fieldsForTest: opts.fields, blockedByJson: inferred != null);

  // Route registration.
  RouteRegistrar.register(
    opts.name,
    viewDir: featureDir,
    ctx: ctx,
    dryRun: opts.dryRun,
  );

  writer.printSummary();
  if (!ctx.hasNetwork) {
    print('\nTip: run "river_cli init --modules network" to wire the '
        'repository to the Dio API client.');
  }
}

/// Parses [CreateOptions.jsonSample] into model defs, or null if no JSON was
/// supplied. Invalid JSON is reported and treated as absent.
List<ModelDef>? _inferredModels(CreateOptions opts) {
  final raw = opts.jsonSample;
  if (raw == null || raw.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return inferModels(opts.name, decoded);
  } on FormatException catch (e) {
    print('  Warning: could not parse JSON sample (${e.message}); '
        'falling back to --fields.');
    return null;
  }
}

/// Writes a round-trip test when `--with-test` is set and it is safe to do so
/// (the model has no nested-model fields, which an empty fixture can't satisfy).
void _maybeWriteModelTest(
  CreateOptions opts,
  ProjectContext ctx,
  FileWriter writer, {
  required List<FieldSpec> fieldsForTest,
  required bool blockedByJson,
}) {
  if (!opts.withTest) return;
  if (blockedByJson) {
    print('  (skipping --with-test: round-trip tests are not generated for '
        'JSON-inferred models)');
    return;
  }
  if (fieldsForTest.any((f) => f.isModel)) {
    print('  (skipping --with-test: model has nested-model fields)');
    return;
  }
  final snake = Naming.snake(opts.name);
  writer.write(
    'test/${snake}_model_test.dart',
    modelTestTemplate(opts.name, fieldsForTest, ctx),
  );
}
