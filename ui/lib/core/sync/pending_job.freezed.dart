// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingJob {

 int get id; JobType get type; Map<String, dynamic> get payload; int get createdAt; int get retryCount; String get status; int? get nextRetryAt;
/// Create a copy of PendingJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingJobCopyWith<PendingJob> get copyWith => _$PendingJobCopyWithImpl<PendingJob>(this as PendingJob, _$identity);

  /// Serializes this PendingJob to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingJob&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(payload),createdAt,retryCount,status,nextRetryAt);

@override
String toString() {
  return 'PendingJob(id: $id, type: $type, payload: $payload, createdAt: $createdAt, retryCount: $retryCount, status: $status, nextRetryAt: $nextRetryAt)';
}


}

/// @nodoc
abstract mixin class $PendingJobCopyWith<$Res>  {
  factory $PendingJobCopyWith(PendingJob value, $Res Function(PendingJob) _then) = _$PendingJobCopyWithImpl;
@useResult
$Res call({
 int id, JobType type, Map<String, dynamic> payload, int createdAt, int retryCount, String status, int? nextRetryAt
});




}
/// @nodoc
class _$PendingJobCopyWithImpl<$Res>
    implements $PendingJobCopyWith<$Res> {
  _$PendingJobCopyWithImpl(this._self, this._then);

  final PendingJob _self;
  final $Res Function(PendingJob) _then;

/// Create a copy of PendingJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? retryCount = null,Object? status = null,Object? nextRetryAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as JobType,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingJob].
extension PendingJobPatterns on PendingJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingJob value)  $default,){
final _that = this;
switch (_that) {
case _PendingJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingJob value)?  $default,){
final _that = this;
switch (_that) {
case _PendingJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  JobType type,  Map<String, dynamic> payload,  int createdAt,  int retryCount,  String status,  int? nextRetryAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingJob() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.createdAt,_that.retryCount,_that.status,_that.nextRetryAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  JobType type,  Map<String, dynamic> payload,  int createdAt,  int retryCount,  String status,  int? nextRetryAt)  $default,) {final _that = this;
switch (_that) {
case _PendingJob():
return $default(_that.id,_that.type,_that.payload,_that.createdAt,_that.retryCount,_that.status,_that.nextRetryAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  JobType type,  Map<String, dynamic> payload,  int createdAt,  int retryCount,  String status,  int? nextRetryAt)?  $default,) {final _that = this;
switch (_that) {
case _PendingJob() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.createdAt,_that.retryCount,_that.status,_that.nextRetryAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingJob implements PendingJob {
  const _PendingJob({required this.id, required this.type, required final  Map<String, dynamic> payload, required this.createdAt, this.retryCount = 0, this.status = 'pending', this.nextRetryAt}): _payload = payload;
  factory _PendingJob.fromJson(Map<String, dynamic> json) => _$PendingJobFromJson(json);

@override final  int id;
@override final  JobType type;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  int createdAt;
@override@JsonKey() final  int retryCount;
@override@JsonKey() final  String status;
@override final  int? nextRetryAt;

/// Create a copy of PendingJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingJobCopyWith<_PendingJob> get copyWith => __$PendingJobCopyWithImpl<_PendingJob>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingJobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingJob&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(_payload),createdAt,retryCount,status,nextRetryAt);

@override
String toString() {
  return 'PendingJob(id: $id, type: $type, payload: $payload, createdAt: $createdAt, retryCount: $retryCount, status: $status, nextRetryAt: $nextRetryAt)';
}


}

/// @nodoc
abstract mixin class _$PendingJobCopyWith<$Res> implements $PendingJobCopyWith<$Res> {
  factory _$PendingJobCopyWith(_PendingJob value, $Res Function(_PendingJob) _then) = __$PendingJobCopyWithImpl;
@override @useResult
$Res call({
 int id, JobType type, Map<String, dynamic> payload, int createdAt, int retryCount, String status, int? nextRetryAt
});




}
/// @nodoc
class __$PendingJobCopyWithImpl<$Res>
    implements _$PendingJobCopyWith<$Res> {
  __$PendingJobCopyWithImpl(this._self, this._then);

  final _PendingJob _self;
  final $Res Function(_PendingJob) _then;

/// Create a copy of PendingJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? createdAt = null,Object? retryCount = null,Object? status = null,Object? nextRetryAt = freezed,}) {
  return _then(_PendingJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as JobType,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
