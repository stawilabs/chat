// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadProgress {

/// Unique download ID for tracking
 String get downloadId;/// Progress percentage from 0.0 to 1.0
 double get progress;/// Current state of the download
 DownloadState get state;/// Error message if download failed
 String? get error;/// File name being downloaded
 String? get fileName;/// Remote file URL being downloaded
 String? get fileUrl;/// Local file path where download is saved
 String? get localPath;/// Total size of the file in bytes
 int? get totalBytes;/// Number of bytes downloaded so far
 int get downloadedBytes;/// Current chunk index for chunked downloads
 int get currentChunk;/// Total number of chunks for chunked downloads
 int get totalChunks;/// ETag for HTTP caching and resume validation
 String? get etag;/// Timestamp when download started
 int? get startedAt;/// Timestamp when download completed or failed
 int? get completedAt;/// Number of retry attempts
 int get retryCount;/// Whether this is a chunked download
 bool get isChunked;/// Room ID this download is associated with
 String? get roomId;/// MIME type of the file
 String? get mimeType;
/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadProgressCopyWith<DownloadProgress> get copyWith => _$DownloadProgressCopyWithImpl<DownloadProgress>(this as DownloadProgress, _$identity);

  /// Serializes this DownloadProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadProgress&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.currentChunk, currentChunk) || other.currentChunk == currentChunk)&&(identical(other.totalChunks, totalChunks) || other.totalChunks == totalChunks)&&(identical(other.etag, etag) || other.etag == etag)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.isChunked, isChunked) || other.isChunked == isChunked)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downloadId,progress,state,error,fileName,fileUrl,localPath,totalBytes,downloadedBytes,currentChunk,totalChunks,etag,startedAt,completedAt,retryCount,isChunked,roomId,mimeType);

@override
String toString() {
  return 'DownloadProgress(downloadId: $downloadId, progress: $progress, state: $state, error: $error, fileName: $fileName, fileUrl: $fileUrl, localPath: $localPath, totalBytes: $totalBytes, downloadedBytes: $downloadedBytes, currentChunk: $currentChunk, totalChunks: $totalChunks, etag: $etag, startedAt: $startedAt, completedAt: $completedAt, retryCount: $retryCount, isChunked: $isChunked, roomId: $roomId, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class $DownloadProgressCopyWith<$Res>  {
  factory $DownloadProgressCopyWith(DownloadProgress value, $Res Function(DownloadProgress) _then) = _$DownloadProgressCopyWithImpl;
@useResult
$Res call({
 String downloadId, double progress, DownloadState state, String? error, String? fileName, String? fileUrl, String? localPath, int? totalBytes, int downloadedBytes, int currentChunk, int totalChunks, String? etag, int? startedAt, int? completedAt, int retryCount, bool isChunked, String? roomId, String? mimeType
});




}
/// @nodoc
class _$DownloadProgressCopyWithImpl<$Res>
    implements $DownloadProgressCopyWith<$Res> {
  _$DownloadProgressCopyWithImpl(this._self, this._then);

  final DownloadProgress _self;
  final $Res Function(DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? downloadId = null,Object? progress = null,Object? state = null,Object? error = freezed,Object? fileName = freezed,Object? fileUrl = freezed,Object? localPath = freezed,Object? totalBytes = freezed,Object? downloadedBytes = null,Object? currentChunk = null,Object? totalChunks = null,Object? etag = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? retryCount = null,Object? isChunked = null,Object? roomId = freezed,Object? mimeType = freezed,}) {
  return _then(_self.copyWith(
downloadId: null == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DownloadState,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,currentChunk: null == currentChunk ? _self.currentChunk : currentChunk // ignore: cast_nullable_to_non_nullable
as int,totalChunks: null == totalChunks ? _self.totalChunks : totalChunks // ignore: cast_nullable_to_non_nullable
as int,etag: freezed == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,isChunked: null == isChunked ? _self.isChunked : isChunked // ignore: cast_nullable_to_non_nullable
as bool,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadProgress].
extension DownloadProgressPatterns on DownloadProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadProgress value)  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String downloadId,  double progress,  DownloadState state,  String? error,  String? fileName,  String? fileUrl,  String? localPath,  int? totalBytes,  int downloadedBytes,  int currentChunk,  int totalChunks,  String? etag,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked,  String? roomId,  String? mimeType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.downloadId,_that.progress,_that.state,_that.error,_that.fileName,_that.fileUrl,_that.localPath,_that.totalBytes,_that.downloadedBytes,_that.currentChunk,_that.totalChunks,_that.etag,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked,_that.roomId,_that.mimeType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String downloadId,  double progress,  DownloadState state,  String? error,  String? fileName,  String? fileUrl,  String? localPath,  int? totalBytes,  int downloadedBytes,  int currentChunk,  int totalChunks,  String? etag,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked,  String? roomId,  String? mimeType)  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress():
return $default(_that.downloadId,_that.progress,_that.state,_that.error,_that.fileName,_that.fileUrl,_that.localPath,_that.totalBytes,_that.downloadedBytes,_that.currentChunk,_that.totalChunks,_that.etag,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked,_that.roomId,_that.mimeType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String downloadId,  double progress,  DownloadState state,  String? error,  String? fileName,  String? fileUrl,  String? localPath,  int? totalBytes,  int downloadedBytes,  int currentChunk,  int totalChunks,  String? etag,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked,  String? roomId,  String? mimeType)?  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.downloadId,_that.progress,_that.state,_that.error,_that.fileName,_that.fileUrl,_that.localPath,_that.totalBytes,_that.downloadedBytes,_that.currentChunk,_that.totalChunks,_that.etag,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked,_that.roomId,_that.mimeType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadProgress extends DownloadProgress {
  const _DownloadProgress({required this.downloadId, this.progress = 0.0, this.state = DownloadState.pending, this.error, this.fileName, this.fileUrl, this.localPath, this.totalBytes, this.downloadedBytes = 0, this.currentChunk = 0, this.totalChunks = 1, this.etag, this.startedAt, this.completedAt, this.retryCount = 0, this.isChunked = false, this.roomId, this.mimeType}): super._();
  factory _DownloadProgress.fromJson(Map<String, dynamic> json) => _$DownloadProgressFromJson(json);

/// Unique download ID for tracking
@override final  String downloadId;
/// Progress percentage from 0.0 to 1.0
@override@JsonKey() final  double progress;
/// Current state of the download
@override@JsonKey() final  DownloadState state;
/// Error message if download failed
@override final  String? error;
/// File name being downloaded
@override final  String? fileName;
/// Remote file URL being downloaded
@override final  String? fileUrl;
/// Local file path where download is saved
@override final  String? localPath;
/// Total size of the file in bytes
@override final  int? totalBytes;
/// Number of bytes downloaded so far
@override@JsonKey() final  int downloadedBytes;
/// Current chunk index for chunked downloads
@override@JsonKey() final  int currentChunk;
/// Total number of chunks for chunked downloads
@override@JsonKey() final  int totalChunks;
/// ETag for HTTP caching and resume validation
@override final  String? etag;
/// Timestamp when download started
@override final  int? startedAt;
/// Timestamp when download completed or failed
@override final  int? completedAt;
/// Number of retry attempts
@override@JsonKey() final  int retryCount;
/// Whether this is a chunked download
@override@JsonKey() final  bool isChunked;
/// Room ID this download is associated with
@override final  String? roomId;
/// MIME type of the file
@override final  String? mimeType;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadProgressCopyWith<_DownloadProgress> get copyWith => __$DownloadProgressCopyWithImpl<_DownloadProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadProgress&&(identical(other.downloadId, downloadId) || other.downloadId == downloadId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.localPath, localPath) || other.localPath == localPath)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.currentChunk, currentChunk) || other.currentChunk == currentChunk)&&(identical(other.totalChunks, totalChunks) || other.totalChunks == totalChunks)&&(identical(other.etag, etag) || other.etag == etag)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.isChunked, isChunked) || other.isChunked == isChunked)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,downloadId,progress,state,error,fileName,fileUrl,localPath,totalBytes,downloadedBytes,currentChunk,totalChunks,etag,startedAt,completedAt,retryCount,isChunked,roomId,mimeType);

@override
String toString() {
  return 'DownloadProgress(downloadId: $downloadId, progress: $progress, state: $state, error: $error, fileName: $fileName, fileUrl: $fileUrl, localPath: $localPath, totalBytes: $totalBytes, downloadedBytes: $downloadedBytes, currentChunk: $currentChunk, totalChunks: $totalChunks, etag: $etag, startedAt: $startedAt, completedAt: $completedAt, retryCount: $retryCount, isChunked: $isChunked, roomId: $roomId, mimeType: $mimeType)';
}


}

/// @nodoc
abstract mixin class _$DownloadProgressCopyWith<$Res> implements $DownloadProgressCopyWith<$Res> {
  factory _$DownloadProgressCopyWith(_DownloadProgress value, $Res Function(_DownloadProgress) _then) = __$DownloadProgressCopyWithImpl;
@override @useResult
$Res call({
 String downloadId, double progress, DownloadState state, String? error, String? fileName, String? fileUrl, String? localPath, int? totalBytes, int downloadedBytes, int currentChunk, int totalChunks, String? etag, int? startedAt, int? completedAt, int retryCount, bool isChunked, String? roomId, String? mimeType
});




}
/// @nodoc
class __$DownloadProgressCopyWithImpl<$Res>
    implements _$DownloadProgressCopyWith<$Res> {
  __$DownloadProgressCopyWithImpl(this._self, this._then);

  final _DownloadProgress _self;
  final $Res Function(_DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? downloadId = null,Object? progress = null,Object? state = null,Object? error = freezed,Object? fileName = freezed,Object? fileUrl = freezed,Object? localPath = freezed,Object? totalBytes = freezed,Object? downloadedBytes = null,Object? currentChunk = null,Object? totalChunks = null,Object? etag = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? retryCount = null,Object? isChunked = null,Object? roomId = freezed,Object? mimeType = freezed,}) {
  return _then(_DownloadProgress(
downloadId: null == downloadId ? _self.downloadId : downloadId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as DownloadState,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,localPath: freezed == localPath ? _self.localPath : localPath // ignore: cast_nullable_to_non_nullable
as String?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,currentChunk: null == currentChunk ? _self.currentChunk : currentChunk // ignore: cast_nullable_to_non_nullable
as int,totalChunks: null == totalChunks ? _self.totalChunks : totalChunks // ignore: cast_nullable_to_non_nullable
as int,etag: freezed == etag ? _self.etag : etag // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,isChunked: null == isChunked ? _self.isChunked : isChunked // ignore: cast_nullable_to_non_nullable
as bool,roomId: freezed == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
