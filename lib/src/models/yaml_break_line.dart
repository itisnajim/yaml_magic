import 'dart:math' show Random;

import '../exceptions/exceptions.dart';

/// Represents a YAML break line.
class YamlBreakLine {
  final int count;
  final String? lineBefore;
  final int lineKeyExistsCount;

  String get key =>
      '__breakline_${Random().nextInt(100)}_${DateTime.now().millisecondsSinceEpoch}';

  /// Creates a new instance of [YamlBreakLine].
  ///
  /// **Ignore this property**: The [lineBefore] property is used by the YamlMagic package to calculate and define the position of this break line.
  /// **Ignore this property**: The [lineKeyExistsCount] property is used by the YamlMagic package to calculate and define the position of this break line.
  ///
  YamlBreakLine({
    this.count = 1,
    this.lineBefore,
    this.lineKeyExistsCount = 1,
  }) {
    if (count < 1) {
      throw YamlMagicException('Invalid count for YamlBreakLine');
    }
  }

  @override
  String toString() {
    return '\n' * count;
  }

  Map<String, YamlBreakLine> toMap() => {key: this};

  bool get isLineBeforeComment => (lineBefore ?? '').trimLeft().startsWith('#');

  String? get lineKey =>
      lineBefore == null ? null : getKeyFromLine(lineBefore!);

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
    if (lineBefore != null) {
      final trimmedLine = lineBefore!.trim();
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

    return other is YamlBreakLine &&
        other.count == count &&
        other.lineBefore == lineBefore;
  }

  @override
  int get hashCode => count.hashCode ^ lineBefore.hashCode;
}
