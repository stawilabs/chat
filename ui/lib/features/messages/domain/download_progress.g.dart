// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadProgress _$DownloadProgressFromJson(Map<String, dynamic> json) =>
    _DownloadProgress(
      downloadId: json['downloadId'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      state:
          $enumDecodeNullable(_$DownloadStateEnumMap, json['state']) ??
          DownloadState.pending,
      error: json['error'] as String?,
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      localPath: json['localPath'] as String?,
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      currentChunk: (json['currentChunk'] as num?)?.toInt() ?? 0,
      totalChunks: (json['totalChunks'] as num?)?.toInt() ?? 1,
      etag: json['etag'] as String?,
      startedAt: (json['startedAt'] as num?)?.toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      isChunked: json['isChunked'] as bool? ?? false,
      roomId: json['roomId'] as String?,
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$DownloadProgressToJson(_DownloadProgress instance) =>
    <String, dynamic>{
      'downloadId': instance.downloadId,
      'progress': instance.progress,
      'state': _$DownloadStateEnumMap[instance.state]!,
      'error': instance.error,
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'localPath': instance.localPath,
      'totalBytes': instance.totalBytes,
      'downloadedBytes': instance.downloadedBytes,
      'currentChunk': instance.currentChunk,
      'totalChunks': instance.totalChunks,
      'etag': instance.etag,
      'startedAt': instance.startedAt,
      'completedAt': instance.completedAt,
      'retryCount': instance.retryCount,
      'isChunked': instance.isChunked,
      'roomId': instance.roomId,
      'mimeType': instance.mimeType,
    };

const _$DownloadStateEnumMap = {
  DownloadState.pending: 'pending',
  DownloadState.downloading: 'downloading',
  DownloadState.completed: 'completed',
  DownloadState.failed: 'failed',
  DownloadState.cancelled: 'cancelled',
  DownloadState.paused: 'paused',
};
