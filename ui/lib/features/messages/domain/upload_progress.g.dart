// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UploadProgress _$UploadProgressFromJson(Map<String, dynamic> json) =>
    _UploadProgress(
      localId: json['localId'] as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      state:
          $enumDecodeNullable(_$UploadStateEnumMap, json['state']) ??
          UploadState.pending,
      error: json['error'] as String?,
      fileName: json['fileName'] as String?,
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      uploadedBytes: (json['uploadedBytes'] as num?)?.toInt() ?? 0,
      currentChunk: (json['currentChunk'] as num?)?.toInt() ?? 0,
      totalChunks: (json['totalChunks'] as num?)?.toInt() ?? 1,
      uploadId: json['uploadId'] as String?,
      startedAt: (json['startedAt'] as num?)?.toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      isChunked: json['isChunked'] as bool? ?? false,
    );

Map<String, dynamic> _$UploadProgressToJson(_UploadProgress instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'progress': instance.progress,
      'state': _$UploadStateEnumMap[instance.state]!,
      'error': instance.error,
      'fileName': instance.fileName,
      'totalBytes': instance.totalBytes,
      'uploadedBytes': instance.uploadedBytes,
      'currentChunk': instance.currentChunk,
      'totalChunks': instance.totalChunks,
      'uploadId': instance.uploadId,
      'startedAt': instance.startedAt,
      'completedAt': instance.completedAt,
      'retryCount': instance.retryCount,
      'isChunked': instance.isChunked,
    };

const _$UploadStateEnumMap = {
  UploadState.pending: 'pending',
  UploadState.uploading: 'uploading',
  UploadState.completed: 'completed',
  UploadState.failed: 'failed',
  UploadState.cancelled: 'cancelled',
  UploadState.paused: 'paused',
};
