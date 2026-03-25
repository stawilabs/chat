import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import '../networking/client.dart';
import 'files_config_service.dart';

/// Default chunk size for streaming uploads (256KB).
const int _uploadChunkSize = 256 * 1024;

/// Threshold for using multipart upload (100MB).
const int _multipartThreshold = 100 * 1024 * 1024;

/// Default part size for multipart uploads (5MB).
const int _multipartPartSize = 5 * 1024 * 1024;

/// Result of an upload operation using direct HTTP URLs.
class FilesUploadResult {
  const FilesUploadResult({
    required this.contentUri,
    required this.mediaId,
    required this.serverName,
  });

  /// The direct HTTP URL for the content.
  final String contentUri;

  /// The media ID component.
  final String mediaId;

  /// The server name component.
  final String serverName;

  /// Legacy-compatible file URL getter.
  ///
  /// Returns the HTTP URL for backward compatibility with code
  /// that expects a `fileUrl` field.
  String get fileUrl => contentUri;
}

/// Service for uploading files via the proto [FilesServiceClient.uploadContent]
/// streaming RPC.
///
/// Provides a unified streaming upload path that works for all file sizes.
class FilesUploadService {
  FilesUploadService(this._getClient, this._configService);

  final Future<FilesServiceClient> Function() _getClient;
  final FilesConfigService _configService;

  String get _baseUrl => _configService.baseUrl;

  /// Upload a [File] via streaming RPC.
  ///
  /// Reads the file in chunks to avoid loading it entirely into memory.
  /// Calls [onProgress] with values from 0.0 to 1.0 during upload.
  ///
  /// Throws [StateError] if the file exceeds the server's max upload size.
  Future<FilesUploadResult> uploadFile(
    File file, {
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final detectedMime = mimeType ?? _detectMimeType(fileName);

    await _validateFileSize(fileSize);

    final client = await _getClient();

    final controller = StreamController<UploadContentRequest>();

    // Send metadata first
    controller.add(
      UploadContentRequest(
        metadata: UploadMetadata(
          contentType: detectedMime,
          filename: fileName,
          totalSize: Int64(fileSize),
        ),
      ),
    );

    // Read and send chunks
    final randomAccess = await file.open();
    try {
      var bytesSent = 0;
      while (bytesSent < fileSize) {
        final remaining = fileSize - bytesSent;
        final chunkSize = remaining < _uploadChunkSize
            ? remaining
            : _uploadChunkSize;

        final chunkBytes = await randomAccess.read(chunkSize);
        controller.add(UploadContentRequest(chunk: chunkBytes));

        bytesSent += chunkSize;
        onProgress?.call(bytesSent / fileSize);
      }
    } finally {
      await randomAccess.close();
      await controller.close();
    }

    final response = await client.uploadContent(controller.stream);
    final uploadUrl = contentUrlFromResponse(_baseUrl, response);

    AppLogger.info(
      'File uploaded via HTTP',
      data: {'contentUrl': uploadUrl, 'fileName': fileName, 'size': fileSize},
    );

    return FilesUploadResult(
      contentUri: uploadUrl,
      mediaId: response.mediaId,
      serverName: response.serverName,
    );
  }

  /// Upload raw bytes via streaming RPC.
  /// Uses multipart upload for files larger than 100MB.
  Future<FilesUploadResult> uploadBytes(
    Uint8List bytes,
    String filename,
    String mimeType, {
    void Function(double progress)? onProgress,
  }) async {
    AppLogger.debug(
      'uploadBytes: starting upload of $filename, size: ${bytes.length}, mimeType: $mimeType',
    );

    await _validateFileSize(bytes.length);

    // Use multipart upload for large files
    if (bytes.length > _multipartThreshold) {
      return _uploadBytesMultipart(bytes, filename, mimeType, onProgress);
    }

    return _uploadBytesStreaming(bytes, filename, mimeType, onProgress);
  }

  /// Upload using streaming RPC (for files < 100MB).
  Future<FilesUploadResult> _uploadBytesStreaming(
    Uint8List bytes,
    String filename,
    String mimeType,
    void Function(double progress)? onProgress,
  ) async {
    final client = await _getClient();

    final controller = StreamController<UploadContentRequest>();

    controller.add(
      UploadContentRequest(
        metadata: UploadMetadata(
          contentType: mimeType,
          filename: filename,
          totalSize: Int64(bytes.length),
        ),
      ),
    );

    var bytesSent = 0;
    while (bytesSent < bytes.length) {
      final end = bytesSent + _uploadChunkSize;
      final chunkEnd = end > bytes.length ? bytes.length : end;
      final chunk = bytes.sublist(bytesSent, chunkEnd);

      controller.add(UploadContentRequest(chunk: chunk));

      bytesSent = chunkEnd;
      onProgress?.call(bytesSent / bytes.length);
    }

    await controller.close();

    final response = await client.uploadContent(controller.stream);
    final uploadUrl = contentUrlFromResponse(_baseUrl, response);

    AppLogger.debug('uploadBytes: response received: $uploadUrl');

    return FilesUploadResult(
      contentUri: uploadUrl,
      mediaId: response.mediaId,
      serverName: response.serverName,
    );
  }

  /// Upload using multipart upload (for files > 100MB).
  Future<FilesUploadResult> _uploadBytesMultipart(
    Uint8List bytes,
    String filename,
    String mimeType,
    void Function(double progress)? onProgress,
  ) async {
    final client = await _getClient();

    // Create multipart upload
    final createResponse = await client.createMultipartUpload(
      CreateMultipartUploadRequest(
        filename: filename,
        contentType: mimeType,
        totalSize: Int64(bytes.length),
      ),
    );

    final uploadId = createResponse.uploadId;
    AppLogger.debug(
      'uploadBytes: created multipart upload, uploadId: $uploadId',
    );

    // Upload parts
    final parts = <CompleteMultipartUploadRequest_Part>[];
    var bytesSent = 0;
    var partNumber = 1;

    while (bytesSent < bytes.length) {
      final end = bytesSent + _multipartPartSize;
      final partEnd = end > bytes.length ? bytes.length : end;
      final partData = bytes.sublist(bytesSent, partEnd);

      final partResponse = await client.uploadMultipartPart(
        UploadMultipartPartRequest(
          uploadId: uploadId,
          partNumber: partNumber,
          content: partData,
        ),
      );

      parts.add(
        CompleteMultipartUploadRequest_Part(
          partNumber: partNumber,
          etag: partResponse.etag,
        ),
      );

      bytesSent = partEnd;
      partNumber++;
      onProgress?.call(bytesSent / bytes.length);

      AppLogger.debug(
        'uploadBytes: uploaded part $partNumber, etag: ${partResponse.etag}',
      );
    }

    // Complete multipart upload
    final completeResponse = await client.completeMultipartUpload(
      CompleteMultipartUploadRequest(uploadId: uploadId, parts: parts),
    );

    final metadata = completeResponse.metadata;
    final mediaId = metadata.mediaId;
    final uploadUrl = metadata.contentUri.isNotEmpty
        ? metadata.contentUri
        : contentUrl(_baseUrl, mediaId);

    AppLogger.debug('uploadBytes: multipart upload complete: $uploadUrl');

    return FilesUploadResult(
      contentUri: uploadUrl,
      mediaId: mediaId,
      serverName: Uri.parse(_baseUrl).host,
    );
  }

  /// Upload a thumbnail image (convenience wrapper with simpler logging).
  Future<FilesUploadResult> uploadThumbnail(
    Uint8List bytes,
    String mimeType,
  ) async {
    final result = await uploadBytes(bytes, 'thumbnail', mimeType);

    AppLogger.debug(
      'Thumbnail uploaded',
      data: {'contentUri': result.contentUri, 'size': bytes.length},
    );

    return result;
  }

  /// Validate file size against server config.
  Future<void> _validateFileSize(int fileSize) async {
    final maxSize = await _configService.getMaxUploadSize();
    if (fileSize > maxSize) {
      throw StateError(
        'File size ($fileSize bytes) exceeds maximum upload size ($maxSize bytes)',
      );
    }
  }

  /// Detect MIME type from file extension.
  String _detectMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'webm' => 'video/webm',
      'mkv' => 'video/x-matroska',
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'ogg' => 'audio/ogg',
      'm4a' => 'audio/mp4',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      'json' => 'application/json',
      _ => 'application/octet-stream',
    };
  }
}

/// Provider for [FilesUploadService].
final filesUploadServiceProvider = Provider<FilesUploadService>((ref) {
  final configService = ref.watch(filesConfigServiceProvider);
  return FilesUploadService(
    () => ref.read(filesServiceClientProvider.future),
    configService,
  );
});
