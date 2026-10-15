import 'dart:typed_data';

import 'package:antinvestor_api_files/antinvestor_api_files.dart';
import 'package:connectrpc/test.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/files/files_config_service.dart';
import 'package:stawi/core/files/files_upload_service.dart';

/// The largest part service-files accepts: it holds a part in memory and
/// refuses one over 1.5 MiB (`maxInMemoryFileBytes`).
const int _serverMaxPartBytes = 1536 * 1024;

/// Multipart uploads start above 100 MB.
const int _multipartThreshold = 100 * 1024 * 1024;

void main() {
  test('a multipart part is at most 1 MiB, under the files service cap', () {
    expect(multipartPartSize, lessThanOrEqualTo(1024 * 1024));
    expect(multipartPartSize, lessThan(_serverMaxPartBytes));
  });

  test(
    'a large upload goes up in contiguous parts the files service accepts',
    () async {
      final parts = <UploadMultipartPartRequest>[];
      CompleteMultipartUploadRequest? completed;

      final transport = FakeTransportBuilder()
          .unary(
            FilesService.getConfig,
            (_, _) => GetConfigResponse(maxUploadBytes: Int64(1 << 30)),
          )
          .unary(
            FilesService.createMultipartUpload,
            (_, _) => CreateMultipartUploadResponse(uploadId: 'up-1'),
          )
          .unary(FilesService.uploadMultipartPart, (req, _) {
            // Refuse what the server refuses, so an oversized part fails here
            // as it would against service-files.
            if (req.content.length > _serverMaxPartBytes) {
              throw StateError('part ${req.partNumber} is too large');
            }
            parts.add(req);
            return UploadMultipartPartResponse(
              etag: 'etag-${req.partNumber}',
              partNumber: req.partNumber,
              size: Int64(req.content.length),
            );
          })
          .unary(FilesService.completeMultipartUpload, (req, _) {
            completed = req;
            return CompleteMultipartUploadResponse(
              metadata: MediaMetadata(
                mediaId: 'media-1',
                contentUri: 'https://files.test/media-1',
              ),
            );
          })
          .build();
      final client = FilesServiceClient(transport);
      final service = FilesUploadService(
        () async => client,
        FilesConfigService(() async => client),
      );

      // Just over the multipart threshold, with a short final part.
      const size = _multipartThreshold + multipartPartSize + 12345;
      final bytes = Uint8List(size);
      for (var i = 0; i < size; i += 4096) {
        bytes[i] = i ~/ 4096 % 251;
      }
      final progress = <double>[];

      final result = await service.uploadBytes(
        bytes,
        'big.bin',
        'application/octet-stream',
        onProgress: progress.add,
      );

      expect(result.mediaId, 'media-1');
      expect(result.contentUri, 'https://files.test/media-1');

      const expectedParts = (size + multipartPartSize - 1) ~/ multipartPartSize;
      expect(parts, hasLength(expectedParts));
      var offset = 0;
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        expect(part.uploadId, 'up-1');
        expect(part.partNumber, i + 1);
        expect(part.content.length, lessThanOrEqualTo(multipartPartSize));
        expect(part.content.first, bytes[offset], reason: 'part ${i + 1}');
        offset += part.content.length;
      }
      expect(offset, size, reason: 'the parts carry every byte once');
      expect(parts.last.content.length, 12345);

      expect(completed?.uploadId, 'up-1');
      expect(completed?.parts.map((p) => p.partNumber), [
        for (var n = 1; n <= expectedParts; n++) n,
      ]);
      expect(completed?.parts.map((p) => p.etag), [
        for (var n = 1; n <= expectedParts; n++) 'etag-$n',
      ]);
      expect(progress.last, 1.0);
    },
  );
}
