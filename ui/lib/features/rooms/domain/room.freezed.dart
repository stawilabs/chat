// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Room {

 String get id; String get name; String get type;// 'direct' or 'group'
 String? get lastEventId; int get lastEventIndex; int get unreadCount; Map<String, dynamic>? get metadata;/// Disappearing messages timeout in seconds (null = disabled)
/// Supported values: null (off), 86400 (24h), 604800 (7d), 7776000 (90d)
 int? get disappearingTimeout;/// Mute notifications until this timestamp (milliseconds since epoch)
/// - null = not muted
/// - 0 = muted forever
/// - timestamp = muted until that time
 int? get mutedUntil;/// Maximum number of members allowed (null = default 256)
 int? get memberLimit;/// Whether member limit is enforced
 bool get memberLimitEnabled;
/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomCopyWith<Room> get copyWith => _$RoomCopyWithImpl<Room>(this as Room, _$identity);

  /// Serializes this Room to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.lastEventId, lastEventId) || other.lastEventId == lastEventId)&&(identical(other.lastEventIndex, lastEventIndex) || other.lastEventIndex == lastEventIndex)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.disappearingTimeout, disappearingTimeout) || other.disappearingTimeout == disappearingTimeout)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil)&&(identical(other.memberLimit, memberLimit) || other.memberLimit == memberLimit)&&(identical(other.memberLimitEnabled, memberLimitEnabled) || other.memberLimitEnabled == memberLimitEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,lastEventId,lastEventIndex,unreadCount,const DeepCollectionEquality().hash(metadata),disappearingTimeout,mutedUntil,memberLimit,memberLimitEnabled);

@override
String toString() {
  return 'Room(id: $id, name: $name, type: $type, lastEventId: $lastEventId, lastEventIndex: $lastEventIndex, unreadCount: $unreadCount, metadata: $metadata, disappearingTimeout: $disappearingTimeout, mutedUntil: $mutedUntil, memberLimit: $memberLimit, memberLimitEnabled: $memberLimitEnabled)';
}


}

/// @nodoc
abstract mixin class $RoomCopyWith<$Res>  {
  factory $RoomCopyWith(Room value, $Res Function(Room) _then) = _$RoomCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, String? lastEventId, int lastEventIndex, int unreadCount, Map<String, dynamic>? metadata, int? disappearingTimeout, int? mutedUntil, int? memberLimit, bool memberLimitEnabled
});




}
/// @nodoc
class _$RoomCopyWithImpl<$Res>
    implements $RoomCopyWith<$Res> {
  _$RoomCopyWithImpl(this._self, this._then);

  final Room _self;
  final $Res Function(Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? lastEventId = freezed,Object? lastEventIndex = null,Object? unreadCount = null,Object? metadata = freezed,Object? disappearingTimeout = freezed,Object? mutedUntil = freezed,Object? memberLimit = freezed,Object? memberLimitEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,lastEventId: freezed == lastEventId ? _self.lastEventId : lastEventId // ignore: cast_nullable_to_non_nullable
as String?,lastEventIndex: null == lastEventIndex ? _self.lastEventIndex : lastEventIndex // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,disappearingTimeout: freezed == disappearingTimeout ? _self.disappearingTimeout : disappearingTimeout // ignore: cast_nullable_to_non_nullable
as int?,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as int?,memberLimit: freezed == memberLimit ? _self.memberLimit : memberLimit // ignore: cast_nullable_to_non_nullable
as int?,memberLimitEnabled: null == memberLimitEnabled ? _self.memberLimitEnabled : memberLimitEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Room].
extension RoomPatterns on Room {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Room value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Room value)  $default,){
final _that = this;
switch (_that) {
case _Room():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Room value)?  $default,){
final _that = this;
switch (_that) {
case _Room() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? lastEventId,  int lastEventIndex,  int unreadCount,  Map<String, dynamic>? metadata,  int? disappearingTimeout,  int? mutedUntil,  int? memberLimit,  bool memberLimitEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.lastEventId,_that.lastEventIndex,_that.unreadCount,_that.metadata,_that.disappearingTimeout,_that.mutedUntil,_that.memberLimit,_that.memberLimitEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  String? lastEventId,  int lastEventIndex,  int unreadCount,  Map<String, dynamic>? metadata,  int? disappearingTimeout,  int? mutedUntil,  int? memberLimit,  bool memberLimitEnabled)  $default,) {final _that = this;
switch (_that) {
case _Room():
return $default(_that.id,_that.name,_that.type,_that.lastEventId,_that.lastEventIndex,_that.unreadCount,_that.metadata,_that.disappearingTimeout,_that.mutedUntil,_that.memberLimit,_that.memberLimitEnabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  String? lastEventId,  int lastEventIndex,  int unreadCount,  Map<String, dynamic>? metadata,  int? disappearingTimeout,  int? mutedUntil,  int? memberLimit,  bool memberLimitEnabled)?  $default,) {final _that = this;
switch (_that) {
case _Room() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.lastEventId,_that.lastEventIndex,_that.unreadCount,_that.metadata,_that.disappearingTimeout,_that.mutedUntil,_that.memberLimit,_that.memberLimitEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Room extends Room {
  const _Room({required this.id, required this.name, required this.type, this.lastEventId, this.lastEventIndex = 0, this.unreadCount = 0, final  Map<String, dynamic>? metadata, this.disappearingTimeout, this.mutedUntil, this.memberLimit, this.memberLimitEnabled = true}): _metadata = metadata,super._();
  factory _Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

@override final  String id;
@override final  String name;
@override final  String type;
// 'direct' or 'group'
@override final  String? lastEventId;
@override@JsonKey() final  int lastEventIndex;
@override@JsonKey() final  int unreadCount;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Disappearing messages timeout in seconds (null = disabled)
/// Supported values: null (off), 86400 (24h), 604800 (7d), 7776000 (90d)
@override final  int? disappearingTimeout;
/// Mute notifications until this timestamp (milliseconds since epoch)
/// - null = not muted
/// - 0 = muted forever
/// - timestamp = muted until that time
@override final  int? mutedUntil;
/// Maximum number of members allowed (null = default 256)
@override final  int? memberLimit;
/// Whether member limit is enforced
@override@JsonKey() final  bool memberLimitEnabled;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomCopyWith<_Room> get copyWith => __$RoomCopyWithImpl<_Room>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Room&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.lastEventId, lastEventId) || other.lastEventId == lastEventId)&&(identical(other.lastEventIndex, lastEventIndex) || other.lastEventIndex == lastEventIndex)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.disappearingTimeout, disappearingTimeout) || other.disappearingTimeout == disappearingTimeout)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil)&&(identical(other.memberLimit, memberLimit) || other.memberLimit == memberLimit)&&(identical(other.memberLimitEnabled, memberLimitEnabled) || other.memberLimitEnabled == memberLimitEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,type,lastEventId,lastEventIndex,unreadCount,const DeepCollectionEquality().hash(_metadata),disappearingTimeout,mutedUntil,memberLimit,memberLimitEnabled);

@override
String toString() {
  return 'Room(id: $id, name: $name, type: $type, lastEventId: $lastEventId, lastEventIndex: $lastEventIndex, unreadCount: $unreadCount, metadata: $metadata, disappearingTimeout: $disappearingTimeout, mutedUntil: $mutedUntil, memberLimit: $memberLimit, memberLimitEnabled: $memberLimitEnabled)';
}


}

/// @nodoc
abstract mixin class _$RoomCopyWith<$Res> implements $RoomCopyWith<$Res> {
  factory _$RoomCopyWith(_Room value, $Res Function(_Room) _then) = __$RoomCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, String? lastEventId, int lastEventIndex, int unreadCount, Map<String, dynamic>? metadata, int? disappearingTimeout, int? mutedUntil, int? memberLimit, bool memberLimitEnabled
});




}
/// @nodoc
class __$RoomCopyWithImpl<$Res>
    implements _$RoomCopyWith<$Res> {
  __$RoomCopyWithImpl(this._self, this._then);

  final _Room _self;
  final $Res Function(_Room) _then;

/// Create a copy of Room
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? lastEventId = freezed,Object? lastEventIndex = null,Object? unreadCount = null,Object? metadata = freezed,Object? disappearingTimeout = freezed,Object? mutedUntil = freezed,Object? memberLimit = freezed,Object? memberLimitEnabled = null,}) {
  return _then(_Room(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,lastEventId: freezed == lastEventId ? _self.lastEventId : lastEventId // ignore: cast_nullable_to_non_nullable
as String?,lastEventIndex: null == lastEventIndex ? _self.lastEventIndex : lastEventIndex // ignore: cast_nullable_to_non_nullable
as int,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,disappearingTimeout: freezed == disappearingTimeout ? _self.disappearingTimeout : disappearingTimeout // ignore: cast_nullable_to_non_nullable
as int?,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as int?,memberLimit: freezed == memberLimit ? _self.memberLimit : memberLimit // ignore: cast_nullable_to_non_nullable
as int?,memberLimitEnabled: null == memberLimitEnabled ? _self.memberLimitEnabled : memberLimitEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
