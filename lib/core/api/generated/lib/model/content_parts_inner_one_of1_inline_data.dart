//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ContentPartsInnerOneOf1InlineData {
  /// Returns a new [ContentPartsInnerOneOf1InlineData] instance.
  ContentPartsInnerOneOf1InlineData({
    this.mimeType,
    this.data,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? mimeType;

  /// Base64 encoded data
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPartsInnerOneOf1InlineData &&
          other.mimeType == mimeType &&
          other.data == data;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (mimeType == null ? 0 : mimeType!.hashCode) +
      (data == null ? 0 : data!.hashCode);

  @override
  String toString() =>
      'ContentPartsInnerOneOf1InlineData[mimeType=$mimeType, data=$data]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.mimeType != null) {
      json[r'mimeType'] = this.mimeType;
    } else {
      json[r'mimeType'] = null;
    }
    if (this.data != null) {
      json[r'data'] = this.data;
    } else {
      json[r'data'] = null;
    }
    return json;
  }

  /// Returns a new [ContentPartsInnerOneOf1InlineData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContentPartsInnerOneOf1InlineData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ContentPartsInnerOneOf1InlineData[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ContentPartsInnerOneOf1InlineData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContentPartsInnerOneOf1InlineData(
        mimeType: mapValueOfType<String>(json, r'mimeType'),
        data: mapValueOfType<String>(json, r'data'),
      );
    }
    return null;
  }

  static List<ContentPartsInnerOneOf1InlineData> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentPartsInnerOneOf1InlineData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentPartsInnerOneOf1InlineData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContentPartsInnerOneOf1InlineData> mapFromJson(
      dynamic json) {
    final map = <String, ContentPartsInnerOneOf1InlineData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContentPartsInnerOneOf1InlineData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContentPartsInnerOneOf1InlineData-objects as value to a dart map
  static Map<String, List<ContentPartsInnerOneOf1InlineData>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContentPartsInnerOneOf1InlineData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContentPartsInnerOneOf1InlineData.listFromJson(
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
