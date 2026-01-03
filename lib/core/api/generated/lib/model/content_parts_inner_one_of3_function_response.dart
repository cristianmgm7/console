//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ContentPartsInnerOneOf3FunctionResponse {
  /// Returns a new [ContentPartsInnerOneOf3FunctionResponse] instance.
  ContentPartsInnerOneOf3FunctionResponse({
    this.name,
    this.response = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  Map<String, Object> response;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPartsInnerOneOf3FunctionResponse &&
          other.name == name &&
          _deepEquality.equals(other.response, response);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name == null ? 0 : name!.hashCode) + (response.hashCode);

  @override
  String toString() =>
      'ContentPartsInnerOneOf3FunctionResponse[name=$name, response=$response]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    json[r'response'] = this.response;
    return json;
  }

  /// Returns a new [ContentPartsInnerOneOf3FunctionResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContentPartsInnerOneOf3FunctionResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ContentPartsInnerOneOf3FunctionResponse[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ContentPartsInnerOneOf3FunctionResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContentPartsInnerOneOf3FunctionResponse(
        name: mapValueOfType<String>(json, r'name'),
        response: mapCastOfType<String, Object>(json, r'response') ?? const {},
      );
    }
    return null;
  }

  static List<ContentPartsInnerOneOf3FunctionResponse> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentPartsInnerOneOf3FunctionResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentPartsInnerOneOf3FunctionResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContentPartsInnerOneOf3FunctionResponse> mapFromJson(
      dynamic json) {
    final map = <String, ContentPartsInnerOneOf3FunctionResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value =
            ContentPartsInnerOneOf3FunctionResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContentPartsInnerOneOf3FunctionResponse-objects as value to a dart map
  static Map<String, List<ContentPartsInnerOneOf3FunctionResponse>>
      mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContentPartsInnerOneOf3FunctionResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContentPartsInnerOneOf3FunctionResponse.listFromJson(
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
