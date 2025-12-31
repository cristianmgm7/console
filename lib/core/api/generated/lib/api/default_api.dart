//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DefaultApi {
  DefaultApi([ApiClient? apiClient])
      : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///   Name of the agent/app
  ///
  /// * [String] userId (required):
  ///   User identifier
  ///
  /// * [CreateSessionRequest] createSessionRequest:
  Future<Response> appsAppNameUsersUserIdSessionsPostWithHttpInfo(
    String appName,
    String userId, {
    CreateSessionRequest? createSessionRequest,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/apps/{app_name}/users/{user_id}/sessions'
        .replaceAll('{app_name}', appName)
        .replaceAll('{user_id}', userId);

    // ignore: prefer_final_locals
    Object? postBody = createSessionRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a new session
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///   Name of the agent/app
  ///
  /// * [String] userId (required):
  ///   User identifier
  ///
  /// * [CreateSessionRequest] createSessionRequest:
  Future<Session?> appsAppNameUsersUserIdSessionsPost(
    String appName,
    String userId, {
    CreateSessionRequest? createSessionRequest,
  }) async {
    final response = await appsAppNameUsersUserIdSessionsPostWithHttpInfo(
      appName,
      userId,
      createSessionRequest: createSessionRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Session',
      ) as Session;
    }
    return null;
  }

  /// Delete session
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] sessionId (required):
  Future<Response> appsAppNameUsersUserIdSessionsSessionIdDeleteWithHttpInfo(
    String appName,
    String userId,
    String sessionId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/apps/{app_name}/users/{user_id}/sessions/{session_id}'
        .replaceAll('{app_name}', appName)
        .replaceAll('{user_id}', userId)
        .replaceAll('{session_id}', sessionId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete session
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] sessionId (required):
  Future<void> appsAppNameUsersUserIdSessionsSessionIdDelete(
    String appName,
    String userId,
    String sessionId,
  ) async {
    final response =
        await appsAppNameUsersUserIdSessionsSessionIdDeleteWithHttpInfo(
      appName,
      userId,
      sessionId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get session details
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] sessionId (required):
  Future<Response> appsAppNameUsersUserIdSessionsSessionIdGetWithHttpInfo(
    String appName,
    String userId,
    String sessionId,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/apps/{app_name}/users/{user_id}/sessions/{session_id}'
        .replaceAll('{app_name}', appName)
        .replaceAll('{user_id}', userId)
        .replaceAll('{session_id}', sessionId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get session details
  ///
  /// Parameters:
  ///
  /// * [String] appName (required):
  ///
  /// * [String] userId (required):
  ///
  /// * [String] sessionId (required):
  Future<Session?> appsAppNameUsersUserIdSessionsSessionIdGet(
    String appName,
    String userId,
    String sessionId,
  ) async {
    final response =
        await appsAppNameUsersUserIdSessionsSessionIdGetWithHttpInfo(
      appName,
      userId,
      sessionId,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Session',
      ) as Session;
    }
    return null;
  }

  /// API Documentation
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> docsGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/docs';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// API Documentation
  Future<String?> docsGet() async {
    final response = await docsGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'String',
      ) as String;
    }
    return null;
  }

  /// List available agents
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [bool] detailed:
  ///   Return detailed app information
  Future<Response> listAppsGetWithHttpInfo({
    bool? detailed,
  }) async {
    // ignore: prefer_const_declarations
    final path = r'/list-apps';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (detailed != null) {
      queryParams.addAll(_queryParams('', 'detailed', detailed));
    }

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// List available agents
  ///
  /// Parameters:
  ///
  /// * [bool] detailed:
  ///   Return detailed app information
  Future<ListAppsGet200Response?> listAppsGet({
    bool? detailed,
  }) async {
    final response = await listAppsGetWithHttpInfo(
      detailed: detailed,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'ListAppsGet200Response',
      ) as ListAppsGet200Response;
    }
    return null;
  }

  /// Root endpoint
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> rootGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];

    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Root endpoint
  Future<Get200Response?> rootGet() async {
    final response = await rootGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'Get200Response',
      ) as Get200Response;
    }
    return null;
  }

  /// Run agent (non-streaming)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RunAgentRequest] runAgentRequest (required):
  Future<Response> runPostWithHttpInfo(
    RunAgentRequest runAgentRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/run';

    // ignore: prefer_final_locals
    Object? postBody = runAgentRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Run agent (non-streaming)
  ///
  /// Parameters:
  ///
  /// * [RunAgentRequest] runAgentRequest (required):
  Future<List<Event>?> runPost(
    RunAgentRequest runAgentRequest,
  ) async {
    final response = await runPostWithHttpInfo(
      runAgentRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Event>')
              as List)
          .cast<Event>()
          .toList(growable: false);
    }
    return null;
  }

  /// Run agent (streaming via SSE)
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RunAgentRequest] runAgentRequest (required):
  Future<Response> runSsePostWithHttpInfo(
    RunAgentRequest runAgentRequest,
  ) async {
    // ignore: prefer_const_declarations
    final path = r'/run_sse';

    // ignore: prefer_final_locals
    Object? postBody = runAgentRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];

    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Run agent (streaming via SSE)
  ///
  /// Parameters:
  ///
  /// * [RunAgentRequest] runAgentRequest (required):
  Future<String?> runSsePost(
    RunAgentRequest runAgentRequest,
  ) async {
    final response = await runSsePostWithHttpInfo(
      runAgentRequest,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty &&
        response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(
        await _decodeBodyBytes(response),
        'String',
      ) as String;
    }
    return null;
  }
}
