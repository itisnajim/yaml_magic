import 'dart:io';
import 'package:yaml/yaml.dart';

import 'exceptions/exceptions.dart';
import 'extensions/extensions.dart';
import 'models/models.dart';

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
  final bool noWatermarkComment;
  late YamlDocument _document;

  bool get _includeWatermarkComment => !noWatermarkComment;

  final Map<String, dynamic> _map = {};

  final Map<String, dynamic> _originalMap = {};

  /// The map representation of the YAML file.
  Map<String, dynamic> get map => _map;

  /// The map representation of the YAML file (without comments or break lines)
  Map<String, dynamic> get originalMap => _originalMap;

  set map(Map<String, dynamic> value) {
    _map.clear();
    _map.addAll(value);
  }

  /// Creates a new instance of [YamlMagic] from a YAML content string.
  ///
  /// The [content] parameter should contain the YAML content as a string.
  /// The [path] parameter specifies the path to the YAML file.
  /// Optionally, [noWatermarkComment] can be set to true to exclude watermark comments.
  YamlMagic.fromString({
    required String content,
    required this.path,
    this.noWatermarkComment = false,
  }) {
    if (content.trim().isEmpty) return;

    _document = loadYamlDocument(content);

    if (_document.contents is YamlMap) {
      _originalMap
        ..clear()
        ..addAll((_document.contents as YamlMap).toMap());
      final comments = _getComments(content);
      /*print(
        'comments\n'
        '${comments.map((e) => '$e | '
            'indentLevel: ${e.indentLevel} | '
            'key;value: ${e.lineKey};${e.lineValue} | '
            'number: ${e.lineKeyExistsCount}').join('\n')}',
      );*/
      final breakLines = _getBreakLines(content);

      /*print(
        'breakLines\n'
        '${breakLines.map((b) => 'count: ${b.count} | '
            'key;value: ${b.lineKey};${b.lineValue} | '
            'lineBefore: ${b.lineBefore} | '
            'lineKeyExistsCount: ${b.lineKeyExistsCount}').join('\n')}',
      );*/

      // Merge originalMap with comments
      final mergedWithComments = _mergeMapWithComments(_originalMap, comments);
      final mergedMap = _mergeMapWithBreakLines(mergedWithComments, breakLines);
      map = mergedMap;
    }
  }

  /// Loads a YAML file from the specified path.
  ///
  /// Throws a [YamlIOException] if the file doesn't exist.
  /// Throws a [FileSystemException] if the operation fails.
  /// Optionally, [noWatermarkComment] can be set to true to exclude watermark comments.
  factory YamlMagic.load(String path, {bool noWatermarkComment = false}) {
    if (!File(path).existsSync()) throw YamlIOException(path);

    final content = File(path).readAsStringSync();
    return YamlMagic.fromString(
      content: content,
      path: path,
      noWatermarkComment: noWatermarkComment,
    );
  }

  Map<String, dynamic> _mergeMapWithBreakLines(
    Map map,
    List<YamlBreakLine> breakLines, {
    int level = 0,
    Map? currentMergedMap,
  }) {
    final mergedMap = <String, dynamic>{};

    // add a break line if there a first break line in the yaml content
    if (level == 0) {
      final lastBreakLineIndex = breakLines.indexWhere(
        (c) => c.lineBefore == null,
      );
      if (lastBreakLineIndex > -1) {
        final breakLine = breakLines[lastBreakLineIndex];
        mergedMap.addAll(breakLine.toMap());
      }
    }

    // Merge the original map with the break lines
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      //print('map key;value: $key;$value | level: $level | number: $keyExistsCount');

      if (value is Map) {
        final nestedMergedMap = _mergeMapWithBreakLines(
          value,
          breakLines,
          level: level + 1,
          currentMergedMap: mergedMap,
        );
        mergedMap[key] = nestedMergedMap;
      } else if (value is Iterable) {
        final mergedIterable = <dynamic>[];
        for (final item in value) {
          if (item is Map) {
            final nestedMergedMap = _mergeMapWithBreakLines(
              item,
              breakLines,
              level: level + 1,
              currentMergedMap: mergedMap,
            );
            mergedIterable.add(nestedMergedMap);
          } else {
            // Find the breakLine associated with the current list value
            final breakLineIndex = breakLines.indexWhere(
              (c) =>
                  c.lineKey == null &&
                  c.lineValue ==
                      item
                          .toString()
                          .trimLeft()
                          .replaceFirst(r'[-#]', '')
                          .trim(),
            );

            mergedIterable.add(item);
            if (breakLineIndex > -1) {
              final breakLine = breakLines[breakLineIndex];
              // Add the break line after the value
              mergedIterable.add(breakLine);
            }
          }
        }
        mergedMap[key] = mergedIterable;
      } else {
        // Regular value assignment
        mergedMap[key] = value;
      }

      final keyExistsCount =
          _getKeyExistsCount(_originalMap, key, keyLevel: level);

      // Find the break line associated with the current key
      final breakLineIndex = breakLines.indexWhere(
        (b) =>
            ((b.lineBefore ?? '').isNotEmpty &&
                b.isLineBeforeComment &&
                value is YamlComment &&
                value.text
                    .trim()
                    .contains(b.lineBefore!.replaceFirst('#', '').trim())) ||
            (b.lineKey == key &&
                b.lineKeyExistsCount == keyExistsCount &&
                ((b.lineValue?.toString().trim().removeQuotes() ==
                    value
                        .toString()
                        .trim()
                        .replaceFirst(r'[-#]', '')
                        .trim()
                        .removeQuotes()))),
      );
      if (breakLineIndex > -1) {
        final breakLine = breakLines[breakLineIndex];
        // Add the breakLine after the key-value pair
        mergedMap[breakLine.key] = breakLine;
      }
    }

    return mergedMap;
  }

  Map<String, dynamic> _mergeMapWithComments(
    Map map,
    List<YamlComment> comments, {
    int level = 0,
    Map? currentMergedMap,
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

      if (value is Map) {
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
          if (item is Map) {
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
    Map map,
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

      if (value is Map) {
        final childKeyExistsCount = _getKeyExistsCount(value, keyString,
            keyLevel: keyLevel, currentLevel: currentLevel + 1);
        keyExistsCount += childKeyExistsCount;
      } else if (value is Iterable) {
        for (var item in value) {
          if (item is Map) {
            final childKeyExistsCount = _getKeyExistsCount(item, keyString,
                keyLevel: keyLevel, currentLevel: currentLevel + 1);
            keyExistsCount += childKeyExistsCount;
          }
        }
      }
    }

    return keyExistsCount;
  }

  bool _isMapContainsComment(Map map, YamlComment comment) {
    return map.values.any(
      (value) =>
          (value is YamlComment && value == comment) ||
          (value is Map && _isMapContainsComment(value, comment)) ||
          value is Iterable &&
              value.any(
                (item) =>
                    (item is YamlComment && item == comment) ||
                    (item is Map && _isMapContainsComment(item, comment)),
              ),
    );
  }

  /// Retrieves comments from the provided YAML [content] string.
  ///
  /// Returns a [List] of [YamlComment] objects,
  List<YamlComment> _getComments(String content) {
    final lines = content.split('\n').toList();
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

  /// Retrieves break lines from the provided YAML [content] string.
  ///
  /// Returns a [List] of [YamlBreakLine] objects,
  List<YamlBreakLine> _getBreakLines(String content) {
    final breakLines = <YamlBreakLine>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        int count = 1;
        var endLine = i;

        // Check if it's a multi line break and count them.
        while (
            endLine < lines.length - 1 && lines[endLine + 1].trim().isEmpty) {
          count++;
          endLine++;
        }

        final String? lineBefore = i > 0 ? lines[i - 1] : null;
        final key =
            lineBefore == null ? null : YamlComment.getKeyFromLine(lineBefore);
        final keyLevel = key == null ? 0 : _getIndentLevel(lineBefore!);
        final keyExistsCount = key == null
            ? 0
            : _getKeyExistsCount(
                _originalMap,
                key,
                keyLevel: keyLevel,
              );
        breakLines.add(YamlBreakLine(
          count: count,
          lineBefore: lineBefore,
          lineKeyExistsCount: keyExistsCount,
        ));
        i = endLine; // Skip to the end of the multi line breaks comment
      }
    }

    return breakLines;
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
    if (!(await file.exists())) {
      await file.create();
    }
    final sink = file.openWrite(); // Open the file for writing

    if (_includeWatermarkComment && !_isMagicYamlCommentExists(map)) {
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
    if (await file.exists()) {
      await file.rename(originalFile.path);
    }
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    return toString();
  }

  bool _isMagicYamlCommentExists(Map map) {
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

  /// Adds a break line to the YAML file.
  ///
  /// The [breakLine] parameter specifies the break line to be added.
  void addBreakLine(YamlBreakLine breakLine) => map.addAll(breakLine.toMap());

  String _writeMapEntries(
    Map map,
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
      } else if (value is YamlBreakLine) {
        sink.write(value);
      } else {
        final indent = '  ' * level;
        sink.write(
          "$indent${arrayItemIndex > -1 && keyValueIndex == 0 ? '- ' : arrayItemIndex > -1 ? '  ' : ''}",
        );
        sink.write('$key:');
        /*print(
          'key: $key value: $value index $arrayItemIndex level: $level keyValueIndex $keyValueIndex',
        );*/
        if (value is Map) {
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
            if (item is Map) {
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

  String _formatValue(dynamic value, {int level = 0}) {
    if (value is String) {
      if (_isHashStartValue(value)) {
        return '"$value"';
      } else {
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
    }
    return value == null ? '' : value.toString();
  }

  bool _isHashStartValue(String input) {
    input = input.trim();
    return input.startsWith('#');
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
