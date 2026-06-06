import 'field_spec.dart';
import 'naming.dart';

/// A model to generate: a class [name] and its [fields].
class ModelDef {
  final String name;
  final List<FieldSpec> fields;
  const ModelDef(this.name, this.fields);
}

/// Infers a set of [ModelDef]s from a decoded JSON value. The root object
/// becomes a model named [rootName] (PascalCase); nested objects become their
/// own models named after the key that holds them. Returns the root model first
/// followed by nested models (de-duplicated by name).
///
/// Type inference: `int`/`double`/`bool`/`String` from primitives, `DateTime`
/// for ISO-8601-looking strings, `List<T>` from arrays (element type from the
/// first element), nested object/array-of-object types as generated models, and
/// `dynamic` for `null` or empty arrays.
List<ModelDef> inferModels(String rootName, Object? json) {
  final models = <ModelDef>[];
  final seen = <String>{};

  void addModel(String name, Map<String, dynamic> map) {
    if (seen.contains(name)) return;
    seen.add(name);
    final fields = <FieldSpec>[];
    final nested = <_PendingModel>[];

    map.forEach((key, value) {
      final fieldName = Naming.camel(key);
      if (fieldName.isEmpty) return;
      final inferred = _inferField(fieldName, key, value, nested);
      fields.add(inferred);
    });

    models.add(ModelDef(name, fields));
    // Recurse into nested objects after registering this model.
    for (final p in nested) {
      addModel(p.name, p.map);
    }
  }

  if (json is Map<String, dynamic>) {
    addModel(Naming.pascal(rootName), json);
  } else if (json is List && json.isNotEmpty && json.first is Map) {
    // A top-level array of objects: model the element.
    addModel(Naming.pascal(rootName), json.first as Map<String, dynamic>);
  } else {
    // Not an object — emit a placeholder model with a single `value` field.
    models.add(ModelDef(
      Naming.pascal(rootName),
      [FieldSpec('value', _scalarType(json), false)],
    ));
  }

  return models;
}

class _PendingModel {
  final String name;
  final Map<String, dynamic> map;
  const _PendingModel(this.name, this.map);
}

FieldSpec _inferField(
  String fieldName,
  String key,
  Object? value,
  List<_PendingModel> nested,
) {
  if (value == null) {
    return FieldSpec(fieldName, 'dynamic', false);
  }
  if (value is Map<String, dynamic>) {
    final modelName = Naming.pascal(key);
    nested.add(_PendingModel(modelName, value));
    return FieldSpec(fieldName, modelName, false, isModel: true);
  }
  if (value is List) {
    if (value.isEmpty) {
      return FieldSpec(fieldName, 'List<dynamic>', false);
    }
    final first = value.first;
    if (first is Map<String, dynamic>) {
      final elementName = Naming.pascal(_singularize(key));
      nested.add(_PendingModel(elementName, first));
      return FieldSpec(fieldName, 'List<$elementName>', false, isModel: true);
    }
    return FieldSpec(fieldName, 'List<${_scalarType(first)}>', false);
  }
  return FieldSpec(fieldName, _scalarType(value), false);
}

String _scalarType(Object? value) {
  if (value is bool) return 'bool';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is String) return _looksLikeDate(value) ? 'DateTime' : 'String';
  return 'dynamic';
}

final RegExp _isoDate = RegExp(
    r'^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2})?(\.\d+)?(Z|[+-]\d{2}:?\d{2})?)?$');

bool _looksLikeDate(String value) => _isoDate.hasMatch(value);

/// Naive English singularization sufficient for deriving element model names
/// from collection keys: `categories` → `category`, `users` → `user`.
String _singularize(String key) {
  if (key.length <= 1) return key;
  if (key.endsWith('ies')) return '${key.substring(0, key.length - 3)}y';
  if (key.endsWith('ses')) return key.substring(0, key.length - 2);
  if (key.endsWith('s')) return key.substring(0, key.length - 1);
  return key;
}
