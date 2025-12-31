//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Session {
  /// Returns a new [Session] instance.
  Session({
    required this.id,
    required this.appName,
    required this.userId,
    this.state = const {},
    this.events = const [],
    this.lastUpdateTime,
  });

  /// Session ID
  String id;

  /// Agent/app name
  String appName;

  /// User ID
  String userId;

  /// Session state
  Map<String, Object> state;

  /// Session events
  List<Event> events;

  /// Last update timestamp
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? lastUpdateTime;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          other.id == id &&
          other.appName == appName &&
          other.userId == userId &&
          _deepEquality.equals(other.state, state) &&
          _deepEquality.equals(other.events, events) &&
          other.lastUpdateTime == lastUpdateTime;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (id.hashCode) +
      (appName.hashCode) +
      (userId.hashCode) +
      (state.hashCode) +
      (events.hashCode) +
      (lastUpdateTime == null ? 0 : lastUpdateTime!.hashCode);

  @override
  String toString() =>
      'Session[id=$id, appName=$appName, userId=$userId, state=$state, events=$events, lastUpdateTime=$lastUpdateTime]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'id'] = this.id;
    json[r'appName'] = this.appName;
    json[r'userId'] = this.userId;
    json[r'state'] = this.state;
    json[r'events'] = this.events;
    if (this.lastUpdateTime != null) {
      json[r'lastUpdateTime'] = this.lastUpdateTime;
    } else {
      json[r'lastUpdateTime'] = null;
    }
    return json;
  }

  /// Returns a new [Session] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Session? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Session[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Session[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Session(
        id: mapValueOfType<String>(json, r'id')!,
        appName: mapValueOfType<String>(json, r'appName')!,
        userId: mapValueOfType<String>(json, r'userId')!,
        state: mapCastOfType<String, Object>(json, r'state') ?? const {},
        events: Event.listFromJson(json[r'events']),
        lastUpdateTime: num.parse('${json[r'lastUpdateTime']}'),
      );
    }
    return null;
  }

  static List<Session> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Session>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Session.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Session> mapFromJson(dynamic json) {
    final map = <String, Session>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Session.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Session-objects as value to a dart map
  static Map<String, List<Session>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Session>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Session.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'id',
    'appName',
    'userId',
  };
}
