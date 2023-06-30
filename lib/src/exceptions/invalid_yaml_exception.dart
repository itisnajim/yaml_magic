import 'yaml_magic_exception.dart';

/// An exception thrown when invalid YAML is encountered.
class InvalidYamlException extends YamlMagicException {
  const InvalidYamlException() : super('Invalid YAML found.');
}
