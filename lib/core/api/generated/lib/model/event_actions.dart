//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class EventActions {
  /// Returns a new [EventActions] instance.
  EventActions({
    this.functionCalls = const [],
    this.functionResponses = const [],
    this.skipSummarization,
  });

  List<EventActionsFunctionCallsInner> functionCalls;

  List<EventActionsFunctionResponsesInner> functionResponses;

  /// Whether to skip summarization
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? skipSummarization;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventActions &&
          _deepEquality.equals(other.functionCalls, functionCalls) &&
          _deepEquality.equals(other.functionResponses, functionResponses) &&
          other.skipSummarization == skipSummarization;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (functionCalls.hashCode) +
      (functionResponses.hashCode) +
      (skipSummarization == null ? 0 : skipSummarization!.hashCode);

  @override
  String toString() =>
      'EventActions[functionCalls=$functionCalls, functionResponses=$functionResponses, skipSummarization=$skipSummarization]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'functionCalls'] = this.functionCalls;
    json[r'functionResponses'] = this.functionResponses;
    if (this.skipSummarization != null) {
      json[r'skipSummarization'] = this.skipSummarization;
    } else {
      json[r'skipSummarization'] = null;
    }
    return json;
  }

  /// Returns a new [EventActions] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static EventActions? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "EventActions[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "EventActions[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return EventActions(
        functionCalls:
            EventActionsFunctionCallsInner.listFromJson(json[r'functionCalls']),
        functionResponses: EventActionsFunctionResponsesInner.listFromJson(
            json[r'functionResponses']),
        skipSummarization: mapValueOfType<bool>(json, r'skipSummarization'),
      );
    }
    return null;
  }

  static List<EventActions> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <EventActions>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = EventActions.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, EventActions> mapFromJson(dynamic json) {
    final map = <String, EventActions>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = EventActions.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of EventActions-objects as value to a dart map
  static Map<String, List<EventActions>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<EventActions>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = EventActions.listFromJson(
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
