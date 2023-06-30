import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

import 'package:yaml_magic/yaml_magic.dart';

void main() {
  group('YamlMagic', () {
    // Test case for loading a YAML file
    test('Load YAML file', () {
      final currentDirectory = '${Directory.current.path}/test/';
      const ymlName = 'test.yaml';
      final ymlPath = path.join(currentDirectory, ymlName);

      final yamlMagic = YamlMagic.load(ymlPath);

      expect(yamlMagic.path, equals(ymlPath));
    });

    // Test case for saving a YAML file
    test('Save YAML file', () async {
      // Create a temporary file for testing
      final currentDirectory = '${Directory.current.path}/test/';
      const ymlName = 'test.yaml';
      final ymlPath = path.join(currentDirectory, ymlName);

      final yml = File(ymlPath);
      yml.createSync();

      final yamlMagic = YamlMagic.load(ymlPath);

      // Modify the YAML object or add key-value pairs
      yamlMagic.map = {
        'key1': 'value1',
        'key2': {
          'foo': 'bar',
          'baz': {'tar': 123},
          'qux': [
            42,
            {
              'country': 'Morocco',
              'devs': ['itisnajim', 'itisnajim']
            },
            94,
            'yolo',
          ],
          'test': null,
        },
        'key3': [
          {
            'name': 'John Doe',
            'age': 30,
            'address': {'street': '123 Main St', 'city': 'New York'}
          },
          {
            'name': 'Jane Smith',
            'age': 28,
            'address': {'street': '456 Elm St', 'city': 'Los Angeles'}
          }
        ],
        'key4': {
          'list1': [1, 2, 3],
          'list2': [4, 5, 6],
          'list3': [7, 8, 9],
        }
      };

      // Save the YAML file
      await yamlMagic.save();

      // Verify that the file is saved successfully
      final savedFile = File(ymlPath);
      expect(savedFile.existsSync(), isTrue);
    });
  });
}
