// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoomEvent {

 String get id; String get roomId; String get senderId; RoomEventType get type; Map<String, dynamic> get content; int get createdAt; String? get senderContactId; String? get parentId; EventStatus get status; int? get serverTs; String? get localId; int? get editedAt; bool get redacted; int? get redactedAt; String? get redactedBy; int get retryCount; String? get errorMessage; String? get forwardedFromRoom; String? get forwardedFromEvent; int get forwardCount; bool get forwardRestricted; int? get expiresAt; bool get starred; int? get starredAt;
/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomEventCopyWith<RoomEvent> get copyWith => _$RoomEventCopyWithImpl<RoomEvent>(this as RoomEvent, _$identity);

  /// Serializes this RoomEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderContactId, senderContactId) || other.senderContactId == senderContactId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.serverTs, serverTs) || other.serverTs == serverTs)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.redacted, redacted) || other.redacted == redacted)&&(identical(other.redactedAt, redactedAt) || other.redactedAt == redactedAt)&&(identical(other.redactedBy, redactedBy) || other.redactedBy == redactedBy)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.forwardedFromRoom, forwardedFromRoom) || other.forwardedFromRoom == forwardedFromRoom)&&(identical(other.forwardedFromEvent, forwardedFromEvent) || other.forwardedFromEvent == forwardedFromEvent)&&(identical(other.forwardCount, forwardCount) || other.forwardCount == forwardCount)&&(identical(other.forwardRestricted, forwardRestricted) || other.forwardRestricted == forwardRestricted)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,senderId,type,const DeepCollectionEquality().hash(content),createdAt,senderContactId,parentId,status,serverTs,localId,editedAt,redacted,redactedAt,redactedBy,retryCount,errorMessage,forwardedFromRoom,forwardedFromEvent,forwardCount,forwardRestricted,expiresAt,starred,starredAt]);

@override
String toString() {
  return 'RoomEvent(id: $id, roomId: $roomId, senderId: $senderId, type: $type, content: $content, createdAt: $createdAt, senderContactId: $senderContactId, parentId: $parentId, status: $status, serverTs: $serverTs, localId: $localId, editedAt: $editedAt, redacted: $redacted, redactedAt: $redactedAt, redactedBy: $redactedBy, retryCount: $retryCount, errorMessage: $errorMessage, forwardedFromRoom: $forwardedFromRoom, forwardedFromEvent: $forwardedFromEvent, forwardCount: $forwardCount, forwardRestricted: $forwardRestricted, expiresAt: $expiresAt, starred: $starred, starredAt: $starredAt)';
}


}

/// @nodoc
abstract mixin class $RoomEventCopyWith<$Res>  {
  factory $RoomEventCopyWith(RoomEvent value, $Res Function(RoomEvent) _then) = _$RoomEventCopyWithImpl;
@useResult
$Res call({
 String id, String roomId, String senderId, RoomEventType type, Map<String, dynamic> content, int createdAt, String? senderContactId, String? parentId, EventStatus status, int? serverTs, String? localId, int? editedAt, bool redacted, int? redactedAt, String? redactedBy, int retryCount, String? errorMessage, String? forwardedFromRoom, String? forwardedFromEvent, int forwardCount, bool forwardRestricted, int? expiresAt, bool starred, int? starredAt
});




}
/// @nodoc
class _$RoomEventCopyWithImpl<$Res>
    implements $RoomEventCopyWith<$Res> {
  _$RoomEventCopyWithImpl(this._self, this._then);

  final RoomEvent _self;
  final $Res Function(RoomEvent) _then;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? senderId = null,Object? type = null,Object? content = null,Object? createdAt = null,Object? senderContactId = freezed,Object? parentId = freezed,Object? status = null,Object? serverTs = freezed,Object? localId = freezed,Object? editedAt = freezed,Object? redacted = null,Object? redactedAt = freezed,Object? redactedBy = freezed,Object? retryCount = null,Object? errorMessage = freezed,Object? forwardedFromRoom = freezed,Object? forwardedFromEvent = freezed,Object? forwardCount = null,Object? forwardRestricted = null,Object? expiresAt = freezed,Object? starred = null,Object? starredAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomEventType,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,senderContactId: freezed == senderContactId ? _self.senderContactId : senderContactId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,serverTs: freezed == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int?,localId: freezed == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as int?,redacted: null == redacted ? _self.redacted : redacted // ignore: cast_nullable_to_non_nullable
as bool,redactedAt: freezed == redactedAt ? _self.redactedAt : redactedAt // ignore: cast_nullable_to_non_nullable
as int?,redactedBy: freezed == redactedBy ? _self.redactedBy : redactedBy // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,forwardedFromRoom: freezed == forwardedFromRoom ? _self.forwardedFromRoom : forwardedFromRoom // ignore: cast_nullable_to_non_nullable
as String?,forwardedFromEvent: freezed == forwardedFromEvent ? _self.forwardedFromEvent : forwardedFromEvent // ignore: cast_nullable_to_non_nullable
as String?,forwardCount: null == forwardCount ? _self.forwardCount : forwardCount // ignore: cast_nullable_to_non_nullable
as int,forwardRestricted: null == forwardRestricted ? _self.forwardRestricted : forwardRestricted // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,starred: null == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as bool,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomEvent].
extension RoomEventPatterns on RoomEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomEvent value)  $default,){
final _that = this;
switch (_that) {
case _RoomEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomEvent value)?  $default,){
final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomId,  String senderId,  RoomEventType type,  Map<String, dynamic> content,  int createdAt,  String? senderContactId,  String? parentId,  EventStatus status,  int? serverTs,  String? localId,  int? editedAt,  bool redacted,  int? redactedAt,  String? redactedBy,  int retryCount,  String? errorMessage,  String? forwardedFromRoom,  String? forwardedFromEvent,  int forwardCount,  bool forwardRestricted,  int? expiresAt,  bool starred,  int? starredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
return $default(_that.id,_that.roomId,_that.senderId,_that.type,_that.content,_that.createdAt,_that.senderContactId,_that.parentId,_that.status,_that.serverTs,_that.localId,_that.editedAt,_that.redacted,_that.redactedAt,_that.redactedBy,_that.retryCount,_that.errorMessage,_that.forwardedFromRoom,_that.forwardedFromEvent,_that.forwardCount,_that.forwardRestricted,_that.expiresAt,_that.starred,_that.starredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomId,  String senderId,  RoomEventType type,  Map<String, dynamic> content,  int createdAt,  String? senderContactId,  String? parentId,  EventStatus status,  int? serverTs,  String? localId,  int? editedAt,  bool redacted,  int? redactedAt,  String? redactedBy,  int retryCount,  String? errorMessage,  String? forwardedFromRoom,  String? forwardedFromEvent,  int forwardCount,  bool forwardRestricted,  int? expiresAt,  bool starred,  int? starredAt)  $default,) {final _that = this;
switch (_that) {
case _RoomEvent():
return $default(_that.id,_that.roomId,_that.senderId,_that.type,_that.content,_that.createdAt,_that.senderContactId,_that.parentId,_that.status,_that.serverTs,_that.localId,_that.editedAt,_that.redacted,_that.redactedAt,_that.redactedBy,_that.retryCount,_that.errorMessage,_that.forwardedFromRoom,_that.forwardedFromEvent,_that.forwardCount,_that.forwardRestricted,_that.expiresAt,_that.starred,_that.starredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomId,  String senderId,  RoomEventType type,  Map<String, dynamic> content,  int createdAt,  String? senderContactId,  String? parentId,  EventStatus status,  int? serverTs,  String? localId,  int? editedAt,  bool redacted,  int? redactedAt,  String? redactedBy,  int retryCount,  String? errorMessage,  String? forwardedFromRoom,  String? forwardedFromEvent,  int forwardCount,  bool forwardRestricted,  int? expiresAt,  bool starred,  int? starredAt)?  $default,) {final _that = this;
switch (_that) {
case _RoomEvent() when $default != null:
return $default(_that.id,_that.roomId,_that.senderId,_that.type,_that.content,_that.createdAt,_that.senderContactId,_that.parentId,_that.status,_that.serverTs,_that.localId,_that.editedAt,_that.redacted,_that.redactedAt,_that.redactedBy,_that.retryCount,_that.errorMessage,_that.forwardedFromRoom,_that.forwardedFromEvent,_that.forwardCount,_that.forwardRestricted,_that.expiresAt,_that.starred,_that.starredAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RoomEvent extends RoomEvent {
  const _RoomEvent({required this.id, required this.roomId, required this.senderId, required this.type, required final  Map<String, dynamic> content, required this.createdAt, this.senderContactId, this.parentId, this.status = EventStatus.pending, this.serverTs, this.localId, this.editedAt, this.redacted = false, this.redactedAt, this.redactedBy, this.retryCount = 0, this.errorMessage, this.forwardedFromRoom, this.forwardedFromEvent, this.forwardCount = 0, this.forwardRestricted = false, this.expiresAt, this.starred = false, this.starredAt}): _content = content,super._();
  factory _RoomEvent.fromJson(Map<String, dynamic> json) => _$RoomEventFromJson(json);

@override final  String id;
@override final  String roomId;
@override final  String senderId;
@override final  RoomEventType type;
 final  Map<String, dynamic> _content;
@override Map<String, dynamic> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

@override final  int createdAt;
@override final  String? senderContactId;
@override final  String? parentId;
@override@JsonKey() final  EventStatus status;
@override final  int? serverTs;
@override final  String? localId;
@override final  int? editedAt;
@override@JsonKey() final  bool redacted;
@override final  int? redactedAt;
@override final  String? redactedBy;
@override@JsonKey() final  int retryCount;
@override final  String? errorMessage;
@override final  String? forwardedFromRoom;
@override final  String? forwardedFromEvent;
@override@JsonKey() final  int forwardCount;
@override@JsonKey() final  bool forwardRestricted;
@override final  int? expiresAt;
@override@JsonKey() final  bool starred;
@override final  int? starredAt;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomEventCopyWith<_RoomEvent> get copyWith => __$RoomEventCopyWithImpl<_RoomEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoomEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.senderContactId, senderContactId) || other.senderContactId == senderContactId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.status, status) || other.status == status)&&(identical(other.serverTs, serverTs) || other.serverTs == serverTs)&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt)&&(identical(other.redacted, redacted) || other.redacted == redacted)&&(identical(other.redactedAt, redactedAt) || other.redactedAt == redactedAt)&&(identical(other.redactedBy, redactedBy) || other.redactedBy == redactedBy)&&(identical(other.retryCount, retryCount) || other.retryCount == retryCount)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.forwardedFromRoom, forwardedFromRoom) || other.forwardedFromRoom == forwardedFromRoom)&&(identical(other.forwardedFromEvent, forwardedFromEvent) || other.forwardedFromEvent == forwardedFromEvent)&&(identical(other.forwardCount, forwardCount) || other.forwardCount == forwardCount)&&(identical(other.forwardRestricted, forwardRestricted) || other.forwardRestricted == forwardRestricted)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.starred, starred) || other.starred == starred)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,roomId,senderId,type,const DeepCollectionEquality().hash(_content),createdAt,senderContactId,parentId,status,serverTs,localId,editedAt,redacted,redactedAt,redactedBy,retryCount,errorMessage,forwardedFromRoom,forwardedFromEvent,forwardCount,forwardRestricted,expiresAt,starred,starredAt]);

@override
String toString() {
  return 'RoomEvent(id: $id, roomId: $roomId, senderId: $senderId, type: $type, content: $content, createdAt: $createdAt, senderContactId: $senderContactId, parentId: $parentId, status: $status, serverTs: $serverTs, localId: $localId, editedAt: $editedAt, redacted: $redacted, redactedAt: $redactedAt, redactedBy: $redactedBy, retryCount: $retryCount, errorMessage: $errorMessage, forwardedFromRoom: $forwardedFromRoom, forwardedFromEvent: $forwardedFromEvent, forwardCount: $forwardCount, forwardRestricted: $forwardRestricted, expiresAt: $expiresAt, starred: $starred, starredAt: $starredAt)';
}


}

/// @nodoc
abstract mixin class _$RoomEventCopyWith<$Res> implements $RoomEventCopyWith<$Res> {
  factory _$RoomEventCopyWith(_RoomEvent value, $Res Function(_RoomEvent) _then) = __$RoomEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomId, String senderId, RoomEventType type, Map<String, dynamic> content, int createdAt, String? senderContactId, String? parentId, EventStatus status, int? serverTs, String? localId, int? editedAt, bool redacted, int? redactedAt, String? redactedBy, int retryCount, String? errorMessage, String? forwardedFromRoom, String? forwardedFromEvent, int forwardCount, bool forwardRestricted, int? expiresAt, bool starred, int? starredAt
});




}
/// @nodoc
class __$RoomEventCopyWithImpl<$Res>
    implements _$RoomEventCopyWith<$Res> {
  __$RoomEventCopyWithImpl(this._self, this._then);

  final _RoomEvent _self;
  final $Res Function(_RoomEvent) _then;

/// Create a copy of RoomEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? senderId = null,Object? type = null,Object? content = null,Object? createdAt = null,Object? senderContactId = freezed,Object? parentId = freezed,Object? status = null,Object? serverTs = freezed,Object? localId = freezed,Object? editedAt = freezed,Object? redacted = null,Object? redactedAt = freezed,Object? redactedBy = freezed,Object? retryCount = null,Object? errorMessage = freezed,Object? forwardedFromRoom = freezed,Object? forwardedFromEvent = freezed,Object? forwardCount = null,Object? forwardRestricted = null,Object? expiresAt = freezed,Object? starred = null,Object? starredAt = freezed,}) {
  return _then(_RoomEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as RoomEventType,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,senderContactId: freezed == senderContactId ? _self.senderContactId : senderContactId // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EventStatus,serverTs: freezed == serverTs ? _self.serverTs : serverTs // ignore: cast_nullable_to_non_nullable
as int?,localId: freezed == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String?,editedAt: freezed == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as int?,redacted: null == redacted ? _self.redacted : redacted // ignore: cast_nullable_to_non_nullable
as bool,redactedAt: freezed == redactedAt ? _self.redactedAt : redactedAt // ignore: cast_nullable_to_non_nullable
as int?,redactedBy: freezed == redactedBy ? _self.redactedBy : redactedBy // ignore: cast_nullable_to_non_nullable
as String?,retryCount: null == retryCount ? _self.retryCount : retryCount // ignore: cast_nullable_to_non_nullable
as int,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,forwardedFromRoom: freezed == forwardedFromRoom ? _self.forwardedFromRoom : forwardedFromRoom // ignore: cast_nullable_to_non_nullable
as String?,forwardedFromEvent: freezed == forwardedFromEvent ? _self.forwardedFromEvent : forwardedFromEvent // ignore: cast_nullable_to_non_nullable
as String?,forwardCount: null == forwardCount ? _self.forwardCount : forwardCount // ignore: cast_nullable_to_non_nullable
as int,forwardRestricted: null == forwardRestricted ? _self.forwardRestricted : forwardRestricted // ignore: cast_nullable_to_non_nullable
as bool,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,starred: null == starred ? _self.starred : starred // ignore: cast_nullable_to_non_nullable
as bool,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
