import 'dart:io';
import 'package:yaml/yaml.dart';

import 'exceptions/yaml_io_exception.dart';
import 'extensions/yaml.dart';
import 'models/yaml_comment.dart';

/// Use the `YamlMagic` class to load, modify (edit and manipulate), and save YAML files.
///
/// Example usage:
/// ```dart
/// final yamlMagic = YamlMagic.load(ymlPath);
/// yamlMagic['new_key'] = 'a value';
/// yamlMagic.save();
/// ```
class YamlMagic {
  final String path;
  late YamlDocument _document;

  final Map<String, dynamic> _map = {};

  /// The map representation of the YAML file.
  Map<String, dynamic> get map => _map;

  set map(Map<String, dynamic> value) {
    _map.clear();
    _map.addAll(value);
  }

  /// Creates a new instance of [YamlMagic] from a YAML content string.
  ///
  /// The [content] parameter should contain the YAML content as a string.
  /// The [path] parameter specifies the path to the YAML file.
  YamlMagic.fromString({
    required String content,
    required this.path,
  }) {
    if (content.trim().isEmpty) return;

    _document = loadYamlDocument(content);
    if (_document.contents is YamlMap) {
      map = (_document.contents as YamlMap).toMap();
    }
  }

  /// Loads a YAML file from the specified path.
  ///
  /// Throws a [YamlIOException] if the file doesn't exist.
  /// Throws a [FileSystemException] if the operation fails.
  factory YamlMagic.load(String path) {
    if (!File(path).existsSync()) throw YamlIOException(path);

    final content = File(path).readAsStringSync();
    return YamlMagic.fromString(content: content, path: path);
  }

  /// Saves the changes made to the YAML file.
  Future<String> save() async {
    final file = File('$path.tmp');
    final sink = file.openWrite(); // Open the file for writing

    sink.writeln('# This YAML file has been written using YamlMagic.');
    _writeMapEntries(_map, sink);

    await sink.flush();
    await sink.close();

    final originalFile = File(path);
    final backupFile = File('$path.bak');

    /// Do a safe save.
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    if (await originalFile.exists()) {
      await originalFile.rename(backupFile.path);
    }
    await file.rename(originalFile.path);
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    return toString();
  }

  /// Adds a comment to the YAML file.
  ///
  /// The [comment] parameter specifies the comment to be added.
  void addComment(YamlComment comment) {
    map.addAll({YamlComment.key: comment});
  }

  String _writeMapEntries(
    Map<String, dynamic> map,
    StringSink sink, {
    int level = 0,
    int arrayItemIndex = -1, // -1 means map it's not a list item
  }) {
    var keyValueIndex = 0;
    map.forEach((key, value) {
      if (value is YamlComment) {
        value = value.indentLevel > 0
            ? value
            : value.copyWith(
                indentLevel: level + (arrayItemIndex > -1 ? 1 : 0),
              );
        sink.writeln(value);
      } else {
        final indent = '  ' * level;
        sink.write(
          "$indent${arrayItemIndex > -1 && keyValueIndex == 0 ? '- ' : arrayItemIndex > -1 ? '  ' : ''}",
        );
        sink.write('$key:');
        /*print(
          'key: $key value: $value index $arrayItemIndex level: $level keyValueIndex $keyValueIndex',
        );*/
        if (value is Map<String, dynamic>) {
          sink.writeln();
          _writeMapEntries(
            value,
            sink,
            level: level + 1 + (arrayItemIndex > -1 ? 1 : 0),
          );
        } else if (value is Iterable) {
          sink.writeln();
          var index = 0;
          for (var item in value) {
            if (item is Map<String, dynamic>) {
              _writeMapEntries(
                item,
                sink,
                level: level + 1,
                arrayItemIndex: index,
              );
            } else {
              final extraIndent = arrayItemIndex > -1 ? '  ' : '';
              sink.write("$extraIndent$indent  - ");
              final arrayItem = _formatValue(item, shouldWrap: false);
              sink.writeln(arrayItem);
            }
            index++;
          }
        } else {
          // dynamic
          final formatedValue = _formatValue(value);
          sink.writeln(' $formatedValue');
        }
      }
      keyValueIndex++;
    });

    return sink.toString();
  }

  String _formatValue(dynamic value, {bool shouldWrap = true}) {
    if (value is String && shouldWrap) return '"$value"';
    return value == null ? '' : value.toString();
  }

  @override
  String toString() {
    return _writeMapEntries(_map, StringBuffer());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YamlMagic &&
          runtimeType == other.runtimeType &&
          toString() == other.toString();

  @override
  int get hashCode => toString().hashCode;

  dynamic _normalizedValue(String path) => convertNode(_map[path]);

  /// Returns the value for the given key.
  ///
  /// If the key doesn't exists then null is returned.
  /// ```
  /// var yml = YamlMagic.load('file.yaml');
  /// var password = yml['password'];
  /// ```
  dynamic operator [](String path) => _normalizedValue(path);

  /// Adds or Updates the given key/value pair.
  ///
  /// The value may be a String or a number (int, double);
  ///
  /// ```
  /// var yml = YamlMagic.load('file.yaml');
  /// yml['password'] = 'a new password';
  /// yml.save();
  /// ```
  ///
  void operator []=(String path, dynamic value) => _map[path] = value;
}
