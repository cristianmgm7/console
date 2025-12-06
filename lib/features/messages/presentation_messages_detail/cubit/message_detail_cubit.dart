
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart' as bloc;
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/cubit/message_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@injectable
class MessageDetailCubit extends Cubit<MessageDetailState> {
  MessageDetailCubit(this._logger, this._messageDetailBloc)
      : super(const MessageDetailState());

  final Logger _logger;
  final bloc.MessageDetailBloc _messageDetailBloc;

  /// Open detail panel for a message
  void openDetail(String messageId) {
    _logger.i('Opening detail panel for message: $messageId');
    emit(MessageDetailState(selectedMessageId: messageId));

    // Trigger the MessageDetailBloc to load the message
    _messageDetailBloc.add(bloc.LoadMessageDetail(messageId));
  }

  /// Close detail panel
  void closeDetail() {
    _logger.d('Closing detail panel');
    emit(const MessageDetailState());
  }
}
