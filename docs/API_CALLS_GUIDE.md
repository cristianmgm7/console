# API Calls Guide - After OAuth Refactor

This guide explains how to make authenticated API calls after the OAuth 2.0 refactor to use the `oauth2` package.

## Overview

After the refactor, all authenticated API calls should use `AuthenticatedHttpService` instead of Dio. The `oauth2.Client` automatically:
- ✅ Adds `Authorization: Bearer <token>` header to all requests
- ✅ Refreshes tokens automatically when they expire
- ✅ Retries failed requests after token refresh

## Architecture

```
AuthenticatedHttpService
    ↓
OAuthRepository.getClient()
    ↓
oauth2.Client (with automatic token refresh)
    ↓
HTTP Request with Authorization header
```

## Basic Usage

### 1. Inject AuthenticatedHttpService

In your data source, inject `AuthenticatedHttpService`:

```dart
import 'package:injectable/injectable.dart';
import '../../../../core/network/authenticated_http_service.dart';
import '../../../../core/config/oauth_config.dart';

@LazySingleton(as: UsersRemoteDataSource)
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final AuthenticatedHttpService _httpService;

  UsersRemoteDataSourceImpl(this._httpService);

  // ... methods
}
```

### 2. Make GET Requests

```dart
@override
Future<List<UserModel>> getUsers() async {
  // Build full URL using OAuthConfig
  final url = '${OAuthConfig.apiBaseUrl}/api/users';
  
  // Make authenticated GET request
  // Authorization header is added automatically
  final response = await _httpService.get(url);

  // Handle response
  if (response.statusCode == 200) {
    final List<dynamic> jsonList = jsonDecode(response.body);
    return jsonList.map((json) => UserModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users: ${response.statusCode}');
  }
}
```

### 3. Make POST Requests

```dart
@override
Future<UserModel> createUser(CreateUserRequest request) async {
  final url = '${OAuthConfig.apiBaseUrl}/api/users';
  
  // POST with JSON body
  // Authorization header and Content-Type are added automatically
  final response = await _httpService.post(
    url,
    body: {
      'name': request.name,
      'email': request.email,
    },
  );

  if (response.statusCode == 201) {
    return UserModel.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create user: ${response.statusCode}');
  }
}
```

### 4. Make PUT Requests

```dart
@override
Future<UserModel> updateUser(String userId, UpdateUserRequest request) async {
  final url = '${OAuthConfig.apiBaseUrl}/api/users/$userId';
  
  final response = await _httpService.put(
    url,
    body: {
      'name': request.name,
      'email': request.email,
    },
  );

  if (response.statusCode == 200) {
    return UserModel.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update user: ${response.statusCode}');
  }
}
```

### 5. Make DELETE Requests

```dart
@override
Future<void> deleteUser(String userId) async {
  final url = '${OAuthConfig.apiBaseUrl}/api/users/$userId';
  
  final response = await _httpService.delete(url);

  if (response.statusCode != 204 && response.statusCode != 200) {
    throw Exception('Failed to delete user: ${response.statusCode}');
  }
}
```

## Complete Example: User Data Source

```dart
import 'dart:convert';
import 'package:injectable/injectable.dart';
import '../../../../core/network/authenticated_http_service.dart';
import '../../../../core/config/oauth_config.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers();
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(Map<String, dynamic> data);
  Future<UserModel> updateUser(String id, Map<String, dynamic> data);
  Future<void> deleteUser(String id);
}

@LazySingleton(as: UsersRemoteDataSource)
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final AuthenticatedHttpService _httpService;

  UsersRemoteDataSourceImpl(this._httpService);

  @override
  Future<List<UserModel>> getUsers() async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users';
    final response = await _httpService.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> getUserById(String id) async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users/$id';
    final response = await _httpService.get(url);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('User not found');
    } else {
      throw Exception('Failed to load user: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> createUser(Map<String, dynamic> data) async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users';
    final response = await _httpService.post(url, body: data);

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create user: ${response.statusCode}');
    }
  }

  @override
  Future<UserModel> updateUser(String id, Map<String, dynamic> data) async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users/$id';
    final response = await _httpService.put(url, body: data);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteUser(String id) async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users/$id';
    final response = await _httpService.delete(url);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }
}
```

## Custom Headers

You can add custom headers to any request:

```dart
final response = await _httpService.get(
  url,
  headers: {
    'X-Custom-Header': 'custom-value',
    'Accept': 'application/vnd.api+json',
  },
);
```

Note: The `Authorization` header is always added automatically by `oauth2.Client`, and `Content-Type: application/json` is added automatically for POST/PUT requests.

## Error Handling

### Authentication Errors

If the user is not authenticated, `AuthenticatedHttpService` throws an exception:

```dart
try {
  final response = await _httpService.get(url);
  // ... handle response
} catch (e) {
  if (e.toString().contains('Not authenticated')) {
    // Redirect to login
    // Handle unauthenticated state
  } else {
    // Handle other errors
  }
}
```

### HTTP Status Codes

Handle different HTTP status codes appropriately:

```dart
final response = await _httpService.get(url);

switch (response.statusCode) {
  case 200:
    // Success
    break;
  case 401:
    // Unauthorized - token might be invalid
    // oauth2.Client should have refreshed it automatically
    // If this still fails, user needs to re-authenticate
    throw Exception('Authentication required');
  case 403:
    // Forbidden - user doesn't have permission
    throw Exception('Access denied');
  case 404:
    // Not found
    throw Exception('Resource not found');
  case 500:
    // Server error
    throw Exception('Server error');
  default:
    throw Exception('Request failed: ${response.statusCode}');
}
```

## Automatic Token Refresh

The `oauth2.Client` automatically refreshes tokens when they expire. You don't need to handle this manually:

```dart
// This will automatically:
// 1. Check if token is expired
// 2. Refresh token if needed
// 3. Add new token to request
// 4. Retry if previous request failed due to expired token
final response = await _httpService.get(url);
```

## Response Parsing

The service returns `http.Response` objects. Parse JSON responses:

```dart
import 'dart:convert';

final response = await _httpService.get(url);

if (response.statusCode == 200) {
  // Parse JSON
  final json = jsonDecode(response.body);
  
  // Handle single object
  final user = UserModel.fromJson(json);
  
  // Or handle array
  final List<dynamic> jsonList = json as List<dynamic>;
  final users = jsonList.map((j) => UserModel.fromJson(j)).toList();
}
```

## Public (Unauthenticated) Requests

For public endpoints that don't require authentication, use the `publicDio` instance:

```dart
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: PublicApiDataSource)
class PublicApiDataSourceImpl implements PublicApiDataSource {
  @Named('publicDio')
  final Dio _dio;

  PublicApiDataSourceImpl(this._dio);

  Future<PublicData> getPublicData() async {
    final response = await _dio.get('/api/public/data');
    return PublicData.fromJson(response.data);
  }
}
```

## Migration from Dio

### Before (Old Dio-based approach):

```dart
// OLD - Don't use this anymore
@LazySingleton(as: UsersRemoteDataSource)
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final Dio _dio; // ❌ Old approach

  UsersRemoteDataSourceImpl(this._dio);

  @override
  Future<List<UserModel>> getUsers() async {
    final response = await _dio.get('/api/users'); // ❌ Old approach
    return (response.data as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }
}
```

### After (New AuthenticatedHttpService approach):

```dart
// NEW - Use this
@LazySingleton(as: UsersRemoteDataSource)
class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final AuthenticatedHttpService _httpService; // ✅ New approach

  UsersRemoteDataSourceImpl(this._httpService);

  @override
  Future<List<UserModel>> getUsers() async {
    final url = '${OAuthConfig.apiBaseUrl}/api/users';
    final response = await _httpService.get(url); // ✅ New approach
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }
}
```

## Key Differences

| Aspect | Old (Dio) | New (AuthenticatedHttpService) |
|--------|-----------|--------------------------------|
| **Injection** | `Dio` | `AuthenticatedHttpService` |
| **URL** | Relative paths (`/api/users`) | Full URLs (`${OAuthConfig.apiBaseUrl}/api/users`) |
| **Response** | `Response.data` (already parsed) | `http.Response.body` (string, needs parsing) |
| **Token Refresh** | Manual via `AuthInterceptor` | Automatic via `oauth2.Client` |
| **Headers** | Added by interceptor | Added automatically by `oauth2.Client` |
| **Error Handling** | DioException | Standard Exception + status codes |

## Best Practices

1. **Always use full URLs**: Include `OAuthConfig.apiBaseUrl` in your URLs
2. **Handle status codes**: Check `response.statusCode` before parsing
3. **Parse JSON explicitly**: Use `jsonDecode(response.body)` for JSON responses
4. **Use Result pattern**: Wrap responses in `Result<T>` for better error handling
5. **Don't handle token refresh**: Let `oauth2.Client` handle it automatically

## Example with Result Pattern

For better error handling, wrap your data source methods with the `Result` pattern:

```dart
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';

@override
Future<Result<List<UserModel>>> getUsers() async {
  try {
    final url = '${OAuthConfig.apiBaseUrl}/api/users';
    final response = await _httpService.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      final users = jsonList.map((json) => UserModel.fromJson(json)).toList();
      return success(users);
    } else if (response.statusCode == 401) {
      return failure(const AuthFailure(
        code: 'UNAUTHORIZED',
        details: 'Authentication required',
      ));
    } else {
      return failure(ServerFailure(
        statusCode: response.statusCode,
        message: 'Failed to load users',
      ));
    }
  } catch (e) {
    return failure(UnknownFailure(details: e.toString()));
  }
}
```

## Summary

- ✅ Use `AuthenticatedHttpService` for all authenticated API calls
- ✅ Use full URLs with `OAuthConfig.apiBaseUrl`
- ✅ Parse JSON responses with `jsonDecode(response.body)`
- ✅ Handle HTTP status codes appropriately
- ✅ Token refresh happens automatically - no manual handling needed
- ✅ Use `publicDio` for unauthenticated endpoints

The `oauth2.Client` handles all the complexity of token management, so you can focus on your business logic!

