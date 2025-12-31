//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Event {
  /// Returns a new [Event] instance.
  Event({
    required this.author,
    required this.content,
    this.invocationId,
    this.actions,
    this.longRunningToolIds = const [],
    this.branch,
    this.id,
    this.timestamp,
    this.partial,
  });

  /// Author of the event ('user' or agent name)
  String author;

  Content content;

  /// Invocation ID
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? invocationId;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  EventActions? actions;

  /// IDs of long-running tool calls
  List<String> longRunningToolIds;

  /// Branch path (agent hierarchy)
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? branch;

  /// Event ID
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? id;

  /// Event timestamp
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? timestamp;

  /// Whether this is a partial response
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? partial;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          other.author == author &&
          other.content == content &&
          other.invocationId == invocationId &&
          other.actions == actions &&
          _deepEquality.equals(other.longRunningToolIds, longRunningToolIds) &&
          other.branch == branch &&
          other.id == id &&
          other.timestamp == timestamp &&
          other.partial == partial;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (author.hashCode) +
      (content.hashCode) +
      (invocationId == null ? 0 : invocationId!.hashCode) +
      (actions == null ? 0 : actions!.hashCode) +
      (longRunningToolIds.hashCode) +
      (branch == null ? 0 : branch!.hashCode) +
      (id == null ? 0 : id!.hashCode) +
      (timestamp == null ? 0 : timestamp!.hashCode) +
      (partial == null ? 0 : partial!.hashCode);

  @override
  String toString() =>
      'Event[author=$author, content=$content, invocationId=$invocationId, actions=$actions, longRunningToolIds=$longRunningToolIds, branch=$branch, id=$id, timestamp=$timestamp, partial=$partial]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'author'] = this.author;
    json[r'content'] = this.content;
    if (this.invocationId != null) {
      json[r'invocationId'] = this.invocationId;
    } else {
      json[r'invocationId'] = null;
    }
    if (this.actions != null) {
      json[r'actions'] = this.actions;
    } else {
      json[r'actions'] = null;
    }
    json[r'longRunningToolIds'] = this.longRunningToolIds;
    if (this.branch != null) {
      json[r'branch'] = this.branch;
    } else {
      json[r'branch'] = null;
    }
    if (this.id != null) {
      json[r'id'] = this.id;
    } else {
      json[r'id'] = null;
    }
    if (this.timestamp != null) {
      json[r'timestamp'] = this.timestamp;
    } else {
      json[r'timestamp'] = null;
    }
    if (this.partial != null) {
      json[r'partial'] = this.partial;
    } else {
      json[r'partial'] = null;
    }
    return json;
  }

  /// Returns a new [Event] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Event? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Event[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Event[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Event(
        author: mapValueOfType<String>(json, r'author')!,
        content: Content.fromJson(json[r'content'])!,
        invocationId: mapValueOfType<String>(json, r'invocationId'),
        actions: EventActions.fromJson(json[r'actions']),
        longRunningToolIds: json[r'longRunningToolIds'] is Iterable
            ? (json[r'longRunningToolIds'] as Iterable)
                .cast<String>()
                .toList(growable: false)
            : const [],
        branch: mapValueOfType<String>(json, r'branch'),
        id: mapValueOfType<String>(json, r'id'),
        timestamp: num.parse('${json[r'timestamp']}'),
        partial: mapValueOfType<bool>(json, r'partial'),
      );
    }
    return null;
  }

  static List<Event> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Event>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Event.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Event> mapFromJson(dynamic json) {
    final map = <String, Event>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Event.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Event-objects as value to a dart map
  static Map<String, List<Event>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Event>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Event.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'author',
    'content',
  };
}
