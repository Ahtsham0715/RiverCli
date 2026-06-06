import 'package:river_cli/command/create/create_options.dart';
import 'package:river_cli/command/create/init_options.dart';
import 'package:river_cli/static/modules/modules.dart';
import 'package:river_cli/utils/field_spec.dart';
import 'package:river_cli/utils/naming.dart';
import 'package:test/test.dart';

void main() {
  group('Module registry', () {
    test('exposes the expected optional modules', () {
      expect(
        kModules.keys.toSet(),
        {'config', 'utils', 'extensions', 'widgets', 'network', 'storage'},
      );
    });

    test('core is never listed as an optional module', () {
      expect(kModules.containsKey('core'), isFalse);
    });

    test('unknownModuleKeys flags only unrecognized keys', () {
      expect(unknownModuleKeys(['config', 'bogus', 'utils']), ['bogus']);
      expect(unknownModuleKeys(['widgets']), isEmpty);
    });
  });

  group('resolveModules', () {
    List<String> keysOf(List<Module> modules) =>
        modules.map((m) => m.key).toList();

    test('always includes core first', () {
      final resolved = resolveModules([]);
      expect(resolved.first.key, 'core');
    });

    test('expands transitive dependencies for widgets', () {
      final resolved = keysOf(resolveModules(['widgets']));
      expect(resolved.first, 'core');
      expect(
          resolved, containsAll(['config', 'utils', 'extensions', 'widgets']));
    });

    test('orders dependencies before dependents', () {
      final resolved = keysOf(resolveModules(['widgets']));
      expect(resolved.indexOf('config'), lessThan(resolved.indexOf('widgets')));
      expect(resolved.indexOf('utils'), lessThan(resolved.indexOf('widgets')));
      expect(resolved.indexOf('extensions'),
          lessThan(resolved.indexOf('widgets')));
    });

    test('network and storage pull in config', () {
      expect(keysOf(resolveModules(['network'])),
          containsAll(['config', 'network']));
      expect(keysOf(resolveModules(['storage'])),
          containsAll(['config', 'storage']));
    });

    test('does not duplicate shared dependencies', () {
      final resolved =
          keysOf(resolveModules(['widgets', 'network', 'storage']));
      expect(resolved.where((k) => k == 'config').length, 1);
      expect(resolved.where((k) => k == 'core').length, 1);
    });

    test('ignores unknown keys without throwing', () {
      final resolved = keysOf(resolveModules(['nope']));
      expect(resolved, ['core']);
    });
  });

  group('InitOptions.parse', () {
    test('defaults to interactive with no args', () {
      final opts = InitOptions.parse([]);
      expect(opts.wantsInteractive, isTrue);
      expect(opts.explicitSelection(), isNull);
      expect(opts.runPubGet, isTrue);
      expect(opts.force, isFalse);
    });

    test('--all selects every optional module', () {
      final opts = InitOptions.parse(['--all']);
      expect(opts.wantsInteractive, isFalse);
      expect(opts.explicitSelection()!.toSet(), kModules.keys.toSet());
    });

    test('--minimal selects no optional modules', () {
      final opts = InitOptions.parse(['--minimal']);
      expect(opts.explicitSelection(), isEmpty);
    });

    test('--modules accepts a comma-separated value', () {
      final opts = InitOptions.parse(['--modules', 'config,utils,widgets']);
      expect(opts.explicitSelection(), ['config', 'utils', 'widgets']);
    });

    test('--modules=value form is supported', () {
      final opts = InitOptions.parse(['--modules=config,network']);
      expect(opts.explicitSelection(), ['config', 'network']);
    });

    test('--yes with no selection includes all', () {
      final opts = InitOptions.parse(['--yes']);
      expect(opts.explicitSelection()!.toSet(), kModules.keys.toSet());
    });

    test('parses --force, --no-pub-get, --list, --help', () {
      final opts =
          InitOptions.parse(['--force', '--no-pub-get', '--list', '--help']);
      expect(opts.force, isTrue);
      expect(opts.runPubGet, isFalse);
      expect(opts.list, isTrue);
      expect(opts.help, isTrue);
    });

    test('collects unknown flags', () {
      final opts = InitOptions.parse(['--bogus', '--all']);
      expect(opts.unknownFlags, ['--bogus']);
      expect(opts.all, isTrue);
    });
  });

  group('Naming', () {
    test('normalizes any input casing to snake/pascal/camel/title', () {
      for (final input in [
        'my_cool_page',
        'myCoolPage',
        'MyCoolPage',
        'my-cool-page',
        'my cool page'
      ]) {
        expect(Naming.snake(input), 'my_cool_page', reason: input);
        expect(Naming.pascal(input), 'MyCoolPage', reason: input);
        expect(Naming.camel(input), 'myCoolPage', reason: input);
        expect(Naming.title(input), 'My Cool Page', reason: input);
      }
    });

    test('handles single words and empty input', () {
      expect(Naming.pascal('todo'), 'Todo');
      expect(Naming.camel('todo'), 'todo');
      expect(Naming.snake(''), '');
    });
  });

  group('parseFields', () {
    test('returns empty for null or blank input', () {
      expect(parseFields(null), isEmpty);
      expect(parseFields('   '), isEmpty);
    });

    test('parses name:type pairs and trims whitespace', () {
      final fields = parseFields('title:String, count:int , done:bool');
      expect(fields.map((f) => f.name), ['title', 'count', 'done']);
      expect(fields.map((f) => f.type), ['String', 'int', 'bool']);
      expect(fields.every((f) => !f.nullable), isTrue);
    });

    test('recognizes nullable fields via trailing ?', () {
      final fields = parseFields('age:int?, name:String');
      expect(fields[0].nullable, isTrue);
      expect(fields[0].fullType, 'int?');
      expect(fields[1].nullable, isFalse);
    });

    test('defaults missing type to String and normalizes name casing', () {
      final fields = parseFields('FirstName, last_name:String');
      expect(fields[0].name, 'firstName');
      expect(fields[0].type, 'String');
      expect(fields[1].name, 'lastName');
    });

    test('generates correct (de)serialization expressions', () {
      final list = parseFields('tags:List<String>').single;
      expect(list.fromJsonExpr(),
          "(json['tags'] as List<dynamic>).cast<String>()");

      final date = parseFields('due:DateTime?').single;
      expect(date.fromJsonExpr(),
          "json['due'] == null ? null : DateTime.parse(json['due'] as String)");
      expect(date.toJsonEntry(), "'due': due?.toIso8601String(),");
    });
  });

  group('CreateOptions.parse', () {
    test('extracts kind, name and defaults', () {
      final opts = CreateOptions.parse(['model:todo_item']);
      expect(opts.kind, 'model');
      expect(opts.name, 'todo_item');
      expect(opts.path, 'lib/presentation');
      expect(opts.isValid, isTrue);
      expect(opts.fields, isEmpty);
    });

    test('parses path, fields, force and dry-run flags', () {
      final opts = CreateOptions.parse([
        'feature:product',
        '--path',
        'lib/features',
        '--fields',
        'name:String, price:double',
        '--force',
        '--dry-run',
      ]);
      expect(opts.kind, 'feature');
      expect(opts.path, 'lib/features');
      expect(opts.force, isTrue);
      expect(opts.dryRun, isTrue);
      expect(opts.fields.map((f) => f.name), ['name', 'price']);
    });

    test('supports --path= and --fields= forms', () {
      final opts = CreateOptions.parse(
          ['model:order', '--path=lib/x', '--fields=id:String']);
      expect(opts.path, 'lib/x');
      expect(opts.fields.single.name, 'id');
    });

    test('is invalid without a kind:name token', () {
      expect(CreateOptions.parse(['--force']).isValid, isFalse);
    });
  });
}
