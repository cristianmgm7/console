# adk_api.model.RunAgentRequest

## Load the model package
```dart
import 'package:adk_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**appName** | **String** | Agent/app name | 
**userId** | **String** | User ID | 
**sessionId** | **String** | Session ID | 
**newMessage** | [**Content**](Content.md) |  | 
**streaming** | **bool** | Whether to use streaming response | [optional] [default to false]
**stateDelta** | [**Map<String, Object>**](Object.md) | State changes to apply | [optional] [default to const {}]
**invocationId** | **String** | Invocation ID for resuming long-running functions | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


