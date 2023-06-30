/// A custom exception class for YamlMagic-related exceptions.
class YamlMagicException implements Exception {
  final String message;

  const YamlMagicException(this.message);

  @override
  String toString() {
    return '$runtimeType: $message';
  }
}
