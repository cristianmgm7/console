# adk_api.model.Event

## Load the model package
```dart
import 'package:adk_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**author** | **String** | Author of the event ('user' or agent name) | 
**content** | [**Content**](Content.md) |  | 
**invocationId** | **String** | Invocation ID | [optional] 
**actions** | [**EventActions**](EventActions.md) |  | [optional] 
**longRunningToolIds** | **List<String>** | IDs of long-running tool calls | [optional] [default to const []]
**branch** | **String** | Branch path (agent hierarchy) | [optional] 
**id** | **String** | Event ID | [optional] 
**timestamp** | **num** | Event timestamp | [optional] 
**partial** | **bool** | Whether this is a partial response | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


