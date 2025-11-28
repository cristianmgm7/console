import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/message_download/utils/file_name_helper.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: DownloadRepository)
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(
    this._fileSaver,
    this._logger,
  );

  final FileSaver _fileSaver;
  final Logger _logger;

  @override
  Future<Result<String>> getDownloadDirectory() async {
    try {
      final result = await _fileSaver.getDownloadsDirectory();

      return result.fold(
        onSuccess: (downloadsPath) {
          final datePath = FileNameHelper.getDateBasedDirectory(downloadsPath);
          return success(datePath);
        },
        onFailure: (failure) => failure,
      );
    } on Exception catch (e, stack) {
      _logger.e('Failed to get download directory', error: e, stackTrace: stack);
      return failure(StorageFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<DownloadResult>> saveTranscript(
    String messageId,
    String transcriptText,
    String fileName,
  ) async {
    try {
      _logger.d('Saving transcript for message: $messageId');

      // Get download directory
      final directoryResult = await getDownloadDirectory();
      if (directoryResult.isFailure) {
        return success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Failed to access downloads directory',
        ),);
      }

      final directoryPath = directoryResult.valueOrNull!;

      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        fileName,
      );

      final result = await _fileSaver.saveTextFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        content: transcriptText,
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        ),),
        onFailure: (failure) => success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save transcript',
        ),),
      );
    } on Exception catch (e, stack) {
      _logger.e('Error saving transcript', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ),);
    }
  }

  @override
  Future<Result<DownloadResult>> saveAudioFile(
    String messageId,
    List<int> audioBytes,
    String fileName,
    String? contentType,
  ) async {
    try {
      _logger.d('Saving audio file for message: $messageId');

      // Get download directory
      final directoryResult = await getDownloadDirectory();
      if (directoryResult.isFailure) {
        return success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Failed to access downloads directory',
        ),);
      }

      final directoryPath = directoryResult.valueOrNull!;

      // Determine file extension from Content-Type
      final extension = FileNameHelper.getAudioExtension(
        fileName,
        contentType,
      );

      // Generate file name with proper extension
      final baseFileName = fileName.replaceAll('.mp3', extension);
      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        baseFileName,
      );

      // Save file
      final result = await _fileSaver.saveFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        bytes: audioBytes,
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        ),),
        onFailure: (failure) => success(DownloadResult(
          messageId: messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
        ),),
      );
    } on Exception catch (e, stack) {
      _logger.e('Error saving audio file', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ),);
    }
  }
}
