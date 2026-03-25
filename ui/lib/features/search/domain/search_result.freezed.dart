// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MessageSearchResult {

 String get messageId; String get roomId; String get roomName; String get text; String get senderId; DateTime get timestamp;/// The query that matched this result (for highlighting)
 String get query;
/// Create a copy of MessageSearchResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessageSearchResultCopyWith<MessageSearchResult> get copyWith => _$MessageSearchResultCopyWithImpl<MessageSearchResult>(this as MessageSearchResult, _$identity);

  /// Serializes this MessageSearchResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessageSearchResult&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.text, text) || other.text == text)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.query, query) || other.query == query));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,roomId,roomName,text,senderId,timestamp,query);

@override
String toString() {
  return 'MessageSearchResult(messageId: $messageId, roomId: $roomId, roomName: $roomName, text: $text, senderId: $senderId, timestamp: $timestamp, query: $query)';
}


}

/// @nodoc
abstract mixin class $MessageSearchResultCopyWith<$Res>  {
  factory $MessageSearchResultCopyWith(MessageSearchResult value, $Res Function(MessageSearchResult) _then) = _$MessageSearchResultCopyWithImpl;
@useResult
$Res call({
 String messageId, String roomId, String roomName, String text, String senderId, DateTime timestamp, String query
});




}
/// @nodoc
class _$MessageSearchResultCopyWithImpl<$Res>
    implements $MessageSearchResultCopyWith<$Res> {
  _$MessageSearchResultCopyWithImpl(this._self, this._then);

  final MessageSearchResult _self;
  final $Res Function(MessageSearchResult) _then;

/// Create a copy of MessageSearchResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? roomId = null,Object? roomName = null,Object? text = null,Object? senderId = null,Object? timestamp = null,Object? query = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessageSearchResult].
extension MessageSearchResultPatterns on MessageSearchResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessageSearchResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessageSearchResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessageSearchResult value)  $default,){
final _that = this;
switch (_that) {
case _MessageSearchResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessageSearchResult value)?  $default,){
final _that = this;
switch (_that) {
case _MessageSearchResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String roomId,  String roomName,  String text,  String senderId,  DateTime timestamp,  String query)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessageSearchResult() when $default != null:
return $default(_that.messageId,_that.roomId,_that.roomName,_that.text,_that.senderId,_that.timestamp,_that.query);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String roomId,  String roomName,  String text,  String senderId,  DateTime timestamp,  String query)  $default,) {final _that = this;
switch (_that) {
case _MessageSearchResult():
return $default(_that.messageId,_that.roomId,_that.roomName,_that.text,_that.senderId,_that.timestamp,_that.query);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String roomId,  String roomName,  String text,  String senderId,  DateTime timestamp,  String query)?  $default,) {final _that = this;
switch (_that) {
case _MessageSearchResult() when $default != null:
return $default(_that.messageId,_that.roomId,_that.roomName,_that.text,_that.senderId,_that.timestamp,_that.query);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MessageSearchResult implements MessageSearchResult {
  const _MessageSearchResult({required this.messageId, required this.roomId, required this.roomName, required this.text, required this.senderId, required this.timestamp, required this.query});
  factory _MessageSearchResult.fromJson(Map<String, dynamic> json) => _$MessageSearchResultFromJson(json);

@override final  String messageId;
@override final  String roomId;
@override final  String roomName;
@override final  String text;
@override final  String senderId;
@override final  DateTime timestamp;
/// The query that matched this result (for highlighting)
@override final  String query;

/// Create a copy of MessageSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessageSearchResultCopyWith<_MessageSearchResult> get copyWith => __$MessageSearchResultCopyWithImpl<_MessageSearchResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MessageSearchResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessageSearchResult&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.roomName, roomName) || other.roomName == roomName)&&(identical(other.text, text) || other.text == text)&&(identical(other.senderId, senderId) || other.senderId == senderId)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.query, query) || other.query == query));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,roomId,roomName,text,senderId,timestamp,query);

@override
String toString() {
  return 'MessageSearchResult(messageId: $messageId, roomId: $roomId, roomName: $roomName, text: $text, senderId: $senderId, timestamp: $timestamp, query: $query)';
}


}

/// @nodoc
abstract mixin class _$MessageSearchResultCopyWith<$Res> implements $MessageSearchResultCopyWith<$Res> {
  factory _$MessageSearchResultCopyWith(_MessageSearchResult value, $Res Function(_MessageSearchResult) _then) = __$MessageSearchResultCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String roomId, String roomName, String text, String senderId, DateTime timestamp, String query
});




}
/// @nodoc
class __$MessageSearchResultCopyWithImpl<$Res>
    implements _$MessageSearchResultCopyWith<$Res> {
  __$MessageSearchResultCopyWithImpl(this._self, this._then);

  final _MessageSearchResult _self;
  final $Res Function(_MessageSearchResult) _then;

/// Create a copy of MessageSearchResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? roomId = null,Object? roomName = null,Object? text = null,Object? senderId = null,Object? timestamp = null,Object? query = null,}) {
  return _then(_MessageSearchResult(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,roomName: null == roomName ? _self.roomName : roomName // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,senderId: null == senderId ? _self.senderId : senderId // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
