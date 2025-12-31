# adk_api.api.DefaultApi

## Load the API package
```dart
import 'package:adk_api/api.dart';
```

All URIs are relative to *http://127.0.0.1:8000*

Method | HTTP request | Description
------------- | ------------- | -------------
[**appsAppNameUsersUserIdSessionsPost**](DefaultApi.md#appsappnameusersuseridsessionspost) | **POST** /apps/{app_name}/users/{user_id}/sessions | Create a new session
[**appsAppNameUsersUserIdSessionsSessionIdDelete**](DefaultApi.md#appsappnameusersuseridsessionssessioniddelete) | **DELETE** /apps/{app_name}/users/{user_id}/sessions/{session_id} | Delete session
[**appsAppNameUsersUserIdSessionsSessionIdGet**](DefaultApi.md#appsappnameusersuseridsessionssessionidget) | **GET** /apps/{app_name}/users/{user_id}/sessions/{session_id} | Get session details
[**docsGet**](DefaultApi.md#docsget) | **GET** /docs | API Documentation
[**listAppsGet**](DefaultApi.md#listappsget) | **GET** /list-apps | List available agents
[**rootGet**](DefaultApi.md#rootget) | **GET** / | Root endpoint
[**runPost**](DefaultApi.md#runpost) | **POST** /run | Run agent (non-streaming)
[**runSsePost**](DefaultApi.md#runssepost) | **POST** /run_sse | Run agent (streaming via SSE)


# **appsAppNameUsersUserIdSessionsPost**
> Session appsAppNameUsersUserIdSessionsPost(appName, userId, createSessionRequest)

Create a new session

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final appName = appName_example; // String | Name of the agent/app
final userId = userId_example; // String | User identifier
final createSessionRequest = CreateSessionRequest(); // CreateSessionRequest | 

try {
    final result = api_instance.appsAppNameUsersUserIdSessionsPost(appName, userId, createSessionRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->appsAppNameUsersUserIdSessionsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appName** | **String**| Name of the agent/app | 
 **userId** | **String**| User identifier | 
 **createSessionRequest** | [**CreateSessionRequest**](CreateSessionRequest.md)|  | [optional] 

### Return type

[**Session**](Session.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **appsAppNameUsersUserIdSessionsSessionIdDelete**
> appsAppNameUsersUserIdSessionsSessionIdDelete(appName, userId, sessionId)

Delete session

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final appName = appName_example; // String | 
final userId = userId_example; // String | 
final sessionId = sessionId_example; // String | 

try {
    api_instance.appsAppNameUsersUserIdSessionsSessionIdDelete(appName, userId, sessionId);
} catch (e) {
    print('Exception when calling DefaultApi->appsAppNameUsersUserIdSessionsSessionIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appName** | **String**|  | 
 **userId** | **String**|  | 
 **sessionId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **appsAppNameUsersUserIdSessionsSessionIdGet**
> Session appsAppNameUsersUserIdSessionsSessionIdGet(appName, userId, sessionId)

Get session details

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final appName = appName_example; // String | 
final userId = userId_example; // String | 
final sessionId = sessionId_example; // String | 

try {
    final result = api_instance.appsAppNameUsersUserIdSessionsSessionIdGet(appName, userId, sessionId);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->appsAppNameUsersUserIdSessionsSessionIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **appName** | **String**|  | 
 **userId** | **String**|  | 
 **sessionId** | **String**|  | 

### Return type

[**Session**](Session.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **docsGet**
> String docsGet()

API Documentation

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.docsGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->docsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/html

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listAppsGet**
> ListAppsGet200Response listAppsGet(detailed)

List available agents

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final detailed = true; // bool | Return detailed app information

try {
    final result = api_instance.listAppsGet(detailed);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->listAppsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **detailed** | **bool**| Return detailed app information | [optional] [default to false]

### Return type

[**ListAppsGet200Response**](ListAppsGet200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rootGet**
> Get200Response rootGet()

Root endpoint

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.rootGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->rootGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Get200Response**](Get200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **runPost**
> List<Event> runPost(runAgentRequest)

Run agent (non-streaming)

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final runAgentRequest = RunAgentRequest(); // RunAgentRequest | 

try {
    final result = api_instance.runPost(runAgentRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->runPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **runAgentRequest** | [**RunAgentRequest**](RunAgentRequest.md)|  | 

### Return type

[**List<Event>**](Event.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **runSsePost**
> String runSsePost(runAgentRequest)

Run agent (streaming via SSE)

### Example
```dart
import 'package:adk_api/api.dart';

final api_instance = DefaultApi();
final runAgentRequest = RunAgentRequest(); // RunAgentRequest | 

try {
    final result = api_instance.runSsePost(runAgentRequest);
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->runSsePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **runAgentRequest** | [**RunAgentRequest**](RunAgentRequest.md)|  | 

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: text/event-stream

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

