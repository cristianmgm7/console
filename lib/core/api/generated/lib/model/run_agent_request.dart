//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class RunAgentRequest {
  /// Returns a new [RunAgentRequest] instance.
  RunAgentRequest({
    required this.appName,
    required this.userId,
    required this.sessionId,
    required this.newMessage,
    this.streaming = false,
    this.stateDelta = const {},
    this.invocationId,
  });

  /// Agent/app name
  String appName;

  /// User ID
  String userId;

  /// Session ID
  String sessionId;

  Content newMessage;

  /// Whether to use streaming response
  bool streaming;

  /// State changes to apply
  Map<String, Object> stateDelta;

  /// Invocation ID for resuming long-running functions
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? invocationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunAgentRequest &&
          other.appName == appName &&
          other.userId == userId &&
          other.sessionId == sessionId &&
          other.newMessage == newMessage &&
          other.streaming == streaming &&
          _deepEquality.equals(other.stateDelta, stateDelta) &&
          other.invocationId == invocationId;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (appName.hashCode) +
      (userId.hashCode) +
      (sessionId.hashCode) +
      (newMessage.hashCode) +
      (streaming.hashCode) +
      (stateDelta.hashCode) +
      (invocationId == null ? 0 : invocationId!.hashCode);

  @override
  String toString() =>
      'RunAgentRequest[appName=$appName, userId=$userId, sessionId=$sessionId, newMessage=$newMessage, streaming=$streaming, stateDelta=$stateDelta, invocationId=$invocationId]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json[r'appName'] = this.appName;
    json[r'userId'] = this.userId;
    json[r'sessionId'] = this.sessionId;
    json[r'newMessage'] = this.newMessage;
    json[r'streaming'] = this.streaming;
    json[r'stateDelta'] = this.stateDelta;
    if (this.invocationId != null) {
      json[r'invocationId'] = this.invocationId;
    } else {
      json[r'invocationId'] = null;
    }
    return json;
  }

  /// Returns a new [RunAgentRequest] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static RunAgentRequest? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "RunAgentRequest[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "RunAgentRequest[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return RunAgentRequest(
        appName: mapValueOfType<String>(json, r'appName')!,
        userId: mapValueOfType<String>(json, r'userId')!,
        sessionId: mapValueOfType<String>(json, r'sessionId')!,
        newMessage: Content.fromJson(json[r'newMessage'])!,
        streaming: mapValueOfType<bool>(json, r'streaming') ?? false,
        stateDelta:
            mapCastOfType<String, Object>(json, r'stateDelta') ?? const {},
        invocationId: mapValueOfType<String>(json, r'invocationId'),
      );
    }
    return null;
  }

  static List<RunAgentRequest> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <RunAgentRequest>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RunAgentRequest.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, RunAgentRequest> mapFromJson(dynamic json) {
    final map = <String, RunAgentRequest>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = RunAgentRequest.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of RunAgentRequest-objects as value to a dart map
  static Map<String, List<RunAgentRequest>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<RunAgentRequest>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = RunAgentRequest.listFromJson(
          entry.value,
          growable: growable,
        );
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'appName',
    'userId',
    'sessionId',
    'newMessage',
  };
}
