//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class AppInfo {
  /// Returns a new [AppInfo] instance.
  AppInfo({
    this.name,
    this.rootAgentName,
    this.description,
    this.language,
  });

  /// Agent name
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? name;

  /// Root agent name
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? rootAgentName;

  /// Agent description
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? description;

  /// Agent language/format
  AppInfoLanguageEnum? language;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          other.name == name &&
          other.rootAgentName == rootAgentName &&
          other.description == description &&
          other.language == language;

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (name == null ? 0 : name!.hashCode) +
      (rootAgentName == null ? 0 : rootAgentName!.hashCode) +
      (description == null ? 0 : description!.hashCode) +
      (language == null ? 0 : language!.hashCode);

  @override
  String toString() =>
      'AppInfo[name=$name, rootAgentName=$rootAgentName, description=$description, language=$language]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.name != null) {
      json[r'name'] = this.name;
    } else {
      json[r'name'] = null;
    }
    if (this.rootAgentName != null) {
      json[r'rootAgentName'] = this.rootAgentName;
    } else {
      json[r'rootAgentName'] = null;
    }
    if (this.description != null) {
      json[r'description'] = this.description;
    } else {
      json[r'description'] = null;
    }
    if (this.language != null) {
      json[r'language'] = this.language;
    } else {
      json[r'language'] = null;
    }
    return json;
  }

  /// Returns a new [AppInfo] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static AppInfo? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "AppInfo[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "AppInfo[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return AppInfo(
        name: mapValueOfType<String>(json, r'name'),
        rootAgentName: mapValueOfType<String>(json, r'rootAgentName'),
        description: mapValueOfType<String>(json, r'description'),
        language: AppInfoLanguageEnum.fromJson(json[r'language']),
      );
    }
    return null;
  }

  static List<AppInfo> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AppInfo>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppInfo.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, AppInfo> mapFromJson(dynamic json) {
    final map = <String, AppInfo>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = AppInfo.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of AppInfo-objects as value to a dart map
  static Map<String, List<AppInfo>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<AppInfo>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = AppInfo.listFromJson(
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

/// Agent language/format
class AppInfoLanguageEnum {
  /// Instantiate a new enum with the provided [value].
  const AppInfoLanguageEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const yaml = AppInfoLanguageEnum._(r'yaml');
  static const python = AppInfoLanguageEnum._(r'python');

  /// List of all possible values in this [enum][AppInfoLanguageEnum].
  static const values = <AppInfoLanguageEnum>[
    yaml,
    python,
  ];

  static AppInfoLanguageEnum? fromJson(dynamic value) =>
      AppInfoLanguageEnumTypeTransformer().decode(value);

  static List<AppInfoLanguageEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <AppInfoLanguageEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = AppInfoLanguageEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [AppInfoLanguageEnum] to String,
/// and [decode] dynamic data back to [AppInfoLanguageEnum].
class AppInfoLanguageEnumTypeTransformer {
  factory AppInfoLanguageEnumTypeTransformer() =>
      _instance ??= const AppInfoLanguageEnumTypeTransformer._();

  const AppInfoLanguageEnumTypeTransformer._();

  String encode(AppInfoLanguageEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a AppInfoLanguageEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  AppInfoLanguageEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'yaml':
          return AppInfoLanguageEnum.yaml;
        case r'python':
          return AppInfoLanguageEnum.python;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [AppInfoLanguageEnumTypeTransformer] instance.
  static AppInfoLanguageEnumTypeTransformer? _instance;
}
