//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ContentPartsInnerOneOf1 {
  /// Returns a new [ContentPartsInnerOneOf1] instance.
  ContentPartsInnerOneOf1({
    this.inlineData,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentPartsInnerOneOf1InlineData? inlineData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPartsInnerOneOf1 && other.inlineData == inlineData;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (inlineData == null ? 0 : inlineData!.hashCode);

  @override
  String toString() => 'ContentPartsInnerOneOf1[inlineData=$inlineData]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.inlineData != null) {
      json[r'inlineData'] = this.inlineData;
    } else {
      json[r'inlineData'] = null;
    }
    return json;
  }

  /// Returns a new [ContentPartsInnerOneOf1] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContentPartsInnerOneOf1? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ContentPartsInnerOneOf1[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ContentPartsInnerOneOf1[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContentPartsInnerOneOf1(
        inlineData:
            ContentPartsInnerOneOf1InlineData.fromJson(json[r'inlineData']),
      );
    }
    return null;
  }

  static List<ContentPartsInnerOneOf1> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentPartsInnerOneOf1>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentPartsInnerOneOf1.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContentPartsInnerOneOf1> mapFromJson(dynamic json) {
    final map = <String, ContentPartsInnerOneOf1>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContentPartsInnerOneOf1.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContentPartsInnerOneOf1-objects as value to a dart map
  static Map<String, List<ContentPartsInnerOneOf1>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContentPartsInnerOneOf1>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContentPartsInnerOneOf1.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{};
}
