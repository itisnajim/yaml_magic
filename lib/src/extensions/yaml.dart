import 'package:yaml/yaml.dart';

/// Extension methods for the [YamlMap] class.
extension YamlMapExt on YamlMap {
  /// Converts the [YamlMap] to a regular Dart `Map`.
  ///
  /// Returns a `Map<String, dynamic>` where the keys and values are converted
  /// to their corresponding Dart types.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    forEach((dynamic k, dynamic v) {
      if (k is YamlScalar) {
        map[k.value.toString()] = convertNode(v);
      } else {
        map[k.toString()] = convertNode(v);
      }
    });
    return map;
  }
}

/// Converts a YAML node to its corresponding Dart type.
///
/// If the value is a `YamlList`, it is converted to a `List`.
/// If the value is a `YamlMap`, it is converted to a `Map`.
/// Otherwise, the value is returned as-is.
dynamic convertNode(dynamic value) {
  if (value is YamlList) {
    return value.toList();
  }

  if (value is YamlMap) {
    return value.toMap();
  }

  return value;
}
