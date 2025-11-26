import 'dart:convert';
import 'dart:io';
import 'package:carbon_voice_console/core/errors/failures.dart';
import 'package:carbon_voice_console/core/utils/result.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/file_saver.dart';
import 'package:carbon_voice_console/features/message_download/data/datasources/web_file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

@LazySingleton(as: FileSaver)
class DesktopFileSaver implements FileSaver {
  DesktopFileSaver(this._logger) {
    // Delegate to WebFileSaver when running on web
    if (kIsWeb) {
      _delegate = WebFileSaver(_logger);
    }
  }

  final Logger _logger;
  FileSaver? _delegate;

  @override
  Future<Result<String>> getDownloadsDirectory() async {
    if (_delegate != null) {
      return _delegate!.getDownloadsDirectory();
    }

    try {
      final directory = await path_provider.getDownloadsDirectory();
      if (directory == null) {
        return failure(const StorageFailure(details: 'Downloads directory not available'));
      }
      return success(directory.path);
    } on Exception catch (e, stack) {
      _logger.e('Failed to get downloads directory', error: e, stackTrace: stack);
      return failure(StorageFailure(details: e.toString()));
    }
  }

  @override
  Future<Result<String>> saveFile({
    required String directoryPath,
    required String fileName,
    required List<int> bytes,
  }) async {
    if (_delegate != null) {
      return _delegate!.saveFile(
        directoryPath: directoryPath,
        fileName: fileName,
        bytes: bytes,
      );
    }

    try {
      // Ensure directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write file
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      _logger.i('Saved file: $filePath (${bytes.length} bytes)');
      return success(filePath);
    } on Exception catch (e, stack) {
      _logger.e('Failed to save file: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to save file: $e'));
    }
  }

  @override
  Future<Result<String>> saveTextFile({
    required String directoryPath,
    required String fileName,
    required String content,
  }) async {
    if (_delegate != null) {
      return _delegate!.saveTextFile(
        directoryPath: directoryPath,
        fileName: fileName,
        content: content,
      );
    }

    try {
      // Ensure directory exists
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write file
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(content, encoding: utf8);

      _logger.i('Saved text file: $filePath (${content.length} characters)');
      return success(filePath);
    } on Exception catch (e, stack) {
      _logger.e('Failed to save text file: $fileName', error: e, stackTrace: stack);
      return failure(StorageFailure(details: 'Failed to save text file: $e'));
    }
  }
}
