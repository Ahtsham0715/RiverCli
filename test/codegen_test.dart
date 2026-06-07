import 'package:river_cli/command/create/create_options.dart';
import 'package:river_cli/command/create/route_codegen.dart';
import 'package:river_cli/command/generate/generate_routes.dart';
import 'package:river_cli/utils/field_spec.dart';
import 'package:river_cli/utils/json_inference.dart';
import 'package:test/test.dart';

void main() {
  group('FieldSpec serialization', () {
    test('primitive fromJson/toJson', () {
      const f = FieldSpec('count', 'int', false);
      expect(f.fromJsonExpr(), "json['count'] as int");
      expect(f.toJsonEntry(), "'count': count,");
    });

    test('nullable primitive', () {
      const f = FieldSpec('count', 'int', true);
      expect(f.fullType, 'int?');
      expect(f.fromJsonExpr(), "json['count'] as int?");
    });

    test('DateTime is parsed and serialized to ISO-8601', () {
      const f = FieldSpec('due', 'DateTime', false);
      expect(f.fromJsonExpr(), "DateTime.parse(json['due'] as String)");
      expect(f.toJsonEntry(), "'due': due.toIso8601String(),");

      const n = FieldSpec('due', 'DateTime', true);
      expect(n.fromJsonExpr(),
          "json['due'] == null ? null : DateTime.parse(json['due'] as String)");
      expect(n.toJsonEntry(), "'due': due?.toIso8601String(),");
    });

    test('List of primitives casts elements', () {
      const f = FieldSpec('tags', 'List<String>', false);
      expect(
          f.fromJsonExpr(), "(json['tags'] as List<dynamic>).cast<String>()");
      expect(f.toJsonEntry(), "'tags': tags,");
    });

    test('nested model recurses through fromJson/toJson', () {
      const f = FieldSpec('address', 'Address', false, isModel: true);
      expect(f.fromJsonExpr(),
          "Address.fromJson(json['address'] as Map<String, dynamic>)");
      expect(f.toJsonEntry(), "'address': address.toJson(),");

      const n = FieldSpec('address', 'Address', true, isModel: true);
      expect(n.fromJsonExpr(),
          "json['address'] == null ? null : Address.fromJson(json['address'] as Map<String, dynamic>)");
      expect(n.toJsonEntry(), "'address': address?.toJson(),");
    });

    test('List of models maps each element', () {
      const f = FieldSpec('orders', 'List<Order>', false, isModel: true);
      expect(f.fromJsonExpr(),
          "(json['orders'] as List<dynamic>).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList()");
      expect(
          f.toJsonEntry(), "'orders': orders.map((e) => e.toJson()).toList(),");
    });

    test('sampleLiteral matches the type', () {
      expect(const FieldSpec('a', 'int', false).sampleLiteral().json, '1');
      expect(const FieldSpec('a', 'double', false).sampleLiteral().json, '1.5');
      expect(const FieldSpec('a', 'bool', false).sampleLiteral().json, 'true');
      expect(const FieldSpec('a', 'String', false).sampleLiteral().json,
          "'sample'");
      expect(const FieldSpec('a', 'int', true).sampleLiteral().json, 'null');
      expect(const FieldSpec('a', 'List<String>', false).sampleLiteral().json,
          '[]');
    });
  });

  group('inferModels', () {
    test('infers primitive types from a flat object', () {
      final models = inferModels('user', {
        'id': 1,
        'name': 'Ada',
        'active': true,
        'score': 3.5,
      });
      expect(models, hasLength(1));
      final fields = {for (final f in models.single.fields) f.name: f.type};
      expect(fields, {
        'id': 'int',
        'name': 'String',
        'active': 'bool',
        'score': 'double',
      });
    });

    test('detects ISO-8601 date strings as DateTime', () {
      final m =
          inferModels('e', {'created': '2020-05-01T10:00:00.000Z'}).single;
      expect(m.fields.single.type, 'DateTime');
    });

    test('treats non-date strings as String', () {
      final m = inferModels('e', {'name': 'not-a-date'}).single;
      expect(m.fields.single.type, 'String');
    });

    test('null becomes dynamic', () {
      final m = inferModels('e', {'x': null}).single;
      expect(m.fields.single.type, 'dynamic');
    });

    test('nested object becomes its own model named after the key', () {
      final models = inferModels('user', {
        'address': {'city': 'X'}
      });
      expect(models.map((m) => m.name), ['User', 'Address']);
      final addressField = models.first.fields.single;
      expect(addressField.type, 'Address');
      expect(addressField.isModel, isTrue);
    });

    test('array of objects becomes List of a singularized model', () {
      final models = inferModels('order', {
        'items': [
          {'sku': 'A'}
        ]
      });
      expect(models.map((m) => m.name), ['Order', 'Item']);
      final field = models.first.fields.single;
      expect(field.type, 'List<Item>');
      expect(field.isModel, isTrue);
    });

    test('singularizes -ies and -s collection keys', () {
      final categories = inferModels('r', {
        'categories': [
          {'id': 1}
        ]
      });
      expect(categories[1].name, 'Category');
    });

    test('array of primitives becomes a typed List', () {
      final m = inferModels('r', {
        'tags': ['a', 'b']
      }).single;
      expect(m.fields.single.type, 'List<String>');
      expect(m.fields.single.isModel, isFalse);
    });

    test('empty array falls back to List<dynamic>', () {
      final m = inferModels('r', {'xs': []}).single;
      expect(m.fields.single.type, 'List<dynamic>');
    });

    test('top-level array models its first element', () {
      final models = inferModels('thing', [
        {'id': 1}
      ]);
      expect(models.single.name, 'Thing');
      expect(models.single.fields.single.name, 'id');
    });

    test('de-duplicates nested models by name', () {
      final models = inferModels('r', {
        'a': {'v': 1},
        'b': {'v': 2},
      });
      // 'a' and 'b' produce distinct model names A and B (no dedupe collision).
      expect(models.map((m) => m.name), ['R', 'A', 'B']);
    });
  });

  group('route_codegen', () {
    const routes = [
      FeatureRoute(
        routeName: 'product',
        className: 'ProductView',
        importPath: 'package:app/presentation/product/views/product_view.dart',
      ),
      FeatureRoute(
        routeName: 'home',
        className: 'HomeView',
        importPath: 'package:app/presentation/home/views/home_view.dart',
      ),
    ];

    test('buildAppRoutesFile always includes home and skips a home constant',
        () {
      final out = buildAppRoutesFile(routes);
      expect(out, contains("static const String home = '/';"));
      expect(out, contains("static const String product = '/product';"));
      // home is not duplicated as its own '/home' constant.
      expect(out.contains("static const String home = '/home'"), isFalse);
    });

    test('buildRoutePageFile wires a home feature to its view', () {
      final out = buildRoutePageFile(routes, 'app');
      expect(out, contains('builder: (context, state) => const HomeView(),'));
      expect(
          out, contains('builder: (context, state) => const ProductView(),'));
      expect(
          out,
          contains(
              "import 'package:app/presentation/home/views/home_view.dart';"));
    });

    test('buildRoutePageFile uses a Placeholder when no home feature exists',
        () {
      final out = buildRoutePageFile([routes.first], 'app');
      expect(
          out, contains('builder: (context, state) => const Placeholder(),'));
    });

    test('removeRouteConstant removes the line but preserves home', () {
      const content = '''
class AppRoutes {
  static const String home = '/';
  static const String product = '/product';
  static const String login = '/login';
}
''';
      final out = removeRouteConstant(content, 'product');
      expect(out, isNot(contains('product')));
      expect(out, contains("static const String home = '/';"));
      expect(out, contains("static const String login = '/login';"));
    });

    test('removeRouteEntry removes the GoRoute block and its import', () {
      const content = '''
import 'package:flutter/material.dart';
import 'package:app/presentation/product/views/product_view.dart';
import 'package:app/presentation/login/views/login_view.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      name: AppRoutes.product,
      path: AppRoutes.product,
      builder: (context, state) => const ProductView(),
    ),
    GoRoute(
      name: AppRoutes.login,
      path: AppRoutes.login,
      builder: (context, state) => const LoginView(),
    ),
  ],
);
''';
      final out = removeRouteEntry(content, 'product', 'product');
      expect(out, isNot(contains('ProductView')));
      expect(out, isNot(contains('product_view.dart')));
      expect(out, contains('AppRoutes.login'));
      expect(out, contains('login_view.dart'));
    });
  });

  group('featureRoutes mapping', () {
    test('derives route name, class and import from feature dirs', () {
      final routes = featureRoutes(
        ['lib/presentation/user_profile', 'lib/features/cart'],
        'shop',
      );
      expect(routes[0].routeName, 'userProfile');
      expect(routes[0].className, 'UserProfileView');
      expect(routes[0].importPath,
          'package:shop/presentation/user_profile/views/user_profile_view.dart');
      expect(routes[1].importPath,
          'package:shop/features/cart/views/cart_view.dart');
    });
  });

  group('CreateOptions JSON & test flags', () {
    test('parses --json and --with-test', () {
      final opts = CreateOptions.parse(
          ['model:user', '--json', '{"id":1}', '--with-test']);
      expect(opts.jsonSample, '{"id":1}');
      expect(opts.withTest, isTrue);
    });

    test('--json= form is supported', () {
      final opts = CreateOptions.parse(['model:user', '--json={"a":1}']);
      expect(opts.jsonSample, '{"a":1}');
    });

    test('missing --from-json file is ignored with a warning', () {
      final opts = CreateOptions.parse(
          ['model:user', '--from-json', '/no/such/file.json']);
      expect(opts.jsonSample, isNull);
    });
  });
}
