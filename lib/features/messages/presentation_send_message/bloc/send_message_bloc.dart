import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:carbon_voice_console/features/messages/domain/usecases/send_message_usecase.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class SendMessageBloc extends Bloc<SendMessageEvent, SendMessageState> {
  SendMessageBloc(
    this._sendMessageUseCase,
    this._logger,
  ) : super(const SendMessageInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ResetSendMessage>(_onResetSendMessage);
  }

  final SendMessageUseCase _sendMessageUseCase;
  final Logger _logger;

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<SendMessageState> emit,
  ) async {
    emit(const SendMessageInProgress());

    final request = SendMessageRequest(
      text: event.text,
      channelId: event.channelId,
      workspaceId: event.workspaceId,
      replyToMessageId: event.replyToMessageId,
    );

    final result = await _sendMessageUseCase(request);

    result.fold(
      onSuccess: (sendResult) {
        _logger.i('Message sent successfully: ${sendResult.id}');
        emit(
          SendMessageSuccess(
            messageId: sendResult.id,
            createdAt: sendResult.createdAt,
          ),
        );
      },
      onFailure: (failure) {
        _logger.e('Failed to send message: ${failure.failure.code}');
        emit(SendMessageError(failure.failure.details ?? 'Failed to send message'));
      },
    );
  }

  void _onResetSendMessage(
    ResetSendMessage event,
    Emitter<SendMessageState> emit,
  ) {
    emit(const SendMessageInitial());
  }
}
