import 'package:carbon_voice_console/core/utils/failure_mapper.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:carbon_voice_console/features/messages/presentation/mappers/message_ui_mapper.dart';
import 'package:carbon_voice_console/features/messages/presentation/models/message_ui_model.dart';
import 'package:carbon_voice_console/features/users/domain/entities/user.dart';
import 'package:carbon_voice_console/features/users/domain/repositories/user_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'message_detail_event.dart';
part 'message_detail_state.dart';

@injectable
class MessageDetailBloc extends Bloc<MessageDetailEvent, MessageDetailState> {
  MessageDetailBloc(
    this._messageRepository,
    this._userRepository,
  ) : super(const MessageDetailInitial()) {
    on<LoadMessageDetail>(_onLoadMessageDetail);
  }

  final MessageRepository _messageRepository;
  final UserRepository _userRepository;

  Future<void> _onLoadMessageDetail(
    LoadMessageDetail event,
    Emitter<MessageDetailState> emit,
  ) async {
    emit(const MessageDetailLoading());
    final result = await _messageRepository.getMessage(event.messageId);

    if (result.isSuccess) {
      final message = result.valueOrNull!.toUiModel();
      final userResult = await _userRepository.getUsers([message.userId]);
      final user = userResult.valueOrNull?.firstOrNull;

      emit(MessageDetailLoaded(message: message, user: user));
    } else {
      emit(MessageDetailError(FailureMapper.mapToMessage(result.failureOrNull!)));
    }
  }
}
