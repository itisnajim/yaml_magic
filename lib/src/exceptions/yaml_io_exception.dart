import 'yaml_magic_exception.dart';

/// An exception thrown when a YAML I/O error occurs.
class YamlIOException extends YamlMagicException {
  final String filePath;

  const YamlIOException(this.filePath)
      : super('YAML I/O error occurred. (File: $filePath).');
}
