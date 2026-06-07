import 'naming.dart';

/// A single field parsed from a `--fields` spec, e.g. `title:String` or
/// `age:int?` (the trailing `?` marks the field nullable), or inferred from a
/// JSON sample (where [isModel] flags fields whose type is a generated model
/// that exposes `fromJson` / `toJson`).
class FieldSpec {
  /// Field name in `camelCase` (normalized from whatever the user typed).
  final String name;

  /// Dart type as written, e.g. `String`, `int`, `List<String>`, `Address`.
  final String type;

  /// Whether the field is nullable (declared with a trailing `?`).
  final bool nullable;

  /// True when [type] (or, for a `List<T>`, its element `T`) is a generated
  /// model with `fromJson` / `toJson` constructors, so (de)serialization must
  /// recurse instead of casting.
  final bool isModel;

  const FieldSpec(this.name, this.type, this.nullable, {this.isModel = false});

  /// Type including the `?` suffix when nullable.
  String get fullType => nullable ? '$type?' : type;

  bool get _isList => type.startsWith('List<');
  bool get _isDateTime => type == 'DateTime';

  /// The element type of a `List<...>` field (defaults to `dynamic`).
  String get listElement {
    final match = RegExp(r'^List<(.+)>$').firstMatch(type);
    return match?.group(1) ?? 'dynamic';
  }

  /// `final String title;`
  String get declaration => 'final $fullType $name;';

  /// Constructor parameter: `required this.title` or `this.age` for nullables.
  String get ctorParam => nullable ? 'this.$name' : 'required this.$name';

  /// Right-hand side that reads this field out of a JSON map.
  String fromJsonExpr() {
    final key = "json['$name']";

    if (_isList) {
      if (isModel) {
        final mapEl = '(e) => $listElement.fromJson(e as Map<String, dynamic>)';
        return nullable
            ? "($key as List<dynamic>?)?.map($mapEl).toList()"
            : "($key as List<dynamic>).map($mapEl).toList()";
      }
      return nullable
          ? "($key as List<dynamic>?)?.cast<$listElement>()"
          : "($key as List<dynamic>).cast<$listElement>()";
    }

    if (isModel) {
      final parse = '$type.fromJson($key as Map<String, dynamic>)';
      return nullable ? '$key == null ? null : $parse' : parse;
    }

    if (_isDateTime) {
      return nullable
          ? "$key == null ? null : DateTime.parse($key as String)"
          : "DateTime.parse($key as String)";
    }

    return '$key as $fullType';
  }

  /// `'title': title` (models and DateTimes are serialized recursively).
  String toJsonEntry() {
    if (_isList && isModel) {
      final access = nullable
          ? '$name?.map((e) => e.toJson()).toList()'
          : '$name.map((e) => e.toJson()).toList()';
      return "'$name': $access,";
    }
    if (isModel) {
      final access = nullable ? '$name?.toJson()' : '$name.toJson()';
      return "'$name': $access,";
    }
    if (_isDateTime) {
      final access =
          nullable ? '$name?.toIso8601String()' : '$name.toIso8601String()';
      return "'$name': $access,";
    }
    return "'$name': $name,";
  }

  /// A reasonable placeholder used when rendering a field in a generated view.
  String get displayExpr => _isList ? '$name.join(", ")' : '$name.toString()';

  /// A literal sample value for this field, used in generated round-trip tests.
  /// Returns the Dart literal and its matching JSON literal (which differ for
  /// `DateTime`, where JSON carries an ISO-8601 string).
  ({String dart, String json}) sampleLiteral() {
    if (nullable) return (dart: 'null', json: 'null');
    if (isModel && !_isList) {
      return (
        dart: '$type.fromJson(${_modelSampleJson()})',
        json: _modelSampleJson()
      );
    }
    if (_isList) {
      return (dart: 'const []', json: '[]');
    }
    switch (type) {
      case 'int':
        return (dart: '1', json: '1');
      case 'double':
        return (dart: '1.5', json: '1.5');
      case 'num':
        return (dart: '1', json: '1');
      case 'bool':
        return (dart: 'true', json: 'true');
      case 'DateTime':
        return (
          dart: "DateTime.parse('2020-01-01T00:00:00.000')",
          json: "'2020-01-01T00:00:00.000'"
        );
      default:
        return (dart: "'sample'", json: "'sample'");
    }
  }

  String _modelSampleJson() => '<String, dynamic>{}';
}

/// Parses a `--fields` value like `"title:String, done:bool, age:int?"` into a
/// list of [FieldSpec]. Whitespace is tolerated; a missing type defaults to
/// `String`. Returns an empty list for null/blank input.
List<FieldSpec> parseFields(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final fields = <FieldSpec>[];
  for (final part in raw.split(',')) {
    final token = part.trim();
    if (token.isEmpty) continue;
    final colon = token.indexOf(':');
    final rawName = colon == -1 ? token : token.substring(0, colon);
    var type = colon == -1 ? 'String' : token.substring(colon + 1).trim();
    if (type.isEmpty) type = 'String';

    var nullable = false;
    if (type.endsWith('?')) {
      nullable = true;
      type = type.substring(0, type.length - 1).trim();
    }
    final name = Naming.camel(rawName);
    if (name.isEmpty) continue;
    fields.add(FieldSpec(name, type, nullable));
  }
  return fields;
}
