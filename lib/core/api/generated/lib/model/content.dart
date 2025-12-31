//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Content {
  /// Returns a new [Content] instance.
  Content({
    this.role,
    this.parts = const [],
  });

  /// Content role
  ContentRoleEnum? role;

  List<ContentPartsInner> parts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Content &&
          other.role == role &&
          _deepEquality.equals(other.parts, parts);

  @override
  int get hashCode =>
      // ignore: unnecessary_parenthesis
      (role == null ? 0 : role!.hashCode) + (parts.hashCode);

  @override
  String toString() => 'Content[role=$role, parts=$parts]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.role != null) {
      json[r'role'] = this.role;
    } else {
      json[r'role'] = null;
    }
    json[r'parts'] = this.parts;
    return json;
  }

  /// Returns a new [Content] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Content? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key),
              'Required key "Content[$key]" is missing from JSON.');
          assert(json[key] != null,
              'Required key "Content[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Content(
        role: ContentRoleEnum.fromJson(json[r'role']),
        parts: ContentPartsInner.listFromJson(json[r'parts']),
      );
    }
    return null;
  }

  static List<Content> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <Content>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Content.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Content> mapFromJson(dynamic json) {
    final map = <String, Content>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Content.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Content-objects as value to a dart map
  static Map<String, List<Content>> mapListFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final map = <String, List<Content>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Content.listFromJson(
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

/// Content role
class ContentRoleEnum {
  /// Instantiate a new enum with the provided [value].
  const ContentRoleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const user = ContentRoleEnum._(r'user');
  static const model = ContentRoleEnum._(r'model');

  /// List of all possible values in this [enum][ContentRoleEnum].
  static const values = <ContentRoleEnum>[
    user,
    model,
  ];

  static ContentRoleEnum? fromJson(dynamic value) =>
      ContentRoleEnumTypeTransformer().decode(value);

  static List<ContentRoleEnum> listFromJson(
    dynamic json, {
    bool growable = false,
  }) {
    final result = <ContentRoleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = ContentRoleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [ContentRoleEnum] to String,
/// and [decode] dynamic data back to [ContentRoleEnum].
class ContentRoleEnumTypeTransformer {
  factory ContentRoleEnumTypeTransformer() =>
      _instance ??= const ContentRoleEnumTypeTransformer._();

  const ContentRoleEnumTypeTransformer._();

  String encode(ContentRoleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a ContentRoleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  ContentRoleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'user':
          return ContentRoleEnum.user;
        case r'model':
          return ContentRoleEnum.model;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [ContentRoleEnumTypeTransformer] instance.
  static ContentRoleEnumTypeTransformer? _instance;
}
