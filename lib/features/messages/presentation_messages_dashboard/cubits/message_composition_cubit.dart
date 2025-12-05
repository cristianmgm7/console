import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_composition_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageCompositionCubit extends Cubit<MessageCompositionState> {
  MessageCompositionCubit(this._logger) : super(const MessageCompositionState());

  final Logger _logger;

  /// Open composition panel for a new message
  void openNewMessage({
    required String workspaceId,
    required String channelId,
  }) {
    _logger.i('Opening composition panel for new message in channel: $channelId');
    emit(MessageCompositionState(
      isVisible: true,
      workspaceId: workspaceId,
      channelId: channelId,
      replyToMessageId: null,
    ));
  }

  /// Open composition panel for a reply
  void openReply({
    required String workspaceId,
    required String channelId,
    required String replyToMessageId,
  }) {
    _logger.i('Opening composition panel for reply to message: $replyToMessageId');
    emit(MessageCompositionState(
      isVisible: true,
      workspaceId: workspaceId,
      channelId: channelId,
      replyToMessageId: replyToMessageId,
    ));
  }

  /// Cancel reply (keep panel open but clear reply state)
  void cancelReply() {
    _logger.d('Canceling reply');
    emit(state.copyWithNullableReply());
  }

  /// Close composition panel
  void closePanel() {
    _logger.d('Closing composition panel');
    emit(const MessageCompositionState());
  }

  /// Handle successful message send
  void onSuccess() {
    _logger.i('Message sent successfully, closing composition panel');
    emit(const MessageCompositionState());
  }
}
