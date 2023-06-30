import 'dart:io';
import 'package:yaml/yaml.dart';
import 'exceptions/yaml_io_exception.dart';
import 'extensions/yaml.dart';

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
      final topMap = _document.contents as YamlMap;

      for (final key in topMap.keys) {
        _map[key.toString()] = topMap[key];
      }
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
  Future<void> save() async {
    final file = File('$path.tmp');
    final sink = file.openWrite(); // Open the file for writing

    sink.writeln('# This YAML file was generated using YamlMagic.');
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
  }

  void _writeMapEntries(
    Map<String, dynamic> map,
    IOSink sink, {
    int indentLevel = 0,
    bool shouldAddHyphen = false,
  }) {
    final indent = '  ' * indentLevel;

    map.forEach((key, value) {
      sink.write('$indent${shouldAddHyphen ? '- ' : ''}$key: ');
      if (value is Map<String, dynamic>) {
        sink.writeln();
        _writeMapEntries(value, sink, indentLevel: indentLevel + 1);
      } else if (value is Iterable) {
        sink.writeln();
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            _writeMapEntries(item, sink,
                indentLevel: indentLevel + 1, shouldAddHyphen: true);
          } else {
            sink.writeln('$indent  - ${_formatValue(item, shouldWrap: false)}');
          }
        }
      } else {
        sink.writeln(_formatValue(value));
      }
    });
  }

  String _formatValue(dynamic value, {bool shouldWrap = true}) {
    if (value is String && shouldWrap) return '"$value"';
    return value == null ? '' : value.toString();
  }

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
