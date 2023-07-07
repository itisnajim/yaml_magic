# YamlMagic
[![pub package](https://img.shields.io/pub/v/yaml_magic.svg)](https://pub.dartlang.org/packages/yaml_magic) [![GitHub license](https://img.shields.io/github/license/itisnajim/yaml_magic)](https://github.com/itisnajim/yaml_magic/blob/master/LICENSE)  [![GitHub issues](https://img.shields.io/github/issues/itisnajim/yaml_magic)](https://github.com/itisnajim/yaml_magic/issues)

YamlMagic is a Dart & Flutter package that provides utilities for working with YAML files. It allows you to load, modify (edit and manipulate), and save YAML files seamlessly.

## Features

- Convert a Dart `Map` object into a YAML document as a `String`.
- Load YAML files and access their key-value pairs.
- Add or update key-value pairs in the YAML document.
- Save the changes made to the YAML file.

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  yaml_magic: ^1.0.4
```

## Usage

Import the yaml_magic package in your Dart file:

```dart
import 'package:yaml_magic/yaml_magic.dart';
```

### Loading a YAML File

To load a YAML file, use the load method of the YamlMagic class:

```dart
final yamlMagic = YamlMagic.load('path/to/file.yaml');
```

### Accessing Values

You can access the values in the YAML document using the index operator ([]). The key path in the YAML document is provided as the index:

```dart
var value = yamlMagic['key'];
```

### Modifying Values
To add or update a value in the YAML document, use the index operator ([]=):

```dart
yamlMagic['new_key'] = 'new_value';
```

### Adding Comments

Two ways to add comments to your YAML document using the `addComment` method or by nesting a `YamlComment` object within a key-value pair. 

```dart
yamlMagic.addComment(YamlComment('Comment text content here!'));
// or
yamlMagic['new_key'] = {
  ...YamlComment('Comment text content here!').toMap(),
  'foo': 'bar',
};
```

### Saving Changes

To save the changes made to the YAML document, use the save method:

```dart
await yamlMagic.save();
```

## Example

Here's a simple example that demonstrates the basic usage of the YamlMagic package:

```dart
import 'package:yaml_magic/yaml_magic.dart';

void main() async {
  final yamlMagic = YamlMagic.load('path/to/file.yaml');
  yamlMagic['new_key'] = 'new_value';
  await yamlMagic.save();
}
```

## Author

itisnajim, itisnajim@gmail.com

## License

YamlMagic is available under the MIT license. See the LICENSE file for more info.
