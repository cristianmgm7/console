# Workspace V3 API Migration Implementation Plan

## Overview

Migrate the Workspace feature from the legacy `/workspaces` endpoint to the new `/v3/workspaces` API. This migration addresses critical technical debt by eliminating DTO normalization logic, enforcing API contract compliance through non-nullable fields, and restructuring the domain layer to use value objects for conceptual groupings.

## Current State Analysis

### What Exists Now

**Endpoint**: `/workspaces` (legacy, non-versioned)

**DTOs** ([lib/features/workspaces/data/models/api/](lib/features/workspaces/data/models/api/)):
- `WorkspaceDto` - Has all fields but uses `fromApiJson` normalization factory (lines 105-193)
- `WorkspaceUserDto` - Has `fromApiJson` normalization
- `WorkspacePhoneDto` - Has `fromApiJson` normalization
- `WorkspaceSettingDto` - Simple, but `reason` is `String` (should be enum in domain)

**Problematic Pattern**:
```dart
// Current anti-pattern: Heavy normalization in DTO layer
factory WorkspaceDto.fromApiJson(Map<String, dynamic> json) {
  final normalized = Map<String, dynamic>.from(json);
  // 90+ lines of field aliasing and transformation
  normalized['_id'] ??= json['workspace_guid'] ?? json['_id'] ?? json['id'];
  // ... dozens more normalizations
  return _$WorkspaceDtoFromJson(normalized);
}
```

**All fields are nullable**: `String?`, `DateTime?`, `List<X>?` everywhere - silent failures instead of contract enforcement.

**Entity** ([lib/features/workspaces/domain/entities/workspace.dart](lib/features/workspaces/domain/entities/workspace.dart:1)):
- Has basic fields but missing: SSO, SCIM, retention policy details, domain referral
- Retention fields are flat primitives, not grouped conceptually
- Domain referral fields are missing entirely

**Mapper** ([lib/features/workspaces/data/mappers/workspace_dto_mapper.dart](lib/features/workspaces/data/mappers/workspace_dto_mapper.dart:1)):
- Converts DTO → Entity but allows silent failures (skips invalid nested items)

### Key Discoveries

1. **fromApiJson is normalization disguised as parsing** - violates DTO contract
2. **Nullable fields hide API contract violations** - silent corruption
3. **No value objects** - retention and domain referral are flat fields
4. **No v3 endpoint integration** - still using legacy API
5. **Settings reason field** - String instead of enum (no type safety)

## Desired End State

After this migration:

1. ✅ **V3 Endpoint**: New methods using `/v3/workspaces`
2. ✅ **Parallel Implementation**: Keep legacy endpoint working during migration
3. ✅ **Clean V3 DTOs**: No normalization, exact API schema match
4. ✅ **Required Fields**: Non-nullable core fields in V3 DTOs (fail fast on contract violations)
5. ✅ **Value Objects**: `RetentionPolicy` and `DomainReferral` in domain layer
6. ✅ **Setting Reason Enum**: Type-safe enum with `unknown` fallback
7. ✅ **Enhanced Entity**: All V3 fields mapped to domain concepts
8. ✅ **Intelligent Mapper**: The only place where transformation logic lives

### Verification

#### Automated Verification:
- [ ] Build succeeds: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No compilation errors: `flutter analyze`
- [ ] Type checking passes: `dart analyze lib/features/workspaces/`
- [ ] Tests pass (if they exist): `flutter test`

#### Manual Verification:
- [ ] V3 endpoint successfully fetches workspaces
- [ ] All workspace fields are populated correctly
- [ ] Value objects (RetentionPolicy, DomainReferral) work as expected
- [ ] Legacy endpoint still works for backwards compatibility
- [ ] No silent failures on malformed API responses

## What We're NOT Doing

- NOT removing the legacy `/workspaces` endpoint implementation
- NOT adding new UI features (UI can be updated separately)
- NOT changing the repository interface contract
- NOT modifying workspace selection or filtering logic
- NOT implementing workspace creation/editing
- NOT adding new API methods beyond fetch operations
- NOT removing existing enums or changing their values
- NOT changing the BLoC layer contracts

## Implementation Approach

This is a **parallel migration strategy**:
1. Create new V3-specific DTOs alongside existing ones
2. Add new repository methods for V3 endpoint
3. Create value objects for domain layer
4. Update entity to support all V3 fields
5. Allow consumers to opt-in to V3 gradually
6. Keep legacy implementation untouched

### Architectural Boundaries

**DTO Layer (Transport)**:
- Flat fields exactly matching API schema
- Non-nullable required fields (fail loudly on contract violations)
- Strings for enum-like values (API owns the values)
- No normalization, no intelligence
- New files: `*_v3.dart` to avoid conflicts

**Domain Layer (Business Logic)**:
- Value objects for conceptual groupings
- Enums with `unknown` fallback for type safety
- Rich entity with all fields needed for business logic
- Helper methods for workspace categorization

**Mapper Layer (Translation)**:
- String → Enum conversion
- Flat fields → Value object construction
- Default/fallback logic when safe to do so
- The only place where transformation happens

---

## Phase 1: Create V3 DTOs and Supporting Enums

### Overview

Create clean V3 DTOs that exactly match the API schema with no normalization. Add new enum for `WorkspaceSettingReason`. Create value object structures for domain layer.

### Changes Required

#### 1. Create WorkspaceSettingReason Enum

**File**: `lib/features/workspaces/domain/entities/workspace_enums.dart`

**Changes**: Add new enum after existing enums (line 194+)

```dart
/// Workspace setting reason (why a setting has a particular value)
enum WorkspaceSettingReason {
  /// Limited by system constraints
  systemLimitation('system_limitation'),

  /// Set by user preference
  userPreference('user_preference'),

  /// Unknown or unrecognized reason
  unknown('unknown');

  const WorkspaceSettingReason(this.value);
  final String value;

  static WorkspaceSettingReason fromString(String? value) {
    if (value == null) return WorkspaceSettingReason.unknown;
    return WorkspaceSettingReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceSettingReason.unknown,
    );
  }
}
```

#### 2. Create V3 WorkspaceSettingDto

**File**: `lib/features/workspaces/data/models/api/workspace_setting_v3_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_setting_v3_dto.g.dart';

/// V3 DTO for workspace setting value from API response
@JsonSerializable()
class WorkspaceSettingV3Dto {
  const WorkspaceSettingV3Dto({
    required this.value,
    required this.reason,
  });

  factory WorkspaceSettingV3Dto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceSettingV3DtoFromJson(json);

  final bool value;
  final String reason;

  Map<String, dynamic> toJson() => _$WorkspaceSettingV3DtoToJson(this);
}
```

#### 3. Create V3 WorkspaceUserDto

**File**: `lib/features/workspaces/data/models/api/workspace_user_v3_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_user_v3_dto.g.dart';

/// V3 DTO for workspace user from API response
@JsonSerializable()
class WorkspaceUserV3Dto {
  const WorkspaceUserV3Dto({
    required this.userId,
    required this.role,
    required this.statusChangedAt,
    required this.status,
  });

  factory WorkspaceUserV3Dto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceUserV3DtoFromJson(json);

  @JsonKey(name: 'user_id')
  final String userId;

  final String role;

  @JsonKey(name: 'status_changed_at')
  final DateTime statusChangedAt;

  final String status;

  Map<String, dynamic> toJson() => _$WorkspaceUserV3DtoToJson(this);
}
```

#### 4. Create V3 WorkspacePhoneDto

**File**: `lib/features/workspaces/data/models/api/workspace_phone_v3_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_phone_v3_dto.g.dart';

/// V3 DTO for workspace phone from API response
@JsonSerializable()
class WorkspacePhoneV3Dto {
  const WorkspacePhoneV3Dto({
    required this.id,
    required this.destinationWorkspaceId,
    required this.number,
    required this.parentPhone,
    required this.type,
    required this.label,
    required this.messageUrl,
    required this.phoneSid,
  });

  factory WorkspacePhoneV3Dto.fromJson(Map<String, dynamic> json) =>
      _$WorkspacePhoneV3DtoFromJson(json);

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'destination_workspace_id')
  final String destinationWorkspaceId;

  final String number;

  @JsonKey(name: 'parent_phone')
  final String parentPhone;

  final String type;

  final String label;

  @JsonKey(name: 'message_url')
  final String messageUrl;

  @JsonKey(name: 'phone_sid')
  final String phoneSid;

  Map<String, dynamic> toJson() => _$WorkspacePhoneV3DtoToJson(this);
}
```

#### 5. Create V3 WorkspaceDto with Custom Converters

**File**: `lib/features/workspaces/data/models/api/workspace_v3_dto.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_v3_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_v3_dto.g.dart';

// Custom converter for WorkspaceUserV3Dto list
class WorkspaceUserV3ListConverter
    implements JsonConverter<List<WorkspaceUserV3Dto>, List<dynamic>> {
  const WorkspaceUserV3ListConverter();

  @override
  List<WorkspaceUserV3Dto> fromJson(List<dynamic> json) {
    return json
        .map((item) => WorkspaceUserV3Dto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<WorkspaceUserV3Dto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for WorkspacePhoneV3Dto list
class WorkspacePhoneV3ListConverter
    implements JsonConverter<List<WorkspacePhoneV3Dto>, List<dynamic>> {
  const WorkspacePhoneV3ListConverter();

  @override
  List<WorkspacePhoneV3Dto> fromJson(List<dynamic> json) {
    return json
        .map((item) => WorkspacePhoneV3Dto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<WorkspacePhoneV3Dto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for settings map
class WorkspaceSettingsV3Converter
    implements JsonConverter<Map<String, WorkspaceSettingV3Dto>, Map<String, dynamic>> {
  const WorkspaceSettingsV3Converter();

  @override
  Map<String, WorkspaceSettingV3Dto> fromJson(Map<String, dynamic> json) {
    return json.map(
      (key, value) => MapEntry(
        key,
        WorkspaceSettingV3Dto.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson(Map<String, WorkspaceSettingV3Dto> object) =>
      object.map((key, value) => MapEntry(key, value.toJson()));
}

/// V3 DTO for workspace from API response - EXACT schema match, no normalization
@JsonSerializable()
class WorkspaceV3Dto {
  const WorkspaceV3Dto({
    required this.id,
    required this.vanityName,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.planType,
    required this.users,
    required this.settings,
    required this.phones,
    required this.backgroundColor,
    required this.watermarkImageUrl,
    required this.conversationDefault,
    required this.invitationMode,
    required this.ssoEmailDomain,
    required this.scimProvider,
    required this.scimConnectionName,
    required this.isRetentionEnabled,
    required this.retentionDays,
    required this.whoCanChangeConversationRetention,
    required this.whoCanMarkMessagesAsPreserved,
    required this.retentionDaysAsyncMeeting,
    required this.domainReferralMode,
    required this.domainReferralMessage,
    required this.domainReferralTitle,
    required this.domains,
  });

  factory WorkspaceV3Dto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceV3DtoFromJson(json);

  @JsonKey(name: '_id')
  final String id;

  @JsonKey(name: 'vanity_name')
  final String vanityName;

  final String name;

  final String description;

  @JsonKey(name: 'image_url')
  final String imageUrl;

  final String type;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime lastUpdatedAt;

  @JsonKey(name: 'plan_type')
  final String planType;

  @WorkspaceUserV3ListConverter()
  final List<WorkspaceUserV3Dto> users;

  @WorkspaceSettingsV3Converter()
  final Map<String, WorkspaceSettingV3Dto> settings;

  @WorkspacePhoneV3ListConverter()
  final List<WorkspacePhoneV3Dto> phones;

  @JsonKey(name: 'background_color')
  final String backgroundColor;

  @JsonKey(name: 'watermark_image_url')
  final String watermarkImageUrl;

  @JsonKey(name: 'conversation_default')
  final bool conversationDefault;

  @JsonKey(name: 'invitation_mode')
  final String invitationMode;

  @JsonKey(name: 'sso_email_domain')
  final String ssoEmailDomain;

  @JsonKey(name: 'scim_provider')
  final String scimProvider;

  @JsonKey(name: 'scim_connection_name')
  final String scimConnectionName;

  @JsonKey(name: 'is_retention_enabled')
  final bool isRetentionEnabled;

  @JsonKey(name: 'retention_days')
  final int retentionDays;

  @JsonKey(name: 'who_can_change_conversation_retention')
  final List<String> whoCanChangeConversationRetention;

  @JsonKey(name: 'who_can_mark_messages_as_preserved')
  final List<String> whoCanMarkMessagesAsPreserved;

  @JsonKey(name: 'retention_days_async_meeting')
  final int retentionDaysAsyncMeeting;

  @JsonKey(name: 'domain_referral_mode')
  final String domainReferralMode;

  @JsonKey(name: 'domain_referral_message')
  final String domainReferralMessage;

  @JsonKey(name: 'domain_referral_title')
  final String domainReferralTitle;

  final List<String> domains;

  Map<String, dynamic> toJson() => _$WorkspaceV3DtoToJson(this);
}
```

### Success Criteria

#### Automated Verification:
- [ ] All V3 DTO files compile: `dart analyze lib/features/workspaces/data/models/api/`
- [ ] Enum compiles: `dart analyze lib/features/workspaces/domain/entities/workspace_enums.dart`
- [ ] No syntax errors in any new files

#### Manual Verification:
- [ ] All V3 DTOs have required (non-nullable) fields
- [ ] No `fromApiJson` factory methods exist in V3 DTOs
- [ ] Field names exactly match API schema with `@JsonKey` annotations
- [ ] Custom converters follow the established pattern
- [ ] WorkspaceSettingReason enum has `unknown` fallback

---

## Phase 2: Create Domain Value Objects

### Overview

Create value objects to group related fields conceptually in the domain layer. These represent business concepts that the API returns as flat fields.

### Changes Required

#### 1. Create RetentionPolicy Value Object

**File**: `lib/features/workspaces/domain/entities/retention_policy.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain value object representing workspace retention policy configuration
class RetentionPolicy extends Equatable {
  const RetentionPolicy({
    required this.isEnabled,
    required this.retentionDays,
    required this.retentionDaysAsyncMeeting,
    required this.whoCanChangeConversationRetention,
    required this.whoCanMarkMessagesAsPreserved,
  });

  /// Whether retention is enabled for this workspace
  final bool isEnabled;

  /// Number of days to retain standard messages
  final int retentionDays;

  /// Number of days to retain async meeting messages
  final int retentionDaysAsyncMeeting;

  /// User roles that can change conversation retention settings
  final List<WorkspaceUserRole> whoCanChangeConversationRetention;

  /// User roles that can mark messages as preserved
  final List<WorkspaceUserRole> whoCanMarkMessagesAsPreserved;

  /// Factory for disabled retention policy
  factory RetentionPolicy.disabled() {
    return const RetentionPolicy(
      isEnabled: false,
      retentionDays: 0,
      retentionDaysAsyncMeeting: 0,
      whoCanChangeConversationRetention: [],
      whoCanMarkMessagesAsPreserved: [],
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        retentionDays,
        retentionDaysAsyncMeeting,
        whoCanChangeConversationRetention,
        whoCanMarkMessagesAsPreserved,
      ];
}
```

#### 2. Create DomainReferral Value Object

**File**: `lib/features/workspaces/domain/entities/domain_referral.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain value object representing workspace domain referral configuration
class DomainReferral extends Equatable {
  const DomainReferral({
    required this.mode,
    required this.message,
    required this.title,
    required this.domains,
  });

  /// How to handle domain referrals
  final DomainReferralMode mode;

  /// Message to display for domain referrals
  final String message;

  /// Title for domain referral notifications
  final String title;

  /// List of domains associated with this workspace
  final List<String> domains;

  /// Factory for default (no referral) configuration
  factory DomainReferral.none() {
    return const DomainReferral(
      mode: DomainReferralMode.doNotInform,
      message: '',
      title: '',
      domains: [],
    );
  }

  @override
  List<Object?> get props => [mode, message, title, domains];
}
```

#### 3. Create WorkspaceSetting Domain Entity

**File**: `lib/features/workspaces/domain/entities/workspace_setting.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for a workspace setting with typed reason
class WorkspaceSetting extends Equatable {
  const WorkspaceSetting({
    required this.value,
    required this.reason,
  });

  final bool value;
  final WorkspaceSettingReason reason;

  @override
  List<Object?> get props => [value, reason];
}
```

### Success Criteria

#### Automated Verification:
- [ ] Value object files compile: `dart analyze lib/features/workspaces/domain/entities/`
- [ ] No import errors
- [ ] Equatable props are correctly defined

#### Manual Verification:
- [ ] Value objects are immutable (all fields final)
- [ ] Factory methods provide sensible defaults
- [ ] No business logic beyond data holding
- [ ] Equatable comparison works correctly

---

## Phase 3: Update Domain Entity with Value Objects

### Overview

Update the Workspace entity to use value objects for grouped concepts and include all V3 API fields.

### Changes Required

#### 1. Update Workspace Entity

**File**: `lib/features/workspaces/domain/entities/workspace.dart`

**Changes**: Add imports and update Workspace class

Add imports at top:
```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/retention_policy.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/domain_referral.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_setting.dart';
```

Update the Workspace class (replace lines 58-169):
```dart
/// Domain entity representing a workspace
class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    required this.type,
    required this.planType,
    required this.createdAt,
    this.vanityName,
    this.description,
    this.imageUrl,
    this.lastUpdatedAt,
    this.users = const [],
    this.phones = const [],
    this.settings = const {},
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.ssoEmailDomain,
    this.scimProvider,
    this.scimConnectionName,
    RetentionPolicy? retentionPolicy,
    DomainReferral? domainReferral,
  })  : retentionPolicy = retentionPolicy ?? const RetentionPolicy(
          isEnabled: false,
          retentionDays: 0,
          retentionDaysAsyncMeeting: 0,
          whoCanChangeConversationRetention: [],
          whoCanMarkMessagesAsPreserved: [],
        ),
        domainReferral = domainReferral ?? const DomainReferral(
          mode: DomainReferralMode.doNotInform,
          message: '',
          title: '',
          domains: [],
        );

  final String id;
  final String name;
  final WorkspaceType type;
  final PlanType planType;
  final DateTime createdAt;
  final String? vanityName;
  final String? description;
  final String? imageUrl;
  final DateTime? lastUpdatedAt;
  final List<WorkspaceUser> users;
  final List<WorkspacePhone> phones;
  final Map<String, WorkspaceSetting> settings;
  final String? backgroundColor;
  final String? watermarkImageUrl;
  final bool? conversationDefault;
  final InvitationMode? invitationMode;

  // SSO/SCIM fields
  final String? ssoEmailDomain;
  final String? scimProvider;
  final String? scimConnectionName;

  // Value objects for grouped concepts
  final RetentionPolicy retentionPolicy;
  final DomainReferral domainReferral;

  // Legacy compatibility - expose retention fields directly
  bool get isRetentionEnabled => retentionPolicy.isEnabled;
  int get retentionDays => retentionPolicy.retentionDays;
  List<String> get domains => domainReferral.domains;

  /// Gets the current user's role in this workspace (if available)
  WorkspaceUserRole? getCurrentUserRole(String currentUserId) {
    final user = users.where((u) => u.userId == currentUserId).firstOrNull;
    return user?.role;
  }

  /// Checks if this workspace should be hidden from lists
  bool get shouldBeHidden => type == WorkspaceType.personallink;

  /// Checks if current user is admin or member
  bool isAdminOrMember(String currentUserId) {
    final role = getCurrentUserRole(currentUserId);
    return role == WorkspaceUserRole.admin ||
           role == WorkspaceUserRole.member ||
           role == WorkspaceUserRole.owner;
  }

  /// Checks if current user is a guest
  bool isGuest(String currentUserId) {
    final role = getCurrentUserRole(currentUserId);
    return role == WorkspaceUserRole.guest;
  }

  /// Gets workspace classification category
  WorkspaceCategory getCategory(String currentUserId) {
    if (shouldBeHidden) {
      return WorkspaceCategory.hidden;
    }

    if (type == WorkspaceType.personal) {
      return WorkspaceCategory.personal;
    }

    if (type == WorkspaceType.webcontact) {
      return WorkspaceCategory.webcontact;
    }

    // Standard or workspace type
    if (type == WorkspaceType.standard || type == WorkspaceType.workspace) {
      if (isAdminOrMember(currentUserId)) {
        return WorkspaceCategory.standardMember;
      } else if (isGuest(currentUserId)) {
        return WorkspaceCategory.standardGuest;
      }
    }

    return WorkspaceCategory.unknown;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        planType,
        createdAt,
        vanityName,
        description,
        imageUrl,
        lastUpdatedAt,
        users,
        phones,
        settings,
        backgroundColor,
        watermarkImageUrl,
        conversationDefault,
        invitationMode,
        ssoEmailDomain,
        scimProvider,
        scimConnectionName,
        retentionPolicy,
        domainReferral,
      ];
}
```

### Success Criteria

#### Automated Verification:
- [ ] Entity compiles: `dart analyze lib/features/workspaces/domain/entities/workspace.dart`
- [ ] All imports resolve correctly
- [ ] No breaking changes to public API (legacy getters still work)

#### Manual Verification:
- [ ] Value objects are properly integrated
- [ ] Legacy compatibility getters work
- [ ] Equatable props include all new fields
- [ ] Helper methods still function correctly

---

## Phase 4: Create V3 Mapper

### Overview

Create a new mapper specifically for V3 DTOs that handles all transformations from flat DTO to rich domain entity with value objects.

### Changes Required

#### 1. Create V3 Workspace Mapper

**File**: `lib/features/workspaces/data/mappers/workspace_v3_dto_mapper.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/domain_referral.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/retention_policy.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_setting.dart';

/// Extension methods to convert V3 DTOs to domain entities
extension WorkspaceV3DtoMapper on WorkspaceV3Dto {
  Workspace toDomain() {
    return Workspace(
      id: id,
      name: name,
      type: WorkspaceType.fromString(type),
      planType: PlanType.fromString(planType),
      createdAt: createdAt,
      vanityName: vanityName.isEmpty ? null : vanityName,
      description: description.isEmpty ? null : description,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      lastUpdatedAt: lastUpdatedAt,
      users: users
          .map((dto) {
            try {
              return dto.toDomain();
            } catch (e) {
              // Skip invalid user entries
              return null;
            }
          })
          .whereType<WorkspaceUser>()
          .toList(),
      phones: phones
          .map((dto) {
            try {
              return dto.toDomain();
            } catch (e) {
              // Skip invalid phone entries
              return null;
            }
          })
          .whereType<WorkspacePhone>()
          .toList(),
      settings: settings.map(
        (key, value) => MapEntry(key, value.toDomain()),
      ),
      backgroundColor: backgroundColor.isEmpty ? null : backgroundColor,
      watermarkImageUrl: watermarkImageUrl.isEmpty ? null : watermarkImageUrl,
      conversationDefault: conversationDefault,
      invitationMode: InvitationMode.fromString(invitationMode),
      ssoEmailDomain: ssoEmailDomain.isEmpty ? null : ssoEmailDomain,
      scimProvider: scimProvider.isEmpty ? null : scimProvider,
      scimConnectionName: scimConnectionName.isEmpty ? null : scimConnectionName,
      retentionPolicy: RetentionPolicy(
        isEnabled: isRetentionEnabled,
        retentionDays: retentionDays,
        retentionDaysAsyncMeeting: retentionDaysAsyncMeeting,
        whoCanChangeConversationRetention: whoCanChangeConversationRetention
            .map(WorkspaceUserRole.fromString)
            .toList(),
        whoCanMarkMessagesAsPreserved: whoCanMarkMessagesAsPreserved
            .map(WorkspaceUserRole.fromString)
            .toList(),
      ),
      domainReferral: DomainReferral(
        mode: DomainReferralMode.fromString(domainReferralMode),
        message: domainReferralMessage,
        title: domainReferralTitle,
        domains: domains,
      ),
    );
  }
}

extension WorkspaceUserV3DtoMapper on WorkspaceUserV3Dto {
  WorkspaceUser toDomain() {
    return WorkspaceUser(
      userId: userId,
      role: WorkspaceUserRole.fromString(role),
      status: WorkspaceUserStatus.fromString(status),
      statusChangedAt: statusChangedAt,
    );
  }
}

extension WorkspacePhoneV3DtoMapper on WorkspacePhoneV3Dto {
  WorkspacePhone toDomain() {
    return WorkspacePhone(
      id: id,
      number: number,
      type: WorkspacePhoneType.fromString(type),
      destinationWorkspaceId: destinationWorkspaceId.isEmpty ? null : destinationWorkspaceId,
      parentPhone: parentPhone.isEmpty ? null : parentPhone,
      label: label.isEmpty ? null : label,
      messageUrl: messageUrl.isEmpty ? null : messageUrl,
      phoneSid: phoneSid.isEmpty ? null : phoneSid,
    );
  }
}

extension WorkspaceSettingV3DtoMapper on WorkspaceSettingV3Dto {
  WorkspaceSetting toDomain() {
    return WorkspaceSetting(
      value: value,
      reason: WorkspaceSettingReason.fromString(reason),
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Mapper compiles: `dart analyze lib/features/workspaces/data/mappers/workspace_v3_dto_mapper.dart`
- [ ] All imports resolve
- [ ] Extension methods are properly defined

#### Manual Verification:
- [ ] Mapper converts all DTO fields to entity fields
- [ ] String → Enum conversions use `fromString` methods
- [ ] Empty strings are converted to null where appropriate
- [ ] Value objects are constructed from flat DTO fields
- [ ] Invalid nested items are skipped gracefully

---

## Phase 5: Add V3 Repository Methods

### Overview

Add new methods to the repository and data source interfaces for V3 endpoint access while keeping legacy methods intact.

### Changes Required

#### 1. Update WorkspaceRemoteDataSource Interface

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource.dart`

**Changes**: Add new methods for V3 (after existing methods)

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';

/// Remote data source for workspaces
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API (legacy endpoint)
  Future<List<WorkspaceDto>> getWorkspaces();

  /// Fetches a single workspace by ID (legacy endpoint)
  Future<WorkspaceDto> getWorkspace(String workspaceId);

  /// Fetches all workspaces from the V3 API endpoint
  Future<List<WorkspaceV3Dto>> getWorkspacesV3();

  /// Fetches a single workspace by ID from the V3 API endpoint
  Future<WorkspaceV3Dto> getWorkspaceV3(String workspaceId);
}
```

#### 2. Update WorkspaceRemoteDataSourceImpl

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart`

**Changes**: Add new V3 methods implementation (after line 147)

Add import:
```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';
```

Add methods after existing `getWorkspace` method:

```dart
  @override
  Future<List<WorkspaceV3Dto>> getWorkspacesV3() async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/workspaces',
      );

      // Parse response body to check for error details
      Map<String, dynamic>? errorData;
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          errorData = parsed;
        }
      } on Exception catch (e) {
        _logger.e('Failed to parse V3 response body', error: e.toString());
      }

      if (response.statusCode != 200) {
        var errorMessage = 'Failed to fetch workspaces from V3 API';
        if (errorData != null) {
          final errmsg = errorData['errmsg'] as String?;
          if (errmsg != null) {
            errorMessage = errmsg;
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } else {
          errorMessage = response.body;
        }

        _logger.e(
          'Failed to fetch V3 workspaces: ${response.statusCode}',
          error: errorMessage,
        );
        throw ServerException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }

      final data = jsonDecode(response.body);

      // V3 API should return a consistent format
      final List<dynamic> workspacesJson;
      if (data is List) {
        workspacesJson = data;
      } else if (data is Map<String, dynamic>) {
        // Check success field if present
        if (data.containsKey('success') && data['success'] != true) {
          final errmsg = data['errmsg'] as String?;
          final errorMsg = errmsg ?? 'V3 API returned success=false';
          _logger.e('V3 API returned success=false: $errorMsg');
          throw ServerException(
            statusCode: response.statusCode,
            message: errorMsg,
          );
        }

        workspacesJson = (data['workspaces'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            [];
      } else {
        throw const FormatException('Unexpected V3 response format');
      }

      if (workspacesJson.isEmpty) {
        return [];
      }

      // V3 DTOs will fail loudly on malformed data (required fields)
      final workspaces = <WorkspaceV3Dto>[];
      var skipped = 0;
      for (final item in workspacesJson) {
        if (item is! Map<String, dynamic>) {
          skipped++;
          _logger.w('Skipping V3 workspace entry with unexpected type', error: item.runtimeType);
          continue;
        }
        try {
          workspaces.add(WorkspaceV3Dto.fromJson(item));
        } on Exception catch (e, stack) {
          skipped++;
          _logger.w('Skipping malformed V3 workspace entry', error: e, stackTrace: stack);
        }
      }
      if (skipped > 0) {
        _logger.w('Skipped $skipped V3 workspace entries; delivering ${workspaces.length}');
      }

      return workspaces;
    } on ServerException {
      rethrow;
    } on FormatException catch (e, stack) {
      _logger.e('Format error parsing V3 workspaces response', error: e, stackTrace: stack);
      throw FormatException('Failed to parse V3 workspaces response: $e');
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching V3 workspaces', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch V3 workspaces: $e');
    }
  }

  @override
  Future<WorkspaceV3Dto> getWorkspaceV3(String workspaceId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/v3/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _logger.i('V3 Workspace detail keys from API: ${data.keys.toList()}');
        final workspace = WorkspaceV3Dto.fromJson(data);
        return workspace;
      } else {
        _logger.e('Failed to fetch V3 workspace: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch V3 workspace',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching V3 workspace', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch V3 workspace: $e');
    }
  }
```

#### 3. Update WorkspaceRepository Interface

**File**: `lib/features/workspaces/domain/repositories/workspace_repository.dart`

**Changes**: Add V3 methods (keep existing methods)

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Repository for workspace operations
abstract class WorkspaceRepository {
  /// Fetches all workspaces (legacy endpoint)
  Future<Result<List<Workspace>>> getWorkspaces();

  /// Fetches a single workspace by ID (legacy endpoint)
  Future<Result<Workspace>> getWorkspace(String workspaceId);

  /// Fetches all workspaces from V3 API
  Future<Result<List<Workspace>>> getWorkspacesV3();

  /// Fetches a single workspace by ID from V3 API
  Future<Result<Workspace>> getWorkspaceV3(String workspaceId);

  /// Clears the workspace cache
  void clearCache();
}
```

#### 4. Update WorkspaceRepositoryImpl

**File**: `lib/features/workspaces/data/repositories/workspace_repository_impl.dart`

**Changes**: Add V3 methods implementation

Add import:
```dart
import 'package:carbon_voice_console/features/workspaces/data/mappers/workspace_v3_dto_mapper.dart';
```

Add methods after existing methods (before `clearCache`):

```dart
  @override
  Future<Result<List<Workspace>>> getWorkspacesV3() async {
    try {
      // Note: Not using cache for V3 during migration phase
      // Could implement separate V3 cache later if needed
      final workspaceDtos = await _remoteDataSource.getWorkspacesV3();
      final workspaces = workspaceDtos.map((dto) => dto.toDomain()).toList();

      // Optionally update cache with V3 data
      _cachedWorkspaces = workspaces;

      return success(workspaces);
    } on ServerException catch (e) {
      _logger.e('Server error fetching V3 workspaces', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching V3 workspaces', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching V3 workspaces', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Workspace>> getWorkspaceV3(String workspaceId) async {
    try {
      // Check cache first (works for both V1 and V3)
      if (_cachedWorkspaces != null) {
        final cached = _cachedWorkspaces!.where((w) => w.id == workspaceId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached workspace (V3 request): $workspaceId');
          return success(cached);
        }
      }

      final workspaceDto = await _remoteDataSource.getWorkspaceV3(workspaceId);
      return success(workspaceDto.toDomain());
    } on ServerException catch (e) {
      _logger.e('Server error fetching V3 workspace', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching V3 workspace', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching V3 workspace', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }
```

### Success Criteria

#### Automated Verification:
- [ ] Data source interface compiles: `dart analyze lib/features/workspaces/data/datasources/`
- [ ] Repository interface compiles: `dart analyze lib/features/workspaces/domain/repositories/`
- [ ] Implementation files compile: `dart analyze lib/features/workspaces/data/`
- [ ] No breaking changes to existing method signatures

#### Manual Verification:
- [ ] V3 methods are properly added alongside legacy methods
- [ ] Error handling mirrors legacy implementation
- [ ] Logging distinguishes V3 from legacy calls
- [ ] Cache behavior is consistent

---

## Phase 6: Run Code Generation and Verify Build

### Overview

Generate JSON serialization code for all V3 DTOs and verify the entire build works correctly.

### Changes Required

#### 1. Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `workspace_v3_dto.g.dart`
- `workspace_user_v3_dto.g.dart`
- `workspace_phone_v3_dto.g.dart`
- `workspace_setting_v3_dto.g.dart`

#### 2. Verify No Compilation Errors

```bash
flutter analyze
```

#### 3. Run Tests (if they exist)

```bash
flutter test
```

#### 4. Verify Build

```bash
# For web
flutter build web

# OR for macOS
flutter build macos
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] All `.g.dart` files generated without errors
- [ ] No compilation errors: `flutter analyze`
- [ ] Build succeeds: `flutter build web` or `flutter build macos`
- [ ] Tests pass: `flutter test`

#### Manual Verification:
- [ ] Generated files are properly formatted
- [ ] No warnings in analyzer output
- [ ] Legacy workspace functionality still works
- [ ] V3 DTOs can be instantiated from JSON

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation that the build is stable before proceeding to integration testing.

---

## Phase 7: Migrate Consumers to V3 and Deprecate Legacy Code

### Overview

After V3 has been validated in production, migrate all consumers to use V3 methods exclusively, then remove legacy code to keep the codebase clean. This is the final cleanup phase.

### Prerequisites

Before starting this phase:
- [ ] V3 endpoint has been validated in production for at least 1-2 weeks
- [ ] No critical issues reported with V3 implementation
- [ ] All workspace features work correctly with V3
- [ ] Stakeholder approval to deprecate legacy endpoint

### Changes Required

#### 1. Update BLoC to Use V3 Exclusively

**File**: `lib/features/workspaces/presentation/bloc/workspace_bloc.dart`

**Changes**: Replace legacy repository calls with V3 calls

```dart
Future<void> _onLoadWorkspaces(
  LoadWorkspaces event,
  Emitter<WorkspaceState> emit,
) async {
  emit(const WorkspaceLoading());

  // Replace: await _workspaceRepository.getWorkspaces();
  // With V3:
  final result = await _workspaceRepository.getWorkspacesV3();

  result.fold(
    onSuccess: (workspaces) {
      // ... existing logic ...
    },
    onFailure: (failure) {
      emit(WorkspaceError(FailureMapper.mapToMessage(failure.failure)));
    },
  );
}
```

#### 2. Update Any Direct Repository Usage

Search for all usages of legacy methods:

```bash
# Find all legacy method calls
grep -r "getWorkspaces()" lib/ --exclude-dir=".dart_tool"
grep -r "getWorkspace(" lib/ --exclude-dir=".dart_tool"
```

Replace each instance:
- `repository.getWorkspaces()` → `repository.getWorkspacesV3()`
- `repository.getWorkspace(id)` → `repository.getWorkspaceV3(id)`

#### 3. Remove Legacy Methods from Repository Interface

**File**: `lib/features/workspaces/domain/repositories/workspace_repository.dart`

**Changes**: Remove old method signatures

```dart
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Repository for workspace operations
abstract class WorkspaceRepository {
  /// Fetches all workspaces from V3 API
  Future<Result<List<Workspace>>> getWorkspacesV3();

  /// Fetches a single workspace by ID from V3 API
  Future<Result<Workspace>> getWorkspaceV3(String workspaceId);

  /// Clears the workspace cache
  void clearCache();
}
```

Remove:
- ~~`Future<Result<List<Workspace>>> getWorkspaces();`~~
- ~~`Future<Result<Workspace>> getWorkspace(String workspaceId);`~~

#### 4. Remove Legacy Methods from Repository Implementation

**File**: `lib/features/workspaces/data/repositories/workspace_repository_impl.dart`

**Changes**: Delete the `getWorkspaces()` and `getWorkspace()` method implementations (the non-V3 versions)

Remove approximately lines 1127-1152 and 1155-1178 (the legacy methods).

#### 5. Remove Legacy Methods from Data Source Interface

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource.dart`

**Changes**: Remove legacy method signatures

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';

/// Remote data source for workspaces
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the V3 API endpoint
  Future<List<WorkspaceV3Dto>> getWorkspacesV3();

  /// Fetches a single workspace by ID from the V3 API endpoint
  Future<WorkspaceV3Dto> getWorkspaceV3(String workspaceId);
}
```

Remove:
- ~~`Future<List<WorkspaceDto>> getWorkspaces();`~~
- ~~`Future<WorkspaceDto> getWorkspace(String workspaceId);`~~

#### 6. Remove Legacy Methods from Data Source Implementation

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart`

**Changes**: Delete the legacy `getWorkspaces()` and `getWorkspace()` implementations

Remove approximately lines 18-119 and 122-146 (the legacy methods).

#### 7. Delete Legacy DTO Files

Remove the old DTO files that used `fromApiJson` normalization:

```bash
# Delete legacy DTOs
rm lib/features/workspaces/data/models/api/workspace_dto.dart
rm lib/features/workspaces/data/models/api/workspace_dto.g.dart
rm lib/features/workspaces/data/models/api/workspace_user_dto.dart
rm lib/features/workspaces/data/models/api/workspace_user_dto.g.dart
rm lib/features/workspaces/data/models/api/workspace_phone_dto.dart
rm lib/features/workspaces/data/models/api/workspace_phone_dto.g.dart
rm lib/features/workspaces/data/models/api/workspace_setting_dto.dart
rm lib/features/workspaces/data/models/api/workspace_setting_dto.g.dart
```

#### 8. Delete Legacy Mapper File

Remove the old mapper that worked with legacy DTOs:

```bash
rm lib/features/workspaces/data/mappers/workspace_dto_mapper.dart
```

#### 9. Rename V3 Files to Remove "V3" Suffix

Now that V3 is the only version, remove the version suffix:

```bash
# Rename DTO files
mv lib/features/workspaces/data/models/api/workspace_v3_dto.dart \
   lib/features/workspaces/data/models/api/workspace_dto.dart

mv lib/features/workspaces/data/models/api/workspace_user_v3_dto.dart \
   lib/features/workspaces/data/models/api/workspace_user_dto.dart

mv lib/features/workspaces/data/models/api/workspace_phone_v3_dto.dart \
   lib/features/workspaces/data/models/api/workspace_phone_dto.dart

mv lib/features/workspaces/data/models/api/workspace_setting_v3_dto.dart \
   lib/features/workspaces/data/models/api/workspace_setting_dto.dart

# Rename mapper file
mv lib/features/workspaces/data/mappers/workspace_v3_dto_mapper.dart \
   lib/features/workspaces/data/mappers/workspace_dto_mapper.dart
```

#### 10. Update Class Names to Remove "V3" Suffix

**File**: `lib/features/workspaces/data/models/api/workspace_dto.dart`

**Changes**: Rename classes and update imports

```dart
// Change class names:
// WorkspaceV3Dto → WorkspaceDto
// WorkspaceUserV3Dto → WorkspaceUserDto
// WorkspacePhoneV3Dto → WorkspacePhoneDto
// WorkspaceSettingV3Dto → WorkspaceSettingDto
// WorkspaceUserV3ListConverter → WorkspaceUserListConverter
// WorkspacePhoneV3ListConverter → WorkspacePhoneListConverter
// WorkspaceSettingsV3Converter → WorkspaceSettingsConverter
```

Use global find and replace:
- `WorkspaceV3Dto` → `WorkspaceDto`
- `WorkspaceUserV3Dto` → `WorkspaceUserDto`
- `WorkspacePhoneV3Dto` → `WorkspacePhoneDto`
- `WorkspaceSettingV3Dto` → `WorkspaceSettingDto`
- `V3ListConverter` → `ListConverter`
- `V3Converter` → `Converter`

Update part directive:
```dart
part 'workspace_dto.g.dart';  // was: workspace_v3_dto.g.dart
```

Repeat for all DTO files.

#### 11. Update Mapper Class Names

**File**: `lib/features/workspaces/data/mappers/workspace_dto_mapper.dart`

**Changes**: Rename extension methods

```dart
// Change:
// WorkspaceV3DtoMapper → WorkspaceDtoMapper
// WorkspaceUserV3DtoMapper → WorkspaceUserDtoMapper
// WorkspacePhoneV3DtoMapper → WorkspacePhoneDtoMapper
// WorkspaceSettingV3DtoMapper → WorkspaceSettingDtoMapper
```

#### 12. Rename Repository Methods to Remove "V3" Suffix

**File**: `lib/features/workspaces/domain/repositories/workspace_repository.dart`

**Changes**: Rename methods to canonical names

```dart
abstract class WorkspaceRepository {
  /// Fetches all workspaces
  Future<Result<List<Workspace>>> getWorkspaces();

  /// Fetches a single workspace by ID
  Future<Result<Workspace>> getWorkspace(String workspaceId);

  /// Clears the workspace cache
  void clearCache();
}
```

**File**: `lib/features/workspaces/data/repositories/workspace_repository_impl.dart`

**Changes**: Rename method implementations

```dart
@override
Future<Result<List<Workspace>>> getWorkspaces() async {
  // Was: getWorkspacesV3()
  try {
    final workspaceDtos = await _remoteDataSource.getWorkspaces();
    // ... rest of implementation
  }
}

@override
Future<Result<Workspace>> getWorkspace(String workspaceId) async {
  // Was: getWorkspaceV3()
  // ... implementation
}
```

#### 13. Rename Data Source Methods

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource.dart`

```dart
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API
  Future<List<WorkspaceDto>> getWorkspaces();

  /// Fetches a single workspace by ID
  Future<WorkspaceDto> getWorkspace(String workspaceId);
}
```

**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart`

**Changes**: Rename method implementations and update endpoint

```dart
@override
Future<List<WorkspaceDto>> getWorkspaces() async {
  // Was: getWorkspacesV3()
  try {
    final response = await _httpService.get(
      '${OAuthConfig.apiBaseUrl}/v3/workspaces',  // Keep V3 endpoint
    );
    // ... rest of implementation
  }
}

@override
Future<WorkspaceDto> getWorkspace(String workspaceId) async {
  // Was: getWorkspaceV3()
  try {
    final response = await _httpService.get(
      '${OAuthConfig.apiBaseUrl}/v3/workspaces/$workspaceId',  // Keep V3 endpoint
    );
    // ... rest of implementation
  }
}
```

**IMPORTANT**: Keep the `/v3/workspaces` endpoint URL - only remove "V3" from method names!

#### 14. Update BLoC Calls Back to Canonical Names

**File**: `lib/features/workspaces/presentation/bloc/workspace_bloc.dart`

```dart
Future<void> _onLoadWorkspaces(
  LoadWorkspaces event,
  Emitter<WorkspaceState> emit,
) async {
  emit(const WorkspaceLoading());

  // Now just: getWorkspaces() (but using V3 endpoint internally)
  final result = await _workspaceRepository.getWorkspaces();

  // ... rest of implementation
}
```

#### 15. Re-run Code Generation

After renaming classes:

```bash
# Delete old generated files
rm lib/features/workspaces/data/models/api/*_v3_dto.g.dart

# Generate new files
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 16. Update All Import Statements

Search and replace across the codebase:

```bash
# Find old imports
grep -r "workspace_v3_dto" lib/ --exclude-dir=".dart_tool"
grep -r "WorkspaceV3Dto" lib/ --exclude-dir=".dart_tool"
```

Replace:
- `workspace_v3_dto.dart` → `workspace_dto.dart`
- `workspace_user_v3_dto.dart` → `workspace_user_dto.dart`
- `workspace_phone_v3_dto.dart` → `workspace_phone_dto.dart`
- `workspace_setting_v3_dto.dart` → `workspace_setting_dto.dart`
- `workspace_v3_dto_mapper.dart` → `workspace_dto_mapper.dart`

#### 17. Verify No Legacy References Remain

```bash
# Check for any remaining V3 suffixes
grep -r "V3Dto" lib/ --exclude-dir=".dart_tool"
grep -r "v3_dto" lib/ --exclude-dir=".dart_tool"

# Check for any fromApiJson references
grep -r "fromApiJson" lib/features/workspaces/ --exclude-dir=".dart_tool"

# Verify old DTO files are gone
ls lib/features/workspaces/data/models/api/workspace_dto.dart 2>/dev/null && echo "ERROR: Old DTO still exists"
```

Expected result: No matches (clean codebase).

### Success Criteria

#### Automated Verification:
- [ ] All legacy DTO files deleted
- [ ] All legacy mapper files deleted
- [ ] Code generation completes: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No compilation errors: `flutter analyze`
- [ ] No "V3" suffixes found: `grep -r "V3Dto" lib/`
- [ ] No `fromApiJson` found in workspace code: `grep -r "fromApiJson" lib/features/workspaces/`
- [ ] Build succeeds: `flutter build web` or `flutter build macos`
- [ ] All tests pass: `flutter test`

#### Manual Verification:
- [ ] Application launches successfully
- [ ] Workspace loading works correctly
- [ ] Workspace selection works correctly
- [ ] All workspace-related features functional
- [ ] No console errors related to workspaces
- [ ] API calls go to `/v3/workspaces` endpoint (check network tab)
- [ ] No references to old normalization logic
- [ ] Codebase is clean and maintainable

**Implementation Note**: This phase represents the final state - V3 becomes the canonical implementation, "V3" naming is removed, and all technical debt is eliminated. The codebase is now clean, maintainable, and aligned with the API contract.

---

## Testing Strategy

### Unit Tests

Create comprehensive tests for the V3 implementation:

**File**: `test/features/workspaces/data/models/workspace_v3_dto_test.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceV3Dto', () {
    test('fromJson parses complete V3 workspace correctly', () {
      final json = {
        '_id': 'ws_v3_123',
        'vanity_name': 'test-workspace',
        'name': 'Test Workspace V3',
        'description': 'A test workspace',
        'image_url': 'https://example.com/image.png',
        'type': 'standard',
        'created_at': '2025-01-01T00:00:00.000Z',
        'last_updated_at': '2025-01-02T00:00:00.000Z',
        'plan_type': 'pro',
        'users': [],
        'settings': {},
        'phones': [],
        'background_color': '#FFFFFF',
        'watermark_image_url': 'https://example.com/watermark.png',
        'conversation_default': true,
        'invitation_mode': 'invite-only',
        'sso_email_domain': 'example.com',
        'scim_provider': 'okta',
        'scim_connection_name': 'okta-prod',
        'is_retention_enabled': true,
        'retention_days': 30,
        'who_can_change_conversation_retention': ['admin', 'owner'],
        'who_can_mark_messages_as_preserved': ['admin'],
        'retention_days_async_meeting': 60,
        'domain_referral_mode': 'inform',
        'domain_referral_message': 'Welcome!',
        'domain_referral_title': 'Join Us',
        'domains': ['example.com', 'test.com'],
      };

      final dto = WorkspaceV3Dto.fromJson(json);

      expect(dto.id, 'ws_v3_123');
      expect(dto.name, 'Test Workspace V3');
      expect(dto.type, 'standard');
      expect(dto.isRetentionEnabled, true);
      expect(dto.retentionDays, 30);
      expect(dto.domains.length, 2);
    });

    test('fromJson throws on missing required fields', () {
      final incompleteJson = {
        '_id': 'ws_123',
        'name': 'Test',
        // Missing many required fields
      };

      expect(
        () => WorkspaceV3Dto.fromJson(incompleteJson),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson handles nested users array', () {
      final json = {
        // ... other required fields ...
        'users': [
          {
            'user_id': 'user_1',
            'role': 'admin',
            'status': 'active',
            'status_changed_at': '2025-01-01T00:00:00.000Z',
          }
        ],
        // ... rest of required fields ...
      };

      final dto = WorkspaceV3Dto.fromJson(json);

      expect(dto.users.length, 1);
      expect(dto.users.first.userId, 'user_1');
      expect(dto.users.first.role, 'admin');
    });
  });
}
```

**File**: `test/features/workspaces/data/mappers/workspace_v3_dto_mapper_test.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/mappers/workspace_v3_dto_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_v3_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkspaceV3DtoMapper', () {
    test('toDomain converts DTO to entity with value objects', () {
      final dto = WorkspaceV3Dto(
        // ... create complete DTO ...
      );

      final entity = dto.toDomain();

      expect(entity.id, dto.id);
      expect(entity.type, WorkspaceType.fromString(dto.type));
      expect(entity.retentionPolicy.isEnabled, dto.isRetentionEnabled);
      expect(entity.retentionPolicy.retentionDays, dto.retentionDays);
      expect(entity.domainReferral.domains, dto.domains);
    });

    test('toDomain converts string enums correctly', () {
      // Test enum conversion with various values
    });

    test('toDomain handles empty strings as null', () {
      // Test that empty strings become null for optional fields
    });
  });
}
```

### Integration Tests

Test the V3 endpoint against a real or mock API:

```dart
void main() {
  group('V3 Workspace Integration', () {
    test('fetches workspaces from V3 endpoint', () async {
      // Test actual API call
    });

    test('handles V3 API errors gracefully', () async {
      // Test error scenarios
    });
  });
}
```

### Manual Testing Steps

1. **Fetch workspaces using V3 API**:
   - Call `repository.getWorkspacesV3()`
   - Verify all fields are populated
   - Check that retention policy value object works
   - Check that domain referral value object works

2. **Compare V3 vs Legacy**:
   - Fetch same workspace with both methods
   - Verify data consistency
   - Note any differences in field availability

3. **Test Error Handling**:
   - Test with malformed JSON (should fail loudly)
   - Test with missing required fields (should throw)
   - Test with network errors

4. **Test Value Objects**:
   - Verify `retentionPolicy` groups retention fields correctly
   - Verify `domainReferral` groups referral fields correctly
   - Test legacy getters still work (`isRetentionEnabled`, `domains`)

5. **Test Setting Reason Enum**:
   - Verify known reasons map correctly
   - Verify unknown reasons default to `unknown`

## Performance Considerations

### Memory Impact
- V3 DTOs are slightly larger (all required fields vs nullable)
- Value objects add minimal overhead
- **Mitigation**: Same caching strategy, impact negligible

### Parsing Performance
- Required fields enforce contract at parse time (fail fast)
- Value object construction is lightweight
- **Impact**: Negligible - still async off main thread

### Network
- V3 endpoint may return more complete data
- Payload size likely similar
- **Impact**: Depends on backend implementation

## Migration Path for Consumers

### Gradual Adoption Strategy

1. **Phase 1** (This Implementation):
   - V3 methods available alongside legacy
   - No breaking changes
   - Consumers choose when to migrate

2. **Phase 2** (Future):
   - Update BLoC to use V3 by default
   - Add feature flag for V3 vs legacy
   - Monitor for issues

3. **Phase 3** (Future):
   - Deprecate legacy methods
   - Remove `fromApiJson` normalization
   - Clean up legacy DTO code

### For New Features

New code should prefer V3 methods:
```dart
// Prefer this:
final result = await workspaceRepository.getWorkspacesV3();

// Over this:
final result = await workspaceRepository.getWorkspaces();
```

### For Existing Features

Can migrate incrementally:
```dart
// Keep using legacy for now
final result = await workspaceRepository.getWorkspaces();

// Migrate when ready
final result = await workspaceRepository.getWorkspacesV3();
```

## References

- **Current Implementation**: [lib/features/workspaces/](lib/features/workspaces/)
- **Previous Plan**: [thoughts/shared/plans/2025-12-05-workspace-dto-refactor.md](thoughts/shared/plans/2025-12-05-workspace-dto-refactor.md)
- **Data Source**: [workspace_remote_datasource_impl.dart](lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart:1)
- **Entity**: [workspace.dart](lib/features/workspaces/domain/entities/workspace.dart:1)
- **Mapper**: [workspace_dto_mapper.dart](lib/features/workspaces/data/mappers/workspace_dto_mapper.dart:1)
- **Clean Architecture**: Project follows standard clean architecture patterns
