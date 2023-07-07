import 'dart:math' show Random;

/// Represents a YAML comment.
class YamlComment {
  final String text;
  final int indentLevel;
  final String? lineAfter;
  final int lineKeyExistsCount;

  String get key =>
      '__comment_${Random().nextInt(100)}_${DateTime.now().millisecondsSinceEpoch}';

  /// Creates a new instance of [YamlComment].
  ///
  /// The [text] parameter specifies the comment text.
  /// The [indentLevel] parameter specifies the level of indentation for the comment.
  /// **Ignore this property**: The [lineAfter] property is used by the YamlMagic package to calculate and define the position of this comment.
  /// **Ignore this property**: The [lineKeyExistsCount] property is used by the YamlMagic package to calculate and define the position of this comment.
  ///
  const YamlComment(
    this.text, {
    this.indentLevel = 0,
    this.lineAfter,
    this.lineKeyExistsCount = 1,
  });

  @override
  String toString() {
    final indent = '  ' * indentLevel;
    return text
        .split('\n')
        .map((line) => '$indent# $line')
        .join('\n')
        .trimRight();
  }

  Map<String, YamlComment> toMap() => {key: this};

  /// Creates a new [YamlComment] instance with
  /// the specified properties updated.
  YamlComment copyWith({
    String? text,
    int? indentLevel,
    String? lineAfter,
    int? lineKeyExistsCount,
  }) {
    return YamlComment(
      text ?? this.text,
      indentLevel: indentLevel ?? this.indentLevel,
      lineAfter: lineAfter ?? this.lineAfter,
      lineKeyExistsCount: lineKeyExistsCount ?? this.lineKeyExistsCount,
    );
  }

  String? get lineKey => lineAfter == null ? null : getKeyFromLine(lineAfter!);

  /// Retrieve a yaml key string from [line].
  static String? getKeyFromLine(String line) {
    final trimmedLine = line.trim();
    final indexOfColon = trimmedLine.indexOf(':');
    if (indexOfColon != -1) {
      String lineSubstring = trimmedLine.substring(0, indexOfColon).trim();
      if (lineSubstring.startsWith('- ')) {
        lineSubstring = lineSubstring.substring(2);
      }
      return lineSubstring;
    }
    return null;
  }

  String? get lineValue {
    if (lineAfter != null) {
      final trimmedLine = lineAfter!.trim();
      final indexOfColon = trimmedLine.indexOf(':');
      if (indexOfColon != -1) {
        return trimmedLine.substring(indexOfColon + 1).trim();
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is YamlComment &&
        other.text == text &&
        other.indentLevel == indentLevel &&
        other.lineAfter == lineAfter &&
        other.lineKeyExistsCount == lineKeyExistsCount;
  }

  @override
  int get hashCode =>
      text.hashCode ^
      indentLevel.hashCode ^
      lineAfter.hashCode ^
      lineKeyExistsCount.hashCode;
}
