/// Extension methods for the [String].
extension StringExt on String {
  /// Removes the first space ' ' from the string, if any.
  /// If no space is found, the original string is returned.
  String removeFirstSpace() {
    if (contains(' ')) {
      return replaceFirst(' ', '');
    }
    return this;
  }

  /// Removes all quote marks from the string, except where within a word
  /// or where it is a apostrophe preceded by n "s" or "S" (possessive plural).
  String removeQuotes() {
    const rQuotes =
        '(?<=^|[^a-zA-Z])(\'+)|(?<=[^sS])\'+(?=\$|[^a-zA-Z])|["“”„‟’‘‛]+';
    return replaceAll(RegExp(rQuotes), '');
  }
}
