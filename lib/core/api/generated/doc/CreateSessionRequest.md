# adk_api.model.CreateSessionRequest

## Load the model package
```dart
import 'package:adk_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**sessionId** | **String** | Optional session ID. If not provided, one will be generated. | [optional] 
**state** | [**Map<String, Object>**](Object.md) | Initial session state | [optional] [default to const {}]
**events** | [**List<Event>**](Event.md) | Initial events for the session | [optional] [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


