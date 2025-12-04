import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/message.dart';
import 'package:carbon_voice_console/features/messages/domain/entities/send_message_request.dart';
import 'package:carbon_voice_console/features/messages/domain/repositories/message_repository.dart';
import 'package:injectable/injectable.dart';

/// Use case for sending a message to a conversation
@injectable
class SendMessageUseCase {
  const SendMessageUseCase(this._repository);

  final MessageRepository _repository;

  Future<Result<Message>> call(SendMessageRequest request) {
    return _repository.sendMessage(request);
  }
}
