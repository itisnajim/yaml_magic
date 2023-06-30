import 'package:yaml_magic/yaml_magic.dart';

void main() {
  final yamlMagic = YamlMagic.load('example.yaml');
  yamlMagic['new_key'] = 'a value';
  yamlMagic.save();
}
