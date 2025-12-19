import 'package:carbon_voice_console/core/config/oauth_config.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Use case for building the stream URL for audio playback
@injectable
class GetAudioStreamUrlUsecase {
  const GetAudioStreamUrlUsecase(this._logger);

  final Logger _logger;

  /// Builds the stream URL for a message's audio
  ///
  /// [messageId] - The ID of the message
  /// [audioId] - The ID of the audio model
  /// [file] - The filename/format of the audio (e.g., 'audio.mp3')
  ///
  /// Returns the complete stream URL string
  String call({
    required String messageId,
    required String audioId,
    required String file,
  }) {
    final streamUrl = '${OAuthConfig.apiBaseUrl}/stream/$messageId/$audioId/$file';
    _logger.d('Built stream URL: $streamUrl');
    return streamUrl;
  }
}
