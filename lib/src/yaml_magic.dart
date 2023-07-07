import 'dart:io';
import 'package:yaml/yaml.dart';

import 'exceptions/exceptions.dart';
import 'extensions/extensions.dart';
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

  final Map<String, dynamic> _originalMap = {};

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
      _originalMap.addAll((_document.contents as YamlMap).toMap());
      final comments = _getComments(content);
      /*print(
        'comments\n'
        '${comments.map((e) => '$e | '
            'indentLevel: ${e.indentLevel} | '
            'key;value: ${e.lineKey};${e.lineValue} | '
            'number: ${e.lineKeyExistsCount}').join('\n')}',
      );*/

      // Merge originalMap with comments
      final mergedMap = _mergeMapWithComments(_originalMap, comments);

      map = mergedMap;
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

  Map<String, dynamic> _mergeMapWithComments(
    Map<String, dynamic> map,
    List<YamlComment> comments, {
    int level = 0,
    Map<String, dynamic>? currentMergedMap,
  }) {
    final mergedMap = <String, dynamic>{};

    // Merge the original map with the comments
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;
      final keyExistsCount =
          _getKeyExistsCount(_originalMap, key, keyLevel: level);
      //print('map key;value: $key;$value | level: $level | number: $keyExistsCount');

      // Find the comment associated with the current key
      final commentIndex = comments.indexWhere(
        (c) =>
            c.lineKey == key &&
            c.lineKeyExistsCount == keyExistsCount &&
            (c.lineValue?.toString().trim().removeQuotes() ==
                    value
                        .toString()
                        .trim()
                        .replaceFirst('- ', '')
                        .trim()
                        .removeQuotes() ||
                value is Map ||
                value is Iterable ||
                value == null),
      );
      if (commentIndex > -1) {
        final comment = comments[commentIndex];
        // Add the comment before the key-value pair
        if (!_isMapContainsComment(currentMergedMap ?? mergedMap, comment)) {
          mergedMap[comment.key] = comment;
        }
      }

      if (value is Map<String, dynamic>) {
        final nestedMergedMap = _mergeMapWithComments(
          value,
          comments,
          level: level + 1,
          currentMergedMap: mergedMap,
        );
        mergedMap[key] = nestedMergedMap;
      } else if (value is Iterable) {
        final mergedIterable = <dynamic>[];
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nestedMergedMap = _mergeMapWithComments(
              item,
              comments,
              level: level + 1,
              currentMergedMap: mergedMap,
            );
            mergedIterable.add(nestedMergedMap);
          } else {
            // Find the comment associated with the current list value
            final commentIndex = comments.indexWhere(
              (c) =>
                  c.lineKey == null &&
                  c.lineValue ==
                      item
                          .toString()
                          .trimLeft()
                          .replaceFirst('-', '')
                          .trimLeft(),
            );
            if (commentIndex > -1) {
              final comment = comments[commentIndex];
              // Add the comment before the value
              if (!_isMapContainsComment(
                currentMergedMap ?? mergedMap,
                comment,
              )) {
                mergedIterable.add(comment);
              }
            }
            mergedIterable.add(item);
          }
        }
        mergedMap[key] = mergedIterable;
      } else {
        // Regular value assignment
        mergedMap[key] = value;
      }
    }

    // add a comment if there a last comment in the yaml content
    if (level == 0) {
      final lastCommentIndex = comments.indexWhere(
        (c) => c.lineKey == null && c.lineValue == null,
      );
      if (lastCommentIndex > -1) {
        final comment = comments[lastCommentIndex];
        if (!_isMapContainsComment(currentMergedMap ?? mergedMap, comment)) {
          mergedMap.addAll(comment.toMap());
        }
      }
    }

    return mergedMap;
  }

  /// Returns how many times a key with content: [keyString] is
  /// found in the [map], the count start from level 0 to [keyLevel]!
  int _getKeyExistsCount(
    Map<String, dynamic> map,
    String keyString, {
    int keyLevel = 0,
    int currentLevel = 0,
  }) {
    int keyExistsCount = 0;
    if (currentLevel > 0 && currentLevel > keyLevel) return 0;

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == keyString) keyExistsCount++;

      if (value is Map<String, dynamic>) {
        final childKeyExistsCount = _getKeyExistsCount(value, keyString,
            keyLevel: keyLevel, currentLevel: currentLevel + 1);
        keyExistsCount += childKeyExistsCount;
      } else if (value is Iterable) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            final childKeyExistsCount = _getKeyExistsCount(item, keyString,
                keyLevel: keyLevel, currentLevel: currentLevel + 1);
            keyExistsCount += childKeyExistsCount;
          }
        }
      }
    }

    return keyExistsCount;
  }

  bool _isMapContainsComment(Map<String, dynamic> map, YamlComment comment) {
    return map.values.any(
      (value) =>
          (value is YamlComment && value == comment) ||
          (value is Map<String, dynamic> &&
              _isMapContainsComment(value, comment)) ||
          value is Iterable &&
              value.any(
                (item) =>
                    (item is YamlComment && item == comment) ||
                    (item is Map<String, dynamic> &&
                        _isMapContainsComment(item, comment)),
              ),
    );
  }

  /// Retrieves comments from the provided YAML [content] string.
  ///
  /// Returns a [List] of [YamlComment] objects,
  List<YamlComment> _getComments(String content) {
    final lines =
        content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final comments = <YamlComment>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trimLeft().startsWith('#')) {
        var commentText = line.trimLeft().substring(1).removeFirstSpace();
        final indentLevel = _getIndentLevel(line);
        var endLine = i;

        // Check if it's a multiline comment, and append more text content if any
        while (endLine < lines.length - 1 &&
            lines[endLine + 1].trimLeft().startsWith('#')) {
          final commentLineText =
              lines[endLine + 1].trimLeft().substring(1).removeFirstSpace();
          commentText += '\n$commentLineText';
          endLine++;
        }

        final nextLine = lines.length > endLine + 1 ? lines[endLine + 1] : null;
        final key =
            nextLine == null ? null : YamlComment.getKeyFromLine(nextLine);
        final keyLevel = key == null ? 0 : _getIndentLevel(nextLine!);
        final keyExistsCount = key == null
            ? 0
            : _getKeyExistsCount(
                _originalMap,
                key,
                keyLevel: keyLevel,
              );
        // print('keyExistsCount $keyExistsCount of $key, keyLevel: $keyLevel, nextLine: $nextLine');

        String removeComment(String input) {
          // Match comments that start with '#' and are not part of input
          final commentRegex = RegExp(r'(?<!\w)#\s*[^"]*$');
          // Remove comments from the input string
          final result = input.replaceAll(commentRegex, '');
          return result.trimRight();
        }

        comments.add(YamlComment(
          commentText,
          indentLevel: indentLevel,
          lineAfter: lines.length > endLine + 1
              ? removeComment(lines[endLine + 1])
              : null,
          lineKeyExistsCount: keyExistsCount,
        ));

        i = endLine; // Skip to the end of the multiline comment
      }
    }

    return comments;
  }

  int _getIndentLevel(String line) {
    int indentLevel = 0;
    int index = 0;
    while (index < line.length && line[index] == ' ') {
      indentLevel += 1;
      index += 1;
    }
    return indentLevel ~/ 2;
  }

  static final YamlComment _yamlMagicComment =
      const YamlComment('This YAML file has been written using YamlMagic.');

  /// Saves the changes made to the YAML file.
  Future<String> save() async {
    final file = File('$path.tmp');
    final sink = file.openWrite(); // Open the file for writing

    if (!_isMagicYamlCommentExists(map)) {
      map = {
        ..._yamlMagicComment.toMap(),
        ...map,
      };
    }
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

  bool _isCommentLineKeyValueExists(
    YamlComment comment,
    List<YamlComment> comments,
  ) =>
      comments.any(
        (c) =>
            c.lineKey == comment.lineKey &&
            c.lineValue == comment.lineValue &&
            c != comment,
      );

  bool _isMagicYamlCommentExists(Map<String, dynamic> map) {
    if (map.values.isNotEmpty) {
      final firstValue = map.values.first;

      if (firstValue is YamlComment &&
          firstValue.text == _yamlMagicComment.text &&
          firstValue.indentLevel == _yamlMagicComment.indentLevel) {
        return true;
      }
    }

    return false;
  }

  /// Adds a comment to the YAML file.
  ///
  /// The [comment] parameter specifies the comment to be added.
  void addComment(YamlComment comment) => map.addAll(comment.toMap());

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
              final arrayItem = _formatValue(item);
              sink.writeln(arrayItem);
            }
            index++;
          }
        } else {
          // dynamic
          final formatedValue =
              _formatValue(value, level: level + (arrayItemIndex > -1 ? 1 : 0));
          sink.writeln(' $formatedValue');
        }
      }
      keyValueIndex++;
    });

    return sink.toString();
  }

  String _formatValue(
    dynamic value, {
    int level = 0,
  }) {
    if (value is String) {
      // Check if the string contains newlines
      if (value.contains('\n')) {
        final indent = '  ' * (level + 1);
        final lines = value.split('\n');
        final formattedEscaped = lines
            .map((line) => indent + _escapeString(line))
            .join('\n')
            .trimRight();
        return '|-\n$formattedEscaped';
      } else {
        if (_shouldWrapValue(value)) {
          return '"${_escapeString(value)}"';
        }
        return _escapeString(value);
      }
    }
    return value == null ? '' : value.toString();
  }

  String _escapeString(String s) => s.replaceAll('"', r'\"');

  bool _shouldWrapValue(String input) {
    input = input.trim();
    final pattern = RegExp(r'^[>|].*');

    // Check if the value starts with '>' or '|'
    return pattern.hasMatch(input);
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
