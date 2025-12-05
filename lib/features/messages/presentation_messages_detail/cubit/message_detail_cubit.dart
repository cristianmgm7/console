import 'package:carbon_voice_console/features/messages/presentation_messages_detail/cubit/message_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageDetailCubit extends Cubit<MessageDetailState> {
  MessageDetailCubit(this._logger) : super(const MessageDetailState());

  final Logger _logger;

  /// Open detail panel for a message
  void openDetail(String messageId) {
    _logger.i('Opening detail panel for message: $messageId');
    emit(MessageDetailState(selectedMessageId: messageId));
  }

  /// Close detail panel
  void closeDetail() {
    _logger.d('Closing detail panel');
    emit(const MessageDetailState());
  }
}
