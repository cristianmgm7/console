# User Profile DTOs

This folder contains the DTO (Data Transfer Object) classes and domain models for user profiles.

## Structure

### DTOs (Mirror API Structure)
- **`UserProfileDto`** - Main DTO that exactly mirrors the API JSON response
- **`PermissionDto`** - DTO for individual permission objects with `value` and `reason` fields
- **`WorkspaceDto`** - DTO for workspace configuration objects

### Domain Model
- **`UserProfile`** - Simplified domain model with only significant parameters for app logic

### Mapper
- **`UserProfileMapper`** - Extension method to convert `UserProfileDto` to `UserProfile` domain model

## Usage

### Data Source Layer (Returns DTOs)
```dart
// In UserRemoteDataSourceImpl
final userProfileDto = UserProfileDto.fromJson(jsonData);
return userProfileDto; // Data source returns raw DTO
```

### Repository Layer (Converts DTO → Domain Entity)
```dart
// In UserRepositoryImpl
final userProfileDto = await _remoteDataSource.getUser(userId);
final userProfile = userProfileDto.toDomain();
final user = User(
  id: userProfile.id,
  name: userProfile.fullName,
  email: userProfile.email,
);
return user; // Repository returns domain entity
```

### Domain Layer (Works with Entities)
```dart
// Domain entities have only significant parameters
print(userProfile.fullName); // Combined first + last name
print(userProfile.canViewMembers); // Key permission
print(userProfile.hasWorkspaces); // Derived data
```

## Key Features

- **DTOs**: Include all API fields, even unused ones, for complete API fidelity
- **Domain Model**: Only contains fields meaningful for app features (basic user info, key permissions, derived data)
- **Mapper**: Never loses required data, extracts significant parameters from complex API structure
- **JSON Serializable**: All DTOs use `@JsonSerializable` for automatic JSON parsing
