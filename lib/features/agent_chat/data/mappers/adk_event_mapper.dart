import 'package:carbon_voice_console/features/agent_chat/data/models/event_dto.dart';
import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_event.dart';

extension EventDtoToDomain on EventDto {
  /// Convert EventDto to domain AdkEvent
  ///
  /// Unlike the old mapper, this preserves ALL event information
  AdkEvent toAdkEvent() {
    return AdkEvent(
      id: id ?? '',
      invocationId: invocationId ?? '',
      author: author,
      timestamp: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch((timestamp! * 1000).toInt())
          : DateTime.now(),
      content: content.toAdkContent(),
      actions: actions?.toAdkActions(),
      partial: partial ?? false,
      branch: branch,
      longRunningToolIds: longRunningToolIds,
    );
  }
}

extension ContentDtoToDomain on ContentDto {
  AdkContent toAdkContent() {
    return AdkContent(
      role: role,
      parts: parts.map((p) => p.toAdkPart()).toList(),
    );
  }
}

extension PartDtoToDomain on PartDto {
  AdkPart toAdkPart() {
    return AdkPart(
      text: text,
      functionCall: functionCall?.toAdkFunctionCall(),
      functionResponse: functionResponse?.toAdkFunctionResponse(),
      inlineData: inlineData?.toAdkInlineData(),
    );
  }
}

extension FunctionCallDtoToDomain on FunctionCallDto {
  AdkFunctionCall toAdkFunctionCall() {
    return AdkFunctionCall(
      name: name,
      args: args,
    );
  }
}

extension FunctionResponseDtoToDomain on FunctionResponseDto {
  AdkFunctionResponse toAdkFunctionResponse() {
    return AdkFunctionResponse(
      name: name,
      response: response,
    );
  }
}

extension InlineDataDtoToDomain on InlineDataDto {
  AdkInlineData toAdkInlineData() {
    return AdkInlineData(
      mimeType: mimeType,
      data: data,
    );
  }
}

extension ActionsDtoToDomain on ActionsDto {
  AdkActions toAdkActions() {
    return AdkActions(
      functionCalls: functionCalls?.map((c) => c.toAdkFunctionCall()).toList(),
      functionResponses: functionResponses?.map((r) => r.toAdkFunctionResponse()).toList(),
      skipSummarization: skipSummarization ?? false,
    );
  }
}
