// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_with_last_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoomWithLastMessage {

 String get id; String get name; String get type; int get unreadCount; String? get lastMessageText; int? get lastMessageTimestamp; String? get lastMessageSenderId; String? get lastMessageSenderName; bool? get isTyping;/// Draft message text if the user has an unsent message
 String? get draftText;/// Mute notifications until this timestamp (milliseconds since epoch)
/// - null = not muted
/// - 0 = muted forever
/// - timestamp = muted until that time
 int? get mutedUntil;
/// Create a copy of RoomWithLastMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoomWithLastMessageCopyWith<RoomWithLastMessage> get copyWith => _$RoomWithLastMessageCopyWithImpl<RoomWithLastMessage>(this as RoomWithLastMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoomWithLastMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageTimestamp, lastMessageTimestamp) || other.lastMessageTimestamp == lastMessageTimestamp)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageSenderName, lastMessageSenderName) || other.lastMessageSenderName == lastMessageSenderName)&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping)&&(identical(other.draftText, draftText) || other.draftText == draftText)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,unreadCount,lastMessageText,lastMessageTimestamp,lastMessageSenderId,lastMessageSenderName,isTyping,draftText,mutedUntil);

@override
String toString() {
  return 'RoomWithLastMessage(id: $id, name: $name, type: $type, unreadCount: $unreadCount, lastMessageText: $lastMessageText, lastMessageTimestamp: $lastMessageTimestamp, lastMessageSenderId: $lastMessageSenderId, lastMessageSenderName: $lastMessageSenderName, isTyping: $isTyping, draftText: $draftText, mutedUntil: $mutedUntil)';
}


}

/// @nodoc
abstract mixin class $RoomWithLastMessageCopyWith<$Res>  {
  factory $RoomWithLastMessageCopyWith(RoomWithLastMessage value, $Res Function(RoomWithLastMessage) _then) = _$RoomWithLastMessageCopyWithImpl;
@useResult
$Res call({
 String id, String name, String type, int unreadCount, String? lastMessageText, int? lastMessageTimestamp, String? lastMessageSenderId, String? lastMessageSenderName, bool? isTyping, String? draftText, int? mutedUntil
});




}
/// @nodoc
class _$RoomWithLastMessageCopyWithImpl<$Res>
    implements $RoomWithLastMessageCopyWith<$Res> {
  _$RoomWithLastMessageCopyWithImpl(this._self, this._then);

  final RoomWithLastMessage _self;
  final $Res Function(RoomWithLastMessage) _then;

/// Create a copy of RoomWithLastMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? type = null,Object? unreadCount = null,Object? lastMessageText = freezed,Object? lastMessageTimestamp = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageSenderName = freezed,Object? isTyping = freezed,Object? draftText = freezed,Object? mutedUntil = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTimestamp: freezed == lastMessageTimestamp ? _self.lastMessageTimestamp : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
as int?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderName: freezed == lastMessageSenderName ? _self.lastMessageSenderName : lastMessageSenderName // ignore: cast_nullable_to_non_nullable
as String?,isTyping: freezed == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool?,draftText: freezed == draftText ? _self.draftText : draftText // ignore: cast_nullable_to_non_nullable
as String?,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RoomWithLastMessage].
extension RoomWithLastMessagePatterns on RoomWithLastMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoomWithLastMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoomWithLastMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoomWithLastMessage value)  $default,){
final _that = this;
switch (_that) {
case _RoomWithLastMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoomWithLastMessage value)?  $default,){
final _that = this;
switch (_that) {
case _RoomWithLastMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String type,  int unreadCount,  String? lastMessageText,  int? lastMessageTimestamp,  String? lastMessageSenderId,  String? lastMessageSenderName,  bool? isTyping,  String? draftText,  int? mutedUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoomWithLastMessage() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.unreadCount,_that.lastMessageText,_that.lastMessageTimestamp,_that.lastMessageSenderId,_that.lastMessageSenderName,_that.isTyping,_that.draftText,_that.mutedUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String type,  int unreadCount,  String? lastMessageText,  int? lastMessageTimestamp,  String? lastMessageSenderId,  String? lastMessageSenderName,  bool? isTyping,  String? draftText,  int? mutedUntil)  $default,) {final _that = this;
switch (_that) {
case _RoomWithLastMessage():
return $default(_that.id,_that.name,_that.type,_that.unreadCount,_that.lastMessageText,_that.lastMessageTimestamp,_that.lastMessageSenderId,_that.lastMessageSenderName,_that.isTyping,_that.draftText,_that.mutedUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String type,  int unreadCount,  String? lastMessageText,  int? lastMessageTimestamp,  String? lastMessageSenderId,  String? lastMessageSenderName,  bool? isTyping,  String? draftText,  int? mutedUntil)?  $default,) {final _that = this;
switch (_that) {
case _RoomWithLastMessage() when $default != null:
return $default(_that.id,_that.name,_that.type,_that.unreadCount,_that.lastMessageText,_that.lastMessageTimestamp,_that.lastMessageSenderId,_that.lastMessageSenderName,_that.isTyping,_that.draftText,_that.mutedUntil);case _:
  return null;

}
}

}

/// @nodoc


class _RoomWithLastMessage extends RoomWithLastMessage {
  const _RoomWithLastMessage({required this.id, required this.name, required this.type, required this.unreadCount, this.lastMessageText, this.lastMessageTimestamp, this.lastMessageSenderId, this.lastMessageSenderName, this.isTyping, this.draftText, this.mutedUntil}): super._();
  

@override final  String id;
@override final  String name;
@override final  String type;
@override final  int unreadCount;
@override final  String? lastMessageText;
@override final  int? lastMessageTimestamp;
@override final  String? lastMessageSenderId;
@override final  String? lastMessageSenderName;
@override final  bool? isTyping;
/// Draft message text if the user has an unsent message
@override final  String? draftText;
/// Mute notifications until this timestamp (milliseconds since epoch)
/// - null = not muted
/// - 0 = muted forever
/// - timestamp = muted until that time
@override final  int? mutedUntil;

/// Create a copy of RoomWithLastMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoomWithLastMessageCopyWith<_RoomWithLastMessage> get copyWith => __$RoomWithLastMessageCopyWithImpl<_RoomWithLastMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoomWithLastMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.lastMessageText, lastMessageText) || other.lastMessageText == lastMessageText)&&(identical(other.lastMessageTimestamp, lastMessageTimestamp) || other.lastMessageTimestamp == lastMessageTimestamp)&&(identical(other.lastMessageSenderId, lastMessageSenderId) || other.lastMessageSenderId == lastMessageSenderId)&&(identical(other.lastMessageSenderName, lastMessageSenderName) || other.lastMessageSenderName == lastMessageSenderName)&&(identical(other.isTyping, isTyping) || other.isTyping == isTyping)&&(identical(other.draftText, draftText) || other.draftText == draftText)&&(identical(other.mutedUntil, mutedUntil) || other.mutedUntil == mutedUntil));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,type,unreadCount,lastMessageText,lastMessageTimestamp,lastMessageSenderId,lastMessageSenderName,isTyping,draftText,mutedUntil);

@override
String toString() {
  return 'RoomWithLastMessage(id: $id, name: $name, type: $type, unreadCount: $unreadCount, lastMessageText: $lastMessageText, lastMessageTimestamp: $lastMessageTimestamp, lastMessageSenderId: $lastMessageSenderId, lastMessageSenderName: $lastMessageSenderName, isTyping: $isTyping, draftText: $draftText, mutedUntil: $mutedUntil)';
}


}

/// @nodoc
abstract mixin class _$RoomWithLastMessageCopyWith<$Res> implements $RoomWithLastMessageCopyWith<$Res> {
  factory _$RoomWithLastMessageCopyWith(_RoomWithLastMessage value, $Res Function(_RoomWithLastMessage) _then) = __$RoomWithLastMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String type, int unreadCount, String? lastMessageText, int? lastMessageTimestamp, String? lastMessageSenderId, String? lastMessageSenderName, bool? isTyping, String? draftText, int? mutedUntil
});




}
/// @nodoc
class __$RoomWithLastMessageCopyWithImpl<$Res>
    implements _$RoomWithLastMessageCopyWith<$Res> {
  __$RoomWithLastMessageCopyWithImpl(this._self, this._then);

  final _RoomWithLastMessage _self;
  final $Res Function(_RoomWithLastMessage) _then;

/// Create a copy of RoomWithLastMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? type = null,Object? unreadCount = null,Object? lastMessageText = freezed,Object? lastMessageTimestamp = freezed,Object? lastMessageSenderId = freezed,Object? lastMessageSenderName = freezed,Object? isTyping = freezed,Object? draftText = freezed,Object? mutedUntil = freezed,}) {
  return _then(_RoomWithLastMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,lastMessageText: freezed == lastMessageText ? _self.lastMessageText : lastMessageText // ignore: cast_nullable_to_non_nullable
as String?,lastMessageTimestamp: freezed == lastMessageTimestamp ? _self.lastMessageTimestamp : lastMessageTimestamp // ignore: cast_nullable_to_non_nullable
as int?,lastMessageSenderId: freezed == lastMessageSenderId ? _self.lastMessageSenderId : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageSenderName: freezed == lastMessageSenderName ? _self.lastMessageSenderName : lastMessageSenderName // ignore: cast_nullable_to_non_nullable
as String?,isTyping: freezed == isTyping ? _self.isTyping : isTyping // ignore: cast_nullable_to_non_nullable
as bool?,draftText: freezed == draftText ? _self.draftText : draftText // ignore: cast_nullable_to_non_nullable
as String?,mutedUntil: freezed == mutedUntil ? _self.mutedUntil : mutedUntil // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
