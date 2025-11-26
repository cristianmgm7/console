import 'package:carbon_voice_console/core/errors/exceptions.dart';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/download_http_service.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_item.dart';
import 'package:carbon_voice_console/features/message_download/domain/entities/download_result.dart';
import 'package:carbon_voice_console/features/message_download/domain/repositories/download_repository.dart';
import 'package:carbon_voice_console/features/message_download/utils/file_name_helper.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

@LazySingleton(as: DownloadRepository)
class DownloadRepositoryImpl implements DownloadRepository {
  DownloadRepositoryImpl(
    this._downloadHttpService,
    this._fileSaver,
    this._logger,
  );

  final DownloadHttpService _downloadHttpService;
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
  Future<Result<DownloadResult>> downloadItem(DownloadItem item) async {
    try {
      _logger.d('Downloading item: ${item.messageId} (${item.type})');

      // Get download directory
      final directoryResult = await getDownloadDirectory();
      if (directoryResult.isFailure) {
        return success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: 'Failed to access downloads directory',
        ),);
      }

      final directoryPath = directoryResult.valueOrNull!;

      // Handle transcript (no download needed, just save text)
      if (item.type == DownloadItemType.transcript) {
        return _saveTranscript(item, directoryPath);
      }

      // Handle audio download
      return _downloadAudio(item, directoryPath);
    } on Exception catch (e, stack) {
      _logger.e('Error downloading item: ${item.messageId}', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ),);
    }
  }

  Future<Result<DownloadResult>> _saveTranscript(
    DownloadItem item,
    String directoryPath,
  ) async {
    try {
      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        item.fileName,
      );

      final result = await _fileSaver.saveTextFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        content: item.url, // For transcripts, 'url' field contains the text content
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        ),),
        onFailure: (failure) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save transcript',
        ),),
      );
    } on Exception catch (e, stack) {
      _logger.e('Error saving transcript', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ),);
    }
  }

  Future<Result<DownloadResult>> _downloadAudio(
    DownloadItem item,
    String directoryPath,
  ) async {
    try {
      // Download file bytes
      final downloadResponse = await _downloadHttpService.downloadFile(item.url);

      // Determine file extension from Content-Type
      final extension = FileNameHelper.getAudioExtension(
        item.url,
        downloadResponse.contentType,
      );

      // Generate file name with proper extension
      final baseFileName = item.fileName.replaceAll('.mp3', extension);
      final uniqueFileName = FileNameHelper.getUniqueFileName(
        directoryPath,
        baseFileName,
      );

      // Save file
      final result = await _fileSaver.saveFile(
        directoryPath: directoryPath,
        fileName: uniqueFileName,
        bytes: downloadResponse.bytes,
      );

      return result.fold(
        onSuccess: (filePath) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.success,
          filePath: filePath,
        ),),
        onFailure: (failure) => success(DownloadResult(
          messageId: item.messageId,
          status: DownloadStatus.failed,
          errorMessage: failure.failureOrNull?.details ?? 'Failed to save audio file',
        ),),
      );
    } on NetworkException catch (e) {
      _logger.e('Network error downloading audio', error: e);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Network error: ${e.message}',
      ),);
    } on ServerException catch (e) {
      _logger.e('Server error downloading audio', error: e);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: 'Server error: ${e.message}',
      ),);
    } on Exception catch (e, stack) {
      _logger.e('Error downloading audio', error: e, stackTrace: stack);
      return success(DownloadResult(
        messageId: item.messageId,
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      ),);
    }
  }
}
