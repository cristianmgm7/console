//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class ContentPartsInner {
  /// Returns a new [ContentPartsInner] instance.
  ContentPartsInner({
    this.text,
    this.inlineData,
    this.functionCall,
    this.functionResponse,
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? text;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentPartsInnerOneOf1InlineData? inlineData;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentPartsInnerOneOf2FunctionCall? functionCall;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  ContentPartsInnerOneOf3FunctionResponse? functionResponse;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentPartsInner &&
          other.text == text &&
          other.inlineData == inlineData &&
          other.functionCall == functionCall &&
          other.functionResponse == functionResponse;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (text == null ? 0 : text!.hashCode) +
      (inlineData == null ? 0 : inlineData!.hashCode) +
      (functionCall == null ? 0 : functionCall!.hashCode) +
      (functionResponse == null ? 0 : functionResponse!.hashCode);

  @override
  String toString() =>
      'ContentPartsInner[text=$text, inlineData=$inlineData, functionCall=$functionCall, functionResponse=$functionResponse]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.text != null) {
      json[r'text'] = this.text;
    } else {
      json[r'text'] = null;
    }
    if (this.inlineData != null) {
      json[r'inlineData'] = this.inlineData;
    } else {
      json[r'inlineData'] = null;
    }
    if (this.functionCall != null) {
      json[r'functionCall'] = this.functionCall;
    } else {
      json[r'functionCall'] = null;
    }
    if (this.functionResponse != null) {
      json[r'functionResponse'] = this.functionResponse;
    } else {
      json[r'functionResponse'] = null;
    }
    return json;
  }

  /// Returns a new [ContentPartsInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static ContentPartsInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "ContentPartsInner[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "ContentPartsInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return ContentPartsInner(
        text: mapValueOfType<String>(json, r'text'),
        inlineData:
            ContentPartsInnerOneOf1InlineData.fromJson(json[r'inlineData']),
        functionCall:
            ContentPartsInnerOneOf2FunctionCall.fromJson(json[r'functionCall']),
        functionResponse: ContentPartsInnerOneOf3FunctionResponse.fromJson(
            json[r'functionResponse']),
      );
    }
    return null;
  }

  static List<ContentPartsInner> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentPartsInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentPartsInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, ContentPartsInner> mapFromJson(dynamic json) {
    final map = <String, ContentPartsInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = ContentPartsInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of ContentPartsInner-objects as value to a dart map
  static Map<String, List<ContentPartsInner>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<ContentPartsInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = ContentPartsInner.listFromJson(
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
