// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UploadProgress {

/// Local message ID for tracking
 String get localId;/// Progress percentage from 0.0 to 1.0
 double get progress;/// Current state of the upload
 UploadState get state;/// Error message if upload failed
 String? get error;/// Original file name being uploaded
 String? get fileName;/// Total size of the file in bytes
 int? get totalBytes;/// Number of bytes uploaded so far
 int get uploadedBytes;/// Current chunk index for chunked uploads
 int get currentChunk;/// Total number of chunks for chunked uploads
 int get totalChunks;/// Upload ID from server (for resumable uploads)
 String? get uploadId;/// Timestamp when upload started
 int? get startedAt;/// Timestamp when upload completed or failed
 int? get completedAt;/// Number of retry attempts
 int get retryCount;/// Whether this is a chunked upload
 bool get isChunked;
/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadProgressCopyWith<UploadProgress> get copyWith => _$UploadProgressCopyWithImpl<UploadProgress>(this as UploadProgress, _$identity);

  /// Serializes this UploadProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadProgress&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.uploadedBytes, uploadedBytes) || other.uploadedBytes == uploadedBytes)&&(identical(other.currentChunk, currentChunk) || other.currentChunk == currentChunk)&&(identical(other.totalChunks, totalChunks) || other.totalChunks == totalChunks)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.isChunked, isChunked) || other.isChunked == isChunked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,localId,progress,state,error,fileName,totalBytes,uploadedBytes,currentChunk,totalChunks,uploadId,startedAt,completedAt,retryCount,isChunked);

@override
String toString() {
  return 'UploadProgress(localId: $localId, progress: $progress, state: $state, error: $error, fileName: $fileName, totalBytes: $totalBytes, uploadedBytes: $uploadedBytes, currentChunk: $currentChunk, totalChunks: $totalChunks, uploadId: $uploadId, startedAt: $startedAt, completedAt: $completedAt, retryCount: $retryCount, isChunked: $isChunked)';
}


}

/// @nodoc
abstract mixin class $UploadProgressCopyWith<$Res>  {
  factory $UploadProgressCopyWith(UploadProgress value, $Res Function(UploadProgress) _then) = _$UploadProgressCopyWithImpl;
@useResult
$Res call({
 String localId, double progress, UploadState state, String? error, String? fileName, int? totalBytes, int uploadedBytes, int currentChunk, int totalChunks, String? uploadId, int? startedAt, int? completedAt, int retryCount, bool isChunked
});




}
/// @nodoc
class _$UploadProgressCopyWithImpl<$Res>
    implements $UploadProgressCopyWith<$Res> {
  _$UploadProgressCopyWithImpl(this._self, this._then);

  final UploadProgress _self;
  final $Res Function(UploadProgress) _then;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? progress = null,Object? state = null,Object? error = freezed,Object? fileName = freezed,Object? totalBytes = freezed,Object? uploadedBytes = null,Object? currentChunk = null,Object? totalChunks = null,Object? uploadId = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? retryCount = null,Object? isChunked = null,}) {
  return _then(_self.copyWith(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as UploadState,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,uploadedBytes: null == uploadedBytes ? _self.uploadedBytes : uploadedBytes // ignore: cast_nullable_to_non_nullable
as int,currentChunk: null == currentChunk ? _self.currentChunk : currentChunk // ignore: cast_nullable_to_non_nullable
as int,totalChunks: null == totalChunks ? _self.totalChunks : totalChunks // ignore: cast_nullable_to_non_nullable
as int,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,isChunked: null == isChunked ? _self.isChunked : isChunked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UploadProgress].
extension UploadProgressPatterns on UploadProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadProgress value)  $default,){
final _that = this;
switch (_that) {
case _UploadProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localId,  double progress,  UploadState state,  String? error,  String? fileName,  int? totalBytes,  int uploadedBytes,  int currentChunk,  int totalChunks,  String? uploadId,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
return $default(_that.localId,_that.progress,_that.state,_that.error,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.currentChunk,_that.totalChunks,_that.uploadId,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localId,  double progress,  UploadState state,  String? error,  String? fileName,  int? totalBytes,  int uploadedBytes,  int currentChunk,  int totalChunks,  String? uploadId,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked)  $default,) {final _that = this;
switch (_that) {
case _UploadProgress():
return $default(_that.localId,_that.progress,_that.state,_that.error,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.currentChunk,_that.totalChunks,_that.uploadId,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localId,  double progress,  UploadState state,  String? error,  String? fileName,  int? totalBytes,  int uploadedBytes,  int currentChunk,  int totalChunks,  String? uploadId,  int? startedAt,  int? completedAt,  int retryCount,  bool isChunked)?  $default,) {final _that = this;
switch (_that) {
case _UploadProgress() when $default != null:
return $default(_that.localId,_that.progress,_that.state,_that.error,_that.fileName,_that.totalBytes,_that.uploadedBytes,_that.currentChunk,_that.totalChunks,_that.uploadId,_that.startedAt,_that.completedAt,_that.retryCount,_that.isChunked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UploadProgress extends UploadProgress {
  const _UploadProgress({required this.localId, this.progress = 0.0, this.state = UploadState.pending, this.error, this.fileName, this.totalBytes, this.uploadedBytes = 0, this.currentChunk = 0, this.totalChunks = 1, this.uploadId, this.startedAt, this.completedAt, this.retryCount = 0, this.isChunked = false}): super._();
  factory _UploadProgress.fromJson(Map<String, dynamic> json) => _$UploadProgressFromJson(json);

/// Local message ID for tracking
@override final  String localId;
/// Progress percentage from 0.0 to 1.0
@override@JsonKey() final  double progress;
/// Current state of the upload
@override@JsonKey() final  UploadState state;
/// Error message if upload failed
@override final  String? error;
/// Original file name being uploaded
@override final  String? fileName;
/// Total size of the file in bytes
@override final  int? totalBytes;
/// Number of bytes uploaded so far
@override@JsonKey() final  int uploadedBytes;
/// Current chunk index for chunked uploads
@override@JsonKey() final  int currentChunk;
/// Total number of chunks for chunked uploads
@override@JsonKey() final  int totalChunks;
/// Upload ID from server (for resumable uploads)
@override final  String? uploadId;
/// Timestamp when upload started
@override final  int? startedAt;
/// Timestamp when upload completed or failed
@override final  int? completedAt;
/// Number of retry attempts
@override@JsonKey() final  int retryCount;
/// Whether this is a chunked upload
@override@JsonKey() final  bool isChunked;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadProgressCopyWith<_UploadProgress> get copyWith => __$UploadProgressCopyWithImpl<_UploadProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UploadProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadProgress&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.state, state) || other.state == state)&&(identical(other.error, error) || other.error == error)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.uploadedBytes, uploadedBytes) || other.uploadedBytes == uploadedBytes)&&(identical(other.currentChunk, currentChunk) || other.currentChunk == currentChunk)&&(identical(other.totalChunks, totalChunks) || other.totalChunks == totalChunks)&&(identical(other.uploadId, uploadId) || other.uploadId == uploadId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.isChunked, isChunked) || other.isChunked == isChunked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,localId,progress,state,error,fileName,totalBytes,uploadedBytes,currentChunk,totalChunks,uploadId,startedAt,completedAt,retryCount,isChunked);

@override
String toString() {
  return 'UploadProgress(localId: $localId, progress: $progress, state: $state, error: $error, fileName: $fileName, totalBytes: $totalBytes, uploadedBytes: $uploadedBytes, currentChunk: $currentChunk, totalChunks: $totalChunks, uploadId: $uploadId, startedAt: $startedAt, completedAt: $completedAt, retryCount: $retryCount, isChunked: $isChunked)';
}


}

/// @nodoc
abstract mixin class _$UploadProgressCopyWith<$Res> implements $UploadProgressCopyWith<$Res> {
  factory _$UploadProgressCopyWith(_UploadProgress value, $Res Function(_UploadProgress) _then) = __$UploadProgressCopyWithImpl;
@override @useResult
$Res call({
 String localId, double progress, UploadState state, String? error, String? fileName, int? totalBytes, int uploadedBytes, int currentChunk, int totalChunks, String? uploadId, int? startedAt, int? completedAt, int retryCount, bool isChunked
});




}
/// @nodoc
class __$UploadProgressCopyWithImpl<$Res>
    implements _$UploadProgressCopyWith<$Res> {
  __$UploadProgressCopyWithImpl(this._self, this._then);

  final _UploadProgress _self;
  final $Res Function(_UploadProgress) _then;

/// Create a copy of UploadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? progress = null,Object? state = null,Object? error = freezed,Object? fileName = freezed,Object? totalBytes = freezed,Object? uploadedBytes = null,Object? currentChunk = null,Object? totalChunks = null,Object? uploadId = freezed,Object? startedAt = freezed,Object? completedAt = freezed,Object? retryCount = null,Object? isChunked = null,}) {
  return _then(_UploadProgress(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as UploadState,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,fileName: freezed == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String?,totalBytes: freezed == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int?,uploadedBytes: null == uploadedBytes ? _self.uploadedBytes : uploadedBytes // ignore: cast_nullable_to_non_nullable
as int,currentChunk: null == currentChunk ? _self.currentChunk : currentChunk // ignore: cast_nullable_to_non_nullable
as int,totalChunks: null == totalChunks ? _self.totalChunks : totalChunks // ignore: cast_nullable_to_non_nullable
as int,uploadId: freezed == uploadId ? _self.uploadId : uploadId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,isChunked: null == isChunked ? _self.isChunked : isChunked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
