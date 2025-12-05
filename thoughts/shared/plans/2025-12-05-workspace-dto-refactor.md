# Workspace DTO Refactor Implementation Plan

## Overview

Refactor the Workspace feature to use proper DTO pattern with `@JsonSerializable()` annotations, similar to the Messages feature. This will replace the current simple `WorkspaceModel` with comprehensive DTOs that handle all fields returned by the API, enable proper workspace classification, and remove the need for `JsonNormalizer.normalizeWorkspace()`.

## Current State Analysis

### Current Implementation
- **Simple model**: `WorkspaceModel` in `lib/features/workspaces/data/models/workspace_model.dart` with only 4 fields (id, name, guid, description)
- **Entity**: `Workspace` entity in `lib/features/workspaces/domain/entities/workspace.dart` with same 4 fields
- **Normalization**: Uses `JsonNormalizer.normalizeWorkspace()` to map API fields
- **Unused DTO**: There's a partial `WorkspaceDto` in `lib/dtos/workspace_dto.dart` with only configuration fields (not being used)

### API Response Structure
The API returns rich workspace data with ~30+ fields including:
- Basic info: `_id`, `name`, `vanity_name`, `description`, `image_url`
- Type & Plan: `type`, `plan_type` (e.g., "standard", "workspace", "webcontact", "personallink")
- Timestamps: `created_at`, `last_updated_at`
- Users array: `users[]` with `user_id`, `role`, `status`, `status_changed_at`
- Settings: Dynamic `settings{}` object
- Phones: `phones[]` array with phone objects
- Branding: `background_color`, `watermark_image_url`
- Permissions: `invitation_mode`, `conversation_default`
- SSO/SCIM: `sso_email_domain`, `scim_provider`, `scim_connection_name`
- Retention: `is_retention_enabled`, `retention_days`, `who_can_change_conversation_retention[]`, etc.
- Domain referral: `domain_referral_mode`, `domain_referral_message`, `domains[]`

### Key Discoveries
- **Pattern to follow**: Messages feature uses `@JsonSerializable()` DTOs in `features/messages/data/models/api/` with separate `mappers/` folder
- **Nested objects pattern**: ConversationDto shows how to handle nested arrays with custom converters
- **Current usage**: WorkspaceModel is used in:
  - `workspace_remote_datasource.dart` (interface)
  - `workspace_remote_datasource_impl.dart` (implementation)
  - `workspace_repository_impl.dart` (calls `.toEntity()`)

## Desired End State

After this refactor:
1. ✅ **Comprehensive DTO**: Full `WorkspaceDto` with all API fields using `@JsonSerializable()`
2. ✅ **Nested DTOs**: Separate DTOs for `WorkspaceUserDto`, `WorkspacePhoneDto`, `WorkspaceSettingDto`
3. ✅ **Enums**: Type-safe enums for `WorkspaceType`, `PlanType`, `UserRole`, `UserStatus`, `InvitationMode`, etc.
4. ✅ **Rich Entity**: Enhanced `Workspace` domain entity with fields needed for classification
5. ✅ **Mapper**: Extension method `WorkspaceDtoMapper` to convert DTO → Entity
6. ✅ **Clean structure**: Follow clean architecture with DTOs in `data/models/api/`, mappers in `data/mappers/`
7. ✅ **No normalization**: Remove `JsonNormalizer.normalizeWorkspace()` method
8. ✅ **Deleted files**: Remove old `WorkspaceModel` and unused `lib/dtos/workspace_dto.dart`
9. ✅ **Workspace classification**: Entity has properties to support sorting by type, role, and filtering
10. ✅ **Enhanced UI**: Beautiful workspace selector with category grouping, images, role badges, and improved UX

### Workspace Classification Support
The enhanced entity will enable classification as specified:
- **Personal**: `type` == "personal" (if it exists in API)
- **Standard/Workspace (Member/Admin)**: `type` in ["workspace", "standard"] AND current user has role "member" or "admin"
- **Standard/Workspace (Guest)**: `type` in ["workspace", "standard"] AND current user has role "guest"
- **Webcontact**: `type` == "webcontact"
- **Hidden**: `type` == "personallink" (filtered out from lists)

### Verification
- [ ] Build runs successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] No import errors in any workspace-related files
- [ ] Repository tests pass (if they exist)
- [ ] Can fetch and display workspaces in UI
- [ ] Workspace classification logic works correctly
- [ ] JsonNormalizer no longer has workspace-related code

## What We're NOT Doing

- NOT creating use cases for workspace operations (already exist if needed)
- NOT adding new API endpoints or data sources
- NOT migrating conversations or messages DTOs (out of scope)
- NOT creating a separate feature for workspace settings (keep it simple)
- NOT implementing workspace search/filtering (just categorization and display)
- NOT adding workspace creation/editing UI (read-only display)
- NOT implementing advanced workspace management features

## Implementation Approach

Follow the established patterns from Messages and Conversations features:
1. Create DTOs with `@JsonSerializable()` in `features/workspaces/data/models/api/`
2. Create enums in `features/workspaces/domain/entities/`
3. Create mapper extension in `features/workspaces/data/mappers/`
4. Update entity with new fields
5. Update repository to use new DTO
6. Delete old files
7. Update JsonNormalizer
8. Run code generation

## Phase 1: Create Enums and Nested DTOs

### Overview
Create type-safe enums and DTOs for nested objects. This establishes the foundation for the main WorkspaceDto.

### Changes Required

#### 1. Create Workspace Enums
**File**: `lib/features/workspaces/domain/entities/workspace_enums.dart`

```dart
/// Workspace type classification
enum WorkspaceType {
  /// Personal workspace
  personal('personal'),

  /// Standard workspace
  standard('standard'),

  /// Legacy workspace type
  workspace('workspace'),

  /// Web contact workspace
  webcontact('webcontact'),

  /// Personal link workspace (should be hidden from lists)
  personallink('personallink'),

  /// Unknown/unrecognized type
  unknown('unknown');

  const WorkspaceType(this.value);
  final String value;

  static WorkspaceType fromString(String? value) {
    if (value == null) return WorkspaceType.unknown;
    return WorkspaceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceType.unknown,
    );
  }
}

/// Workspace plan type
enum PlanType {
  /// Free plan
  free('free'),

  /// Standard plan
  standard('standard'),

  /// Pro plan
  pro('pro'),

  /// Enterprise plan
  enterprise('enterprise'),

  /// Unknown plan
  unknown('unknown');

  const PlanType(this.value);
  final String value;

  static PlanType fromString(String? value) {
    if (value == null) return PlanType.unknown;
    return PlanType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlanType.unknown,
    );
  }
}

/// User role in workspace
enum WorkspaceUserRole {
  /// Administrator
  admin('admin'),

  /// Regular member
  member('member'),

  /// Guest user
  guest('guest'),

  /// Owner
  owner('owner'),

  /// Unknown role
  unknown('unknown');

  const WorkspaceUserRole(this.value);
  final String value;

  static WorkspaceUserRole fromString(String? value) {
    if (value == null) return WorkspaceUserRole.unknown;
    return WorkspaceUserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceUserRole.unknown,
    );
  }
}

/// User status in workspace
enum WorkspaceUserStatus {
  /// Active user
  active('active'),

  /// Inactive user
  inactive('inactive'),

  /// Pending invitation
  pending('pending'),

  /// Suspended user
  suspended('suspended'),

  /// Unknown status
  unknown('unknown');

  const WorkspaceUserStatus(this.value);
  final String value;

  static WorkspaceUserStatus fromString(String? value) {
    if (value == null) return WorkspaceUserStatus.unknown;
    return WorkspaceUserStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspaceUserStatus.unknown,
    );
  }
}

/// Workspace invitation mode
enum InvitationMode {
  /// Anyone can join
  anyone('anyone'),

  /// Admin approval required
  adminApproval('admin-approval'),

  /// Invite only
  inviteOnly('invite-only'),

  /// Unknown mode
  unknown('unknown');

  const InvitationMode(this.value);
  final String value;

  static InvitationMode fromString(String? value) {
    if (value == null) return InvitationMode.unknown;
    return InvitationMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InvitationMode.unknown,
    );
  }
}

/// Domain referral mode
enum DomainReferralMode {
  /// Do not inform
  doNotInform('do-not-inform'),

  /// Inform user
  inform('inform'),

  /// Unknown mode
  unknown('unknown');

  const DomainReferralMode(this.value);
  final String value;

  static DomainReferralMode fromString(String? value) {
    if (value == null) return DomainReferralMode.unknown;
    return DomainReferralMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DomainReferralMode.unknown,
    );
  }
}

/// Phone type
enum WorkspacePhoneType {
  /// Voicemail
  voicemail('voicemail'),

  /// SMS
  sms('sms'),

  /// Call forwarding
  forwarding('forwarding'),

  /// Unknown type
  unknown('unknown');

  const WorkspacePhoneType(this.value);
  final String value;

  static WorkspacePhoneType fromString(String? value) {
    if (value == null) return WorkspacePhoneType.unknown;
    return WorkspacePhoneType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WorkspacePhoneType.unknown,
    );
  }
}
```

#### 2. Create WorkspaceUserDto
**File**: `lib/features/workspaces/data/models/api/workspace_user_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_user_dto.g.dart';

/// DTO for workspace user from API response
@JsonSerializable()
class WorkspaceUserDto {
  const WorkspaceUserDto({
    this.userId,
    this.role,
    this.statusChangedAt,
    this.status,
  });

  factory WorkspaceUserDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceUserDtoFromJson(json);

  @JsonKey(name: 'user_id')
  final String? userId;

  final String? role;

  @JsonKey(name: 'status_changed_at')
  final DateTime? statusChangedAt;

  final String? status;

  Map<String, dynamic> toJson() => _$WorkspaceUserDtoToJson(this);
}
```

#### 3. Create WorkspacePhoneDto
**File**: `lib/features/workspaces/data/models/api/workspace_phone_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_phone_dto.g.dart';

/// DTO for workspace phone from API response
@JsonSerializable()
class WorkspacePhoneDto {
  const WorkspacePhoneDto({
    this.id,
    this.destinationWorkspaceId,
    this.number,
    this.parentPhone,
    this.type,
    this.label,
    this.messageUrl,
    this.phoneSid,
  });

  factory WorkspacePhoneDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspacePhoneDtoFromJson(json);

  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'destination_workspace_id')
  final String? destinationWorkspaceId;

  final String? number;

  @JsonKey(name: 'parent_phone')
  final String? parentPhone;

  final String? type;

  final String? label;

  @JsonKey(name: 'message_url')
  final String? messageUrl;

  @JsonKey(name: 'phone_sid')
  final String? phoneSid;

  Map<String, dynamic> toJson() => _$WorkspacePhoneDtoToJson(this);
}
```

#### 4. Create WorkspaceSettingDto
**File**: `lib/features/workspaces/data/models/api/workspace_setting_dto.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'workspace_setting_dto.g.dart';

/// DTO for workspace setting value from API response
@JsonSerializable()
class WorkspaceSettingDto {
  const WorkspaceSettingDto({
    this.value,
    this.reason,
  });

  factory WorkspaceSettingDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceSettingDtoFromJson(json);

  final bool? value;

  final String? reason;

  Map<String, dynamic> toJson() => _$WorkspaceSettingDtoToJson(this);
}
```

### Success Criteria

#### Automated Verification:
- [ ] Files compile successfully: `dart analyze lib/features/workspaces/`
- [ ] No syntax errors in enum definitions
- [ ] Enum `fromString` methods handle null and unknown values correctly

#### Manual Verification:
- [ ] Enum files are properly organized
- [ ] All enum values match API response values exactly
- [ ] DTOs follow the same pattern as MessageDto

---

## Phase 2: Create Main WorkspaceDto with Custom Converters

### Overview
Create the main WorkspaceDto with all API fields, using custom converters for nested arrays similar to ConversationDto pattern.

### Changes Required

#### 1. Create WorkspaceDto
**File**: `lib/features/workspaces/data/models/api/workspace_dto.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_setting_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_dto.g.dart';

// Custom converter for WorkspaceUserDto list
class WorkspaceUserListConverter
    implements JsonConverter<List<WorkspaceUserDto>, List<dynamic>?> {
  const WorkspaceUserListConverter();

  @override
  List<WorkspaceUserDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => WorkspaceUserDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<WorkspaceUserDto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for WorkspacePhoneDto list
class WorkspacePhoneListConverter
    implements JsonConverter<List<WorkspacePhoneDto>, List<dynamic>?> {
  const WorkspacePhoneListConverter();

  @override
  List<WorkspacePhoneDto> fromJson(List<dynamic>? json) {
    if (json == null) return [];
    return json
        .map((item) => WorkspacePhoneDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic>? toJson(List<WorkspacePhoneDto> object) =>
      object.map((item) => item.toJson()).toList();
}

// Custom converter for settings map
class WorkspaceSettingsConverter
    implements
        JsonConverter<Map<String, WorkspaceSettingDto>, Map<String, dynamic>?> {
  const WorkspaceSettingsConverter();

  @override
  Map<String, WorkspaceSettingDto> fromJson(Map<String, dynamic>? json) {
    if (json == null) return {};
    return json.map(
      (key, value) => MapEntry(
        key,
        WorkspaceSettingDto.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  @override
  Map<String, dynamic>? toJson(Map<String, WorkspaceSettingDto> object) =>
      object.map((key, value) => MapEntry(key, value.toJson()));
}

/// DTO for workspace from API response
@JsonSerializable()
class WorkspaceDto {
  const WorkspaceDto({
    this.id,
    this.vanityName,
    this.name,
    this.description,
    this.imageUrl,
    this.type,
    this.createdAt,
    this.lastUpdatedAt,
    this.planType,
    this.users,
    this.settings,
    this.phones,
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.ssoEmailDomain,
    this.scimProvider,
    this.scimConnectionName,
    this.isRetentionEnabled,
    this.retentionDays,
    this.whoCanChangeConversationRetention,
    this.whoCanMarkMessagesAsPreserved,
    this.retentionDaysAsyncMeeting,
    this.domainReferralMode,
    this.domainReferralMessage,
    this.domainReferralTitle,
    this.domains,
  });

  factory WorkspaceDto.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceDtoFromJson(json);

  @JsonKey(name: '_id')
  final String? id;

  @JsonKey(name: 'vanity_name')
  final String? vanityName;

  final String? name;

  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  final String? type;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'last_updated_at')
  final DateTime? lastUpdatedAt;

  @JsonKey(name: 'plan_type')
  final String? planType;

  @WorkspaceUserListConverter()
  final List<WorkspaceUserDto>? users;

  @WorkspaceSettingsConverter()
  final Map<String, WorkspaceSettingDto>? settings;

  @WorkspacePhoneListConverter()
  final List<WorkspacePhoneDto>? phones;

  @JsonKey(name: 'background_color')
  final String? backgroundColor;

  @JsonKey(name: 'watermark_image_url')
  final String? watermarkImageUrl;

  @JsonKey(name: 'conversation_default')
  final bool? conversationDefault;

  @JsonKey(name: 'invitation_mode')
  final String? invitationMode;

  @JsonKey(name: 'sso_email_domain')
  final String? ssoEmailDomain;

  @JsonKey(name: 'scim_provider')
  final String? scimProvider;

  @JsonKey(name: 'scim_connection_name')
  final String? scimConnectionName;

  @JsonKey(name: 'is_retention_enabled')
  final bool? isRetentionEnabled;

  @JsonKey(name: 'retention_days')
  final int? retentionDays;

  @JsonKey(name: 'who_can_change_conversation_retention')
  final List<String>? whoCanChangeConversationRetention;

  @JsonKey(name: 'who_can_mark_messages_as_preserved')
  final List<String>? whoCanMarkMessagesAsPreserved;

  @JsonKey(name: 'retention_days_async_meeting')
  final int? retentionDaysAsyncMeeting;

  @JsonKey(name: 'domain_referral_mode')
  final String? domainReferralMode;

  @JsonKey(name: 'domain_referral_message')
  final String? domainReferralMessage;

  @JsonKey(name: 'domain_referral_title')
  final String? domainReferralTitle;

  final List<String>? domains;

  Map<String, dynamic> toJson() => _$WorkspaceDtoToJson(this);
}
```

### Success Criteria

#### Automated Verification:
- [ ] DTO compiles successfully: `dart analyze lib/features/workspaces/data/models/api/workspace_dto.dart`
- [ ] Custom converters compile without errors
- [ ] All `@JsonKey` annotations match API field names exactly

#### Manual Verification:
- [ ] All API fields from the JSON example are represented
- [ ] Nested converters follow ConversationDto pattern
- [ ] File structure matches Messages feature pattern

---

## Phase 3: Update Domain Entity and Create Mapper

### Overview
Enhance the Workspace domain entity with fields needed for classification, and create a mapper to convert from DTO to Entity.

### Changes Required

#### 1. Update Workspace Entity
**File**: `lib/features/workspaces/domain/entities/workspace.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain entity for workspace user
class WorkspaceUser extends Equatable {
  const WorkspaceUser({
    required this.userId,
    required this.role,
    required this.status,
    this.statusChangedAt,
  });

  final String userId;
  final WorkspaceUserRole role;
  final WorkspaceUserStatus status;
  final DateTime? statusChangedAt;

  @override
  List<Object?> get props => [userId, role, status, statusChangedAt];
}

/// Domain entity for workspace phone
class WorkspacePhone extends Equatable {
  const WorkspacePhone({
    required this.id,
    required this.number,
    required this.type,
    this.destinationWorkspaceId,
    this.parentPhone,
    this.label,
    this.messageUrl,
    this.phoneSid,
  });

  final String id;
  final String number;
  final WorkspacePhoneType type;
  final String? destinationWorkspaceId;
  final String? parentPhone;
  final String? label;
  final String? messageUrl;
  final String? phoneSid;

  @override
  List<Object?> get props => [
        id,
        number,
        type,
        destinationWorkspaceId,
        parentPhone,
        label,
        messageUrl,
        phoneSid,
      ];
}

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
    this.backgroundColor,
    this.watermarkImageUrl,
    this.conversationDefault,
    this.invitationMode,
    this.isRetentionEnabled,
    this.retentionDays,
    this.domains = const [],
  });

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
  final String? backgroundColor;
  final String? watermarkImageUrl;
  final bool? conversationDefault;
  final InvitationMode? invitationMode;
  final bool? isRetentionEnabled;
  final int? retentionDays;
  final List<String> domains;

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
        backgroundColor,
        watermarkImageUrl,
        conversationDefault,
        invitationMode,
        isRetentionEnabled,
        retentionDays,
        domains,
      ];
}

/// Workspace classification categories for sorting/filtering
enum WorkspaceCategory {
  /// Personal workspace
  personal,

  /// Standard/workspace where user is admin or member
  standardMember,

  /// Standard/workspace where user is guest
  standardGuest,

  /// Webcontact workspace
  webcontact,

  /// Hidden workspace (personallink)
  hidden,

  /// Unknown category
  unknown,
}
```

#### 2. Create Workspace Mapper
**File**: `lib/features/workspaces/data/mappers/workspace_dto_mapper.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_phone_dto.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_user_dto.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';

/// Extension methods to convert DTOs to domain entities
extension WorkspaceDtoMapper on WorkspaceDto {
  Workspace toDomain() {
    // Validate required fields
    if (id == null || name == null) {
      throw FormatException(
        'Required workspace fields are missing: id=${id == null}, name=${name == null}',
      );
    }

    return Workspace(
      id: id!,
      name: name!,
      type: WorkspaceType.fromString(type),
      planType: PlanType.fromString(planType),
      createdAt: createdAt ?? DateTime.now(),
      vanityName: vanityName,
      description: description,
      imageUrl: imageUrl,
      lastUpdatedAt: lastUpdatedAt,
      users: users?.map((dto) => dto.toDomain()).toList() ?? [],
      phones: phones?.map((dto) => dto.toDomain()).toList() ?? [],
      backgroundColor: backgroundColor,
      watermarkImageUrl: watermarkImageUrl,
      conversationDefault: conversationDefault,
      invitationMode: InvitationMode.fromString(invitationMode),
      isRetentionEnabled: isRetentionEnabled,
      retentionDays: retentionDays,
      domains: domains ?? [],
    );
  }
}

extension WorkspaceUserDtoMapper on WorkspaceUserDto {
  WorkspaceUser toDomain() {
    if (userId == null) {
      throw FormatException('WorkspaceUser missing required userId');
    }

    return WorkspaceUser(
      userId: userId!,
      role: WorkspaceUserRole.fromString(role),
      status: WorkspaceUserStatus.fromString(status),
      statusChangedAt: statusChangedAt,
    );
  }
}

extension WorkspacePhoneDtoMapper on WorkspacePhoneDto {
  WorkspacePhone toDomain() {
    if (id == null || number == null) {
      throw FormatException(
        'WorkspacePhone missing required fields: id=${id == null}, number=${number == null}',
      );
    }

    return WorkspacePhone(
      id: id!,
      number: number!,
      type: WorkspacePhoneType.fromString(type),
      destinationWorkspaceId: destinationWorkspaceId,
      parentPhone: parentPhone,
      label: label,
      messageUrl: messageUrl,
      phoneSid: phoneSid,
    );
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Entity compiles successfully: `dart analyze lib/features/workspaces/domain/entities/`
- [ ] Mapper compiles successfully: `dart analyze lib/features/workspaces/data/mappers/`
- [ ] No breaking changes to existing Workspace usages
- [ ] Helper methods (`getCategory`, `getCurrentUserRole`, etc.) work correctly

#### Manual Verification:
- [ ] Entity has all fields needed for workspace classification
- [ ] Mapper correctly converts all DTO fields to entity fields
- [ ] Enum conversions use `fromString` methods correctly
- [ ] Nested objects (users, phones) are mapped properly

---

## Phase 4: Update Data Sources and Repository

### Overview
Update the remote data source and repository to use the new WorkspaceDto instead of WorkspaceModel.

### Changes Required

#### 1. Update WorkspaceRemoteDataSource Interface
**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource.dart`

**Changes**: Replace `WorkspaceModel` with `WorkspaceDto`

```dart
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';

/// Remote data source for workspaces
abstract class WorkspaceRemoteDataSource {
  /// Fetches all workspaces from the API
  Future<List<WorkspaceDto>> getWorkspaces();

  /// Fetches a single workspace by ID
  Future<WorkspaceDto> getWorkspace(String workspaceId);
}
```

#### 2. Update WorkspaceRemoteDataSourceImpl
**File**: `lib/features/workspaces/data/datasources/workspace_remote_datasource_impl.dart`

**Changes**:
- Import new `WorkspaceDto` instead of `WorkspaceModel`
- Remove `JsonNormalizer.normalizeWorkspace()` calls
- Use `WorkspaceDto.fromJson()` directly

```dart
import 'dart:convert';
import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/network/authenticated_http_service.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/models/api/workspace_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRemoteDataSource)
class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  WorkspaceRemoteDataSourceImpl(this._httpService, this._logger);

  final AuthenticatedHttpService _httpService;
  final Logger _logger;

  @override
  Future<List<WorkspaceDto>> getWorkspaces() async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces',
      );

      // Parse response body to check for error details
      Map<String, dynamic>? errorData;
      try {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          errorData = parsed;
        }
      } on Exception catch (e) {
        _logger.e('Failed to parse response body', error: e.toString());
        // If parsing fails, we'll use the raw body
      }

      if (response.statusCode != 200) {
        // Extract error message from JSON if available
        var errorMessage = 'Failed to fetch workspaces';
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
          'Failed to fetch workspaces: ${response.statusCode}',
          error: errorMessage,
        );
        throw ServerException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }

      final data = jsonDecode(response.body);

      // API might return {workspaces: [...]}, {data: [...]}, or just [...]
      final List<dynamic> workspacesJson;
      if (data is List) {
        workspacesJson = data;
      } else if (data is Map<String, dynamic>) {
        // Check success field if present
        if (data.containsKey('success') && data['success'] != true) {
          // Extract error message if available
          final errmsg = data['errmsg'] as String?;
          final errorMsg = errmsg ?? 'API returned success=false';
          _logger.e('API returned success=false: $errorMsg');
          throw ServerException(
            statusCode: response.statusCode,
            message: errorMsg,
          );
        }

        workspacesJson = (data['workspaces'] as List<dynamic>?) ??
            (data['data'] as List<dynamic>?) ??
            [];
      } else {
        throw const FormatException('Unexpected response format');
      }

      if (workspacesJson.isEmpty) {
        return [];
      }

      final workspaces = workspacesJson
          .map((json) => WorkspaceDto.fromJson(json as Map<String, dynamic>))
          .toList();

      return workspaces;
    } on ServerException {
      rethrow;
    } on FormatException catch (e, stack) {
      _logger.e('Format error parsing workspaces response', error: e, stackTrace: stack);
      throw FormatException('Failed to parse workspaces response: $e');
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspaces', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspaces: $e');
    }
  }

  @override
  Future<WorkspaceDto> getWorkspace(String workspaceId) async {
    try {
      final response = await _httpService.get(
        '${OAuthConfig.apiBaseUrl}/workspaces/$workspaceId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final workspace = WorkspaceDto.fromJson(data);
        return workspace;
      } else {
        _logger.e('Failed to fetch workspace: ${response.statusCode}');
        throw ServerException(
          statusCode: response.statusCode,
          message: 'Failed to fetch workspace',
        );
      }
    } on ServerException {
      rethrow;
    } on Exception catch (e, stack) {
      _logger.e('Network error fetching workspace', error: e, stackTrace: stack);
      throw NetworkException(message: 'Failed to fetch workspace: $e');
    }
  }
}
```

#### 3. Update WorkspaceRepositoryImpl
**File**: `lib/features/workspaces/data/repositories/workspace_repository_impl.dart`

**Changes**:
- Import new mapper
- Call `.toDomain()` on DTO instead of `.toEntity()` on model

```dart
import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/workspaces/data/datasources/workspace_remote_datasource.dart';
import 'package:carbon_voice_console/features/workspaces/data/mappers/workspace_dto_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: WorkspaceRepository)
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this._remoteDataSource, this._logger);

  final WorkspaceRemoteDataSource _remoteDataSource;
  final Logger _logger;

  // In-memory cache for workspaces
  List<Workspace>? _cachedWorkspaces;

  @override
  Future<Result<List<Workspace>>> getWorkspaces() async {
    try {
      // Return cached workspaces if available
      if (_cachedWorkspaces != null) {
        _logger.d('Returning cached workspaces');
        return success(_cachedWorkspaces!);
      }

      final workspaceDtos = await _remoteDataSource.getWorkspaces();
      final workspaces = workspaceDtos.map((dto) => dto.toDomain()).toList();

      // Cache the result
      _cachedWorkspaces = workspaces;

      return success(workspaces);
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspaces', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspaces', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspaces', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<Workspace>> getWorkspace(String workspaceId) async {
    try {
      // Check cache first
      if (_cachedWorkspaces != null) {
        final cached = _cachedWorkspaces!.where((w) => w.id == workspaceId).firstOrNull;
        if (cached != null) {
          _logger.d('Returning cached workspace: $workspaceId');
          return success(cached);
        }
      }

      final workspaceDto = await _remoteDataSource.getWorkspace(workspaceId);
      return success(workspaceDto.toDomain());
    } on ServerException catch (e) {
      _logger.e('Server error fetching workspace', error: e);
      return failure(ServerFailure(statusCode: e.statusCode, details: e.message));
    } on NetworkException catch (e) {
      _logger.e('Network error fetching workspace', error: e);
      return failure(NetworkFailure(details: e.message));
    } on Exception catch (e, stack) {
      _logger.e('Unknown error fetching workspace', error: e, stackTrace: stack);
      return failure(UnknownFailure(details: e.toString()));
    }
  }

  /// Clears the workspace cache (useful for refresh)
  void clearCache() {
    _cachedWorkspaces = null;
  }
}
```

### Success Criteria

#### Automated Verification:
- [ ] Data sources compile successfully: `dart analyze lib/features/workspaces/data/datasources/`
- [ ] Repository compiles successfully: `dart analyze lib/features/workspaces/data/repositories/`
- [ ] No references to old `WorkspaceModel` remain
- [ ] No references to `JsonNormalizer.normalizeWorkspace()` remain

#### Manual Verification:
- [ ] Data source correctly parses API response to DTO
- [ ] Repository correctly converts DTO to entity using mapper
- [ ] Error handling remains intact

---

## Phase 5: Run Code Generation and Delete Old Files

### Overview
Generate the JSON serialization code for all DTOs, delete obsolete files, and clean up JsonNormalizer.

### Changes Required

#### 1. Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `workspace_dto.g.dart`
- `workspace_user_dto.g.dart`
- `workspace_phone_dto.g.dart`
- `workspace_setting_dto.g.dart`

#### 2. Delete Old Files

Delete the following files:
- `lib/features/workspaces/data/models/workspace_model.dart`
- `lib/dtos/workspace_dto.dart` (partial, unused)
- `lib/dtos/workspace_dto.g.dart` (generated for unused DTO)

```bash
rm lib/features/workspaces/data/models/workspace_model.dart
rm lib/dtos/workspace_dto.dart
rm lib/dtos/workspace_dto.g.dart
```

#### 3. Update JsonNormalizer
**File**: `lib/core/utils/json_normalizer.dart`

**Changes**: Remove the `normalizeWorkspace` method entirely

```dart
/// Utility for normalizing API JSON responses to consistent field names
/// This handles the mismatch between API field names and our domain model expectations
class JsonNormalizer {
  // REMOVED: normalizeWorkspace method
  // Workspaces now use WorkspaceDto with @JsonSerializable() annotations

  /// Normalizes conversation JSON from API format to our expected format
  /// @deprecated Use ConversationDto.fromJson() directly instead.
  /// DTOs with json_serializable now handle field mapping automatically.
  @Deprecated('Use ConversationDto.fromJson() directly - DTOs handle field mapping now')
  static Map<String, dynamic> normalizeConversation(Map<String, dynamic> json) {
    // Pass through unchanged - DTOs handle the mapping now
    return Map<String, dynamic>.from(json);
  }

  /// Normalizes message JSON from API format to our expected format
  static Map<String, dynamic> normalizeMessage(Map<String, dynamic> json) {
    // ... existing message normalization code ...
  }

  /// Normalizes audio model JSON from various API formats to our expected format
  static Map<String, dynamic> normalizeAudioModel(Map<String, dynamic> json) {
    // ... existing audio model normalization code ...
  }

  /// Normalizes user JSON from API format to our expected format
  static Map<String, dynamic> normalizeUser(Map<String, dynamic> json) {
    // ... existing user normalization code ...
  }
}
```

#### 4. Check for Any Remaining References

```bash
# Search for any remaining references to WorkspaceModel
grep -r "WorkspaceModel" lib/ --exclude-dir=".dart_tool"

# Search for any remaining references to normalizeWorkspace
grep -r "normalizeWorkspace" lib/ --exclude-dir=".dart_tool"
```

### Success Criteria

#### Automated Verification:
- [ ] Code generation completes successfully: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] All `.g.dart` files are generated without errors
- [ ] No compilation errors: `flutter analyze`
- [ ] No references to `WorkspaceModel` found: `grep -r "WorkspaceModel" lib/`
- [ ] No references to `normalizeWorkspace` in code (except deprecated marker): `grep -r "normalizeWorkspace" lib/`
- [ ] Build succeeds: `flutter build web` or `flutter build macos`

#### Manual Verification:
- [ ] Generated files are properly formatted
- [ ] Old files are completely removed
- [ ] JsonNormalizer only contains methods for messages and users

**Implementation Note**: After completing this phase and all automated verification passes, pause here for manual confirmation from the human that everything builds and works correctly before considering the refactor complete.

---

## Testing Strategy

### Unit Tests
Since this is primarily a data layer refactor, testing focus areas:
- **DTO Parsing**: Test `WorkspaceDto.fromJson()` with various API response formats
- **Mapper**: Test `WorkspaceDtoMapper.toDomain()` conversions
- **Enums**: Test `fromString()` methods with valid and invalid values
- **Entity Methods**: Test `getCategory()`, `getCurrentUserRole()`, etc.

Example test structure:
```dart
void main() {
  group('WorkspaceDto', () {
    test('fromJson parses complete workspace correctly', () {
      final json = {
        '_id': 'ws123',
        'name': 'Test Workspace',
        'type': 'standard',
        'plan_type': 'pro',
        // ... all fields
      };

      final dto = WorkspaceDto.fromJson(json);

      expect(dto.id, 'ws123');
      expect(dto.name, 'Test Workspace');
      expect(dto.type, 'standard');
    });

    test('fromJson handles nested users array', () {
      // Test user parsing
    });

    test('fromJson handles nested phones array', () {
      // Test phone parsing
    });

    test('fromJson handles settings map', () {
      // Test settings parsing
    });
  });

  group('WorkspaceDtoMapper', () {
    test('toDomain converts DTO to entity correctly', () {
      // Test mapper conversion
    });

    test('toDomain throws when required fields missing', () {
      // Test error handling
    });
  });

  group('WorkspaceType enum', () {
    test('fromString returns correct enum value', () {
      expect(WorkspaceType.fromString('standard'), WorkspaceType.standard);
      expect(WorkspaceType.fromString('webcontact'), WorkspaceType.webcontact);
    });

    test('fromString returns unknown for invalid value', () {
      expect(WorkspaceType.fromString('invalid'), WorkspaceType.unknown);
      expect(WorkspaceType.fromString(null), WorkspaceType.unknown);
    });
  });

  group('Workspace entity', () {
    test('getCategory returns correct category for admin', () {
      // Test classification logic
    });

    test('getCategory returns correct category for guest', () {
      // Test classification logic
    });

    test('shouldBeHidden returns true for personallink', () {
      // Test filtering logic
    });
  });
}
```

### Integration Tests
- Test fetching workspaces from API (if test environment available)
- Test repository caching behavior

### Manual Testing Steps
1. Launch the app and navigate to workspace selector/list
2. Verify workspaces load correctly
3. Check that workspace details display all fields
4. Verify workspace classification/sorting works as expected:
   - Personal workspaces appear first
   - Standard/workspace (member/admin) appear next
   - Standard/workspace (guest) appear after
   - Webcontact workspaces appear last
   - Personallink workspaces are hidden
5. Test with various workspace types in the list
6. Verify no console errors or warnings
7. Test workspace selection and navigation

## Performance Considerations

### Memory
- DTOs are slightly larger than the old simple model
- Nested objects (users, phones, settings) add memory overhead
- Repository cache holds full entities with all nested data
- **Mitigation**: Cache is already in place, no change in caching strategy

### Parsing Performance
- `@JsonSerializable()` code generation is very fast
- Nested converters add minimal overhead
- **Impact**: Negligible - DTO parsing is already async and off main thread

### Network
- No change to API calls or payload size
- **Impact**: None

## Migration Notes

### Breaking Changes
- `WorkspaceModel` class is removed
  - Any code importing `workspace_model.dart` will break
  - Any code calling `WorkspaceModel.fromJson()` will break
  - Any code calling `.toEntity()` on WorkspaceModel will break

### Affected Code
Based on grep results, affected files:
- `workspace_remote_datasource.dart` - Updated in Phase 4
- `workspace_remote_datasource_impl.dart` - Updated in Phase 4
- `workspace_repository_impl.dart` - Updated in Phase 4
- Presentation layer (BLoC/UI) - May need to handle new entity fields

### Migration Steps for Consumers
If any other code uses Workspace entity:
1. Update imports if needed
2. Update field access to use new entity structure
3. Test workspace-related UI components
4. Utilize new classification methods if needed

---

## Phase 6: UI Integration - Enhanced Workspace Selector

### Overview
Improve the workspace dropdown in the dashboard app bar to display workspaces organized by category, show workspace images, and provide better visual hierarchy. This phase leverages the new domain entity capabilities to create a user-friendly workspace selection experience.

### Current State
**File**: `lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart:94-139`

Current implementation:
- Simple dropdown showing only workspace names
- No visual grouping or categorization
- No workspace images
- Auto-selects first workspace
- No indication of workspace type or user role

### Changes Required

#### 1. Create Workspace UI Helper
**File**: `lib/features/workspaces/presentation/utils/workspace_ui_helper.dart`

```dart
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';

/// Helper class for organizing workspaces in the UI
class WorkspaceUIHelper {
  /// Groups workspaces by category for the current user
  static Map<WorkspaceCategory, List<Workspace>> groupByCategory(
    List<Workspace> workspaces,
    String currentUserId,
  ) {
    final grouped = <WorkspaceCategory, List<Workspace>>{};

    for (final workspace in workspaces) {
      final category = workspace.getCategory(currentUserId);

      // Skip hidden workspaces
      if (category == WorkspaceCategory.hidden) continue;

      grouped.putIfAbsent(category, () => []).add(workspace);
    }

    return grouped;
  }

  /// Returns workspaces in display order with category headers
  static List<WorkspaceDisplayItem> getDisplayItems(
    List<Workspace> workspaces,
    String currentUserId,
  ) {
    final grouped = groupByCategory(workspaces, currentUserId);
    final items = <WorkspaceDisplayItem>[];

    // Define category order
    const categoryOrder = [
      WorkspaceCategory.personal,
      WorkspaceCategory.standardMember,
      WorkspaceCategory.standardGuest,
      WorkspaceCategory.webcontact,
    ];

    for (final category in categoryOrder) {
      final categoryWorkspaces = grouped[category];
      if (categoryWorkspaces == null || categoryWorkspaces.isEmpty) continue;

      // Add category header
      items.add(WorkspaceDisplayItem.header(
        label: _getCategoryLabel(category),
        category: category,
      ));

      // Add workspaces in this category (sorted by name)
      final sorted = List<Workspace>.from(categoryWorkspaces)
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final workspace in sorted) {
        items.add(WorkspaceDisplayItem.workspace(workspace));
      }
    }

    return items;
  }

  /// Gets display label for category
  static String _getCategoryLabel(WorkspaceCategory category) {
    return switch (category) {
      WorkspaceCategory.personal => 'Personal',
      WorkspaceCategory.standardMember => 'Workspaces',
      WorkspaceCategory.standardGuest => 'Guest Workspaces',
      WorkspaceCategory.webcontact => 'Web Contact',
      WorkspaceCategory.hidden => 'Hidden',
      WorkspaceCategory.unknown => 'Other',
    };
  }

  /// Gets icon for workspace type
  static String getWorkspaceIcon(WorkspaceType type) {
    return switch (type) {
      WorkspaceType.personal => '👤',
      WorkspaceType.standard => '🏢',
      WorkspaceType.workspace => '🏢',
      WorkspaceType.webcontact => '🌐',
      WorkspaceType.personallink => '🔗',
      WorkspaceType.unknown => '❓',
    };
  }

  /// Gets user role badge text
  static String? getRoleBadge(Workspace workspace, String currentUserId) {
    final role = workspace.getCurrentUserRole(currentUserId);
    return switch (role) {
      WorkspaceUserRole.admin => 'Admin',
      WorkspaceUserRole.owner => 'Owner',
      WorkspaceUserRole.guest => 'Guest',
      WorkspaceUserRole.member => null, // Don't show badge for members
      _ => null,
    };
  }
}

/// Represents an item in the workspace display list (header or workspace)
sealed class WorkspaceDisplayItem {
  const WorkspaceDisplayItem();

  factory WorkspaceDisplayItem.header({
    required String label,
    required WorkspaceCategory category,
  }) = WorkspaceHeaderItem;

  factory WorkspaceDisplayItem.workspace(Workspace workspace) = WorkspaceItem;
}

/// Category header item
class WorkspaceHeaderItem extends WorkspaceDisplayItem {
  const WorkspaceHeaderItem({
    required this.label,
    required this.category,
  });

  final String label;
  final WorkspaceCategory category;
}

/// Workspace item
class WorkspaceItem extends WorkspaceDisplayItem {
  const WorkspaceItem(this.workspace);

  final Workspace workspace;
}
```

#### 2. Create Enhanced Workspace Selector Widget
**File**: `lib/features/workspaces/presentation/widgets/workspace_selector.dart`

```dart
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/utils/workspace_ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Enhanced workspace selector with categorization and images
class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({
    required this.currentUserId,
    this.width = 200,
    super.key,
  });

  final String currentUserId;
  final double width;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkspaceBloc, WorkspaceState, WorkspaceLoaded?>(
      selector: (state) => state is WorkspaceLoaded ? state : null,
      builder: (context, workspaceState) {
        if (workspaceState == null || workspaceState.workspaces.isEmpty) {
          return const SizedBox.shrink();
        }

        final displayItems = WorkspaceUIHelper.getDisplayItems(
          workspaceState.workspaces,
          currentUserId,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Workspace',
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: width,
              child: _buildDropdown(
                context,
                workspaceState,
                displayItems,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    WorkspaceLoaded state,
    List<WorkspaceDisplayItem> displayItems,
  ) {
    final selectedWorkspace = state.selectedWorkspace;

    return PopupMenuButton<String>(
      tooltip: 'Select workspace',
      offset: const Offset(0, 45),
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.surface,
        border: Border.all(color: AppColors.border),
        child: Row(
          children: [
            // Workspace image
            if (selectedWorkspace?.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  selectedWorkspace!.imageUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultWorkspaceIcon(selectedWorkspace.type),
                ),
              )
            else
              _buildDefaultWorkspaceIcon(selectedWorkspace?.type ?? WorkspaceType.unknown),

            const SizedBox(width: 8),

            // Workspace name
            Expanded(
              child: Text(
                selectedWorkspace?.name ?? 'Select workspace',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 4),

            // Dropdown icon
            Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return displayItems.map((item) {
          return switch (item) {
            WorkspaceHeaderItem(:final label) => PopupMenuItem<String>(
                enabled: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  label,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            WorkspaceItem(:final workspace) => PopupMenuItem<String>(
                value: workspace.id,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildWorkspaceMenuItem(workspace),
              ),
          };
        }).toList();
      },
      onSelected: (String workspaceId) {
        context.read<WorkspaceBloc>().add(SelectWorkspace(workspaceId));
      },
    );
  }

  Widget _buildWorkspaceMenuItem(Workspace workspace) {
    final roleBadge = WorkspaceUIHelper.getRoleBadge(workspace, currentUserId);

    return Row(
      children: [
        // Workspace image
        if (workspace.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              workspace.imageUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultWorkspaceIcon(workspace.type),
            ),
          )
        else
          _buildDefaultWorkspaceIcon(workspace.type),

        const SizedBox(width: 12),

        // Workspace name
        Expanded(
          child: Text(
            workspace.name,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Role badge
        if (roleBadge != null) ...[
          const SizedBox(width: 8),
          AppContainer(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            child: Text(
              roleBadge,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultWorkspaceIcon(WorkspaceType type) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          WorkspaceUIHelper.getWorkspaceIcon(type),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
```

#### 3. Update WorkspaceBloc to Support Current User
**File**: `lib/features/workspaces/presentation/bloc/workspace_state.dart`

Add current user ID to the state:

```dart
sealed class WorkspaceState extends Equatable {
  const WorkspaceState();

  @override
  List<Object?> get props => [];
}

class WorkspaceInitial extends WorkspaceState {
  const WorkspaceInitial();
}

class WorkspaceLoading extends WorkspaceState {
  const WorkspaceLoading();
}

class WorkspaceLoaded extends WorkspaceState {
  const WorkspaceLoaded(
    this.workspaces,
    this.selectedWorkspace, {
    this.currentUserId, // Add this
  });

  final List<Workspace> workspaces;
  final Workspace? selectedWorkspace;
  final String? currentUserId; // Add this

  @override
  List<Object?> get props => [workspaces, selectedWorkspace, currentUserId];
}

class WorkspaceError extends WorkspaceState {
  const WorkspaceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
```

**File**: `lib/features/workspaces/presentation/bloc/workspace_event.dart`

Add current user ID to load event:

```dart
sealed class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorkspaces extends WorkspaceEvent {
  const LoadWorkspaces({this.currentUserId}); // Add optional userId

  final String? currentUserId;

  @override
  List<Object?> get props => [currentUserId];
}

class SelectWorkspace extends WorkspaceEvent {
  const SelectWorkspace(this.workspaceId);

  final String workspaceId;

  @override
  List<Object?> get props => [workspaceId];
}
```

**File**: `lib/features/workspaces/presentation/bloc/workspace_bloc.dart`

Update to store and use current user ID:

```dart
import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/workspaces/domain/repositories/workspace_repository.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class WorkspaceBloc extends Bloc<WorkspaceEvent, WorkspaceState> {
  WorkspaceBloc(
    this._workspaceRepository,
  ) : super(const WorkspaceInitial()) {
    on<LoadWorkspaces>(_onLoadWorkspaces);
    on<SelectWorkspace>(_onSelectWorkspace);
  }

  final WorkspaceRepository _workspaceRepository;

  Future<void> _onLoadWorkspaces(
    LoadWorkspaces event,
    Emitter<WorkspaceState> emit,
  ) async {
    emit(const WorkspaceLoading());

    final result = await _workspaceRepository.getWorkspaces();

    result.fold(
      onSuccess: (workspaces) {
        if (workspaces.isEmpty) {
          emit(const WorkspaceError('No workspaces found'));
          return;
        }

        // Filter out hidden workspaces if userId provided
        final visibleWorkspaces = event.currentUserId != null
            ? workspaces.where((w) => !w.shouldBeHidden).toList()
            : workspaces;

        if (visibleWorkspaces.isEmpty) {
          emit(const WorkspaceError('No accessible workspaces found'));
          return;
        }

        final selected = visibleWorkspaces.first;
        emit(WorkspaceLoaded(
          visibleWorkspaces,
          selected,
          currentUserId: event.currentUserId,
        ));
      },
      onFailure: (failure) {
        emit(WorkspaceError(FailureMapper.mapToMessage(failure.failure)));
      },
    );
  }

  Future<void> _onSelectWorkspace(
    SelectWorkspace event,
    Emitter<WorkspaceState> emit,
  ) async {
    final currentState = state;
    if (currentState is! WorkspaceLoaded) return;

    final selected = currentState.workspaces.firstWhere(
      (w) => w.id == event.workspaceId,
      orElse: () => currentState.selectedWorkspace!,
    );

    emit(WorkspaceLoaded(
      currentState.workspaces,
      selected,
      currentUserId: currentState.currentUserId,
    ));
  }
}
```

#### 4. Update DashboardAppBar to Use New Selector
**File**: `lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart`

Replace the existing workspace dropdown (lines 93-140) with:

```dart
// Workspace Selector with enhanced UI
BlocSelector<WorkspaceBloc, WorkspaceState, WorkspaceLoaded?>(
  selector: (state) => state is WorkspaceLoaded ? state : null,
  builder: (context, workspaceState) {
    if (workspaceState == null || workspaceState.workspaces.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current user ID from auth or user profile
    // TODO: Replace with actual current user ID from auth
    final currentUserId = workspaceState.currentUserId ?? '';

    return WorkspaceSelector(
      currentUserId: currentUserId,
      width: 200,
    );
  },
),
```

Add import:
```dart
import 'package:carbon_voice_console/features/workspaces/presentation/widgets/workspace_selector.dart';
```

#### 5. Update Workspace Initialization
**File**: Update where `LoadWorkspaces` event is dispatched (likely in dashboard screen or main app)

Change from:
```dart
context.read<WorkspaceBloc>().add(const LoadWorkspaces());
```

To:
```dart
// Get current user ID from auth state or user profile
final currentUserId = /* get from auth */;
context.read<WorkspaceBloc>().add(LoadWorkspaces(currentUserId: currentUserId));
```

### Success Criteria

#### Automated Verification:
- [ ] All new files compile successfully: `dart analyze lib/features/workspaces/presentation/`
- [ ] No import errors
- [ ] BLoC state updates correctly when workspace selected
- [ ] Build succeeds: `flutter build web` or `flutter build macos`

#### Manual Verification:
- [ ] Workspace dropdown shows category headers (Personal, Workspaces, Guest Workspaces, Web Contact)
- [ ] Workspaces are sorted alphabetically within each category
- [ ] Workspace images display correctly (or show default icon if missing)
- [ ] Role badges show for admin/owner/guest roles
- [ ] "Personallink" workspaces are filtered out and not shown
- [ ] Selecting a workspace updates the UI correctly
- [ ] Category separators are visually distinct
- [ ] Dropdown styling is consistent with app design system
- [ ] Performance is acceptable with many workspaces (50+)

**Implementation Note**: This phase depends on having the current user ID available. If auth is not yet implemented, you can use a mock user ID or the first user in any workspace's users array as a temporary solution.

---

## References

- **API JSON Example**: Provided in initial task description
- **Messages DTO Pattern**: [lib/features/messages/data/models/api/message_dto.dart](lib/features/messages/data/models/api/message_dto.dart:1)
- **Conversation DTO Pattern**: [lib/dtos/conversation_dto.dart](lib/dtos/conversation_dto.dart:1)
- **Current WorkspaceModel**: [lib/features/workspaces/data/models/workspace_model.dart](lib/features/workspaces/data/models/workspace_model.dart:1)
- **Current Workspace Dropdown**: [lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart](lib/features/messages/presentation_messages_dashboard/components/app_bar_dashboard.dart:93-139)
- **Clean Architecture Guide**: [CLAUDE.md](CLAUDE.md) - "Feature Structure (Clean Architecture)"
- **Workspace Requirements**: User-provided classification requirements
