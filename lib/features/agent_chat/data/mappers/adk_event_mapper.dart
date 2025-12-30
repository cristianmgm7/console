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
      inlineData: inlineData?.toAdkInlineData(),
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
