/// Represents a YAML comment.
class YamlComment {
  static String key = 'COMMENT';
  final String text;
  final int linesMaxlength;
  final int indentLevel;

  /// Creates a new instance of [YamlComment].
  ///
  /// The [text] parameter specifies the comment text.
  /// The [linesMaxlength] parameter defines the maximum length of each line when splitting the comment into multiple lines.
  /// The [indentLevel] parameter specifies the level of indentation for the comment.
  const YamlComment(
    this.text, {
    this.linesMaxlength = 0,
    this.indentLevel = 0,
  });

  @override
  String toString() {
    final indent = '  ' * indentLevel;
    final lines = <String>[];

    if (linesMaxlength > 0) {
      final words = text.split(' ');
      final buffer = StringBuffer();

      for (final word in words) {
        if ((buffer.length + word.length + 1) <= linesMaxlength) {
          buffer.write('$word ');
        } else {
          lines.add(buffer.toString().trim());
          buffer.clear();
          buffer.write('$indent $word ');
        }
      }

      if (buffer.isNotEmpty) {
        lines.add(buffer.toString().trim());
      }
    } else {
      lines.add(text);
    }

    return lines.map((line) => '$indent# $line').join('\n');
  }

  /// Creates a new [YamlComment] instance with
  /// the specified properties updated.
  YamlComment copyWith({
    String? text,
    int? linesMaxlength,
    int? indentLevel,
  }) {
    return YamlComment(
      text ?? this.text,
      linesMaxlength: linesMaxlength ?? this.linesMaxlength,
      indentLevel: indentLevel ?? this.indentLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is YamlComment &&
        other.text == text &&
        other.linesMaxlength == linesMaxlength &&
        other.indentLevel == indentLevel;
  }

  @override
  int get hashCode =>
      text.hashCode ^ linesMaxlength.hashCode ^ indentLevel.hashCode;
}
