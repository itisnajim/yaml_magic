import 'dart:io';
import 'package:test/test.dart';

import 'package:yaml_magic/yaml_magic.dart';

void main() {
  group('YamlMagic', () {
    // Test case for loading a YAML file
    test('Load YAML file', () {
      final path = 'test/test.yaml';
      final yamlMagic = YamlMagic.load(path);

      print('CONTENT:\n$yamlMagic');

      expect(yamlMagic.path, equals(path));
    });

    test('Load and Write YAML file', () async {
      final path = 'test/test.yaml';
      final yamlMagic = YamlMagic.load(path);

      await yamlMagic.save();
      expect(yamlMagic.path, equals(path));
    });

    // Test case for saving a YAML file
    test('Save YAML file', () async {
      // Create a temporary file for testing
      final path = 'test/test.yaml';
      final yml = File(path);
      yml.createSync();

      final yamlMagic = YamlMagic.load(path);

      // Modify the YAML object or add key-value pairs
      yamlMagic.map = {
        "key1": "value1",
        "key2": {
          "foo": "bar",
          "baz": {
            "tar": 123,
            "description": '''
This is a multiline string.
It spans across multiple lines.
It can contain line breaks and indentation.
'''
          },
          "qux": [
            42,
            {
              "country": "Morocco",
              ...YamlComment(
                "A Magician who turns lines of code into mesmerizing software\nsolutions with a wave of their hand.",
              ).toMap(),
              "devs": ["itisnajim"],
              "description": '''
This is a multiline string.
It spans across multiple lines.
It can contain line breaks and indentation.
'''
            },
            94,
            "yolo",
          ],
          "test": null,
        },
        "key3": [
          {
            "name": "John Doe",
            "age": 30,
            "address": {
              "street": "123 Main St",
              "city": "New York",
              "slogan": "The city that never sleeps.",
            }
          },
          {
            "name": "Jane Smith",
            "age": 28,
            "address": {
              "street": "456 Elm St",
              "city": "Los Angeles",
              "area": [
                "Hollywood",
                "Beverly Hills",
                "Santa Monica",
                "Venice Beach",
              ],
              "slogan": "The entertainment capital",
            }
          }
        ],
        "key4": {
          "list1": [1, 2, 3],
          "list2": [4, 5, 6],
          "list3": [7, 8, 9],
        },
        ...YamlComment(
          "Last Comment in this Yaml file.",
        ).toMap(),
      };

      // Save the YAML file
      final output = await yamlMagic.save();
      print('YamlMagic output: \n$output');

      // Verify that the file is saved successfully
      final savedFile = File(path);
      expect(savedFile.existsSync(), isTrue);
    });
  });
}
