## 1.0.4

- Add retrieve comments support. When loading YAML content (using `YamlMagic.fromString` or `YamlMagic.load`), the package YamlMagic now has the ability to retrieve comments from the YAML content.

- Add retrieve break lines support. When loading YAML content (using `YamlMagic.fromString` or `YamlMagic.load`), the package YamlMagic now has the ability to retrieve break lines from the YAML content.

## 1.0.3+2

- Add support for multiline strings in YAML conversion. example:
```yaml
description: |-
  This is a multiline string.
  It spans across multiple lines.
  It can contain line breaks and indentation.
```

## 1.0.2

- Add `toString` method to get the output string without writing any yaml file (without calling `save` method).

## 1.0.1+2

- Make `YamlComment` `indentLevel` property controlable.

## 1.0.1+1

- Update package pubspec.yaml description (it was too short) and the version to 1.0.1+1

## 1.0.1

- Added the ability to add comments to the YAML file using the addComment method in the YamlMagic class.

## 1.0.0

- Initial version.
