// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupCall {

/// Unique identifier for this call
 String get callId;/// Room ID where this call is taking place
 String get roomId;/// Profile ID of the user who started the call
 String get hostProfileId;/// Timestamp when the call was started
 DateTime get startedAt;/// List of participants in the call
 List<GroupCallParticipant> get participants;/// Current state of the call
 GroupCallState get state;/// Timestamp when the call ended (null if still active)
 DateTime? get endedAt;
/// Create a copy of GroupCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCallCopyWith<GroupCall> get copyWith => _$GroupCallCopyWithImpl<GroupCall>(this as GroupCall, _$identity);

  /// Serializes this GroupCall to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCall&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hostProfileId, hostProfileId) || other.hostProfileId == hostProfileId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&const DeepCollectionEquality().equals(other.participants, participants)&&(identical(other.state, state) || other.state == state)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callId,roomId,hostProfileId,startedAt,const DeepCollectionEquality().hash(participants),state,endedAt);

@override
String toString() {
  return 'GroupCall(callId: $callId, roomId: $roomId, hostProfileId: $hostProfileId, startedAt: $startedAt, participants: $participants, state: $state, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class $GroupCallCopyWith<$Res>  {
  factory $GroupCallCopyWith(GroupCall value, $Res Function(GroupCall) _then) = _$GroupCallCopyWithImpl;
@useResult
$Res call({
 String callId, String roomId, String hostProfileId, DateTime startedAt, List<GroupCallParticipant> participants, GroupCallState state, DateTime? endedAt
});




}
/// @nodoc
class _$GroupCallCopyWithImpl<$Res>
    implements $GroupCallCopyWith<$Res> {
  _$GroupCallCopyWithImpl(this._self, this._then);

  final GroupCall _self;
  final $Res Function(GroupCall) _then;

/// Create a copy of GroupCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? roomId = null,Object? hostProfileId = null,Object? startedAt = null,Object? participants = null,Object? state = null,Object? endedAt = freezed,}) {
  return _then(_self.copyWith(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hostProfileId: null == hostProfileId ? _self.hostProfileId : hostProfileId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,participants: null == participants ? _self.participants : participants // ignore: cast_nullable_to_non_nullable
as List<GroupCallParticipant>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GroupCallState,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCall].
extension GroupCallPatterns on GroupCall {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCall value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCall() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCall value)  $default,){
final _that = this;
switch (_that) {
case _GroupCall():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCall value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCall() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String callId,  String roomId,  String hostProfileId,  DateTime startedAt,  List<GroupCallParticipant> participants,  GroupCallState state,  DateTime? endedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCall() when $default != null:
return $default(_that.callId,_that.roomId,_that.hostProfileId,_that.startedAt,_that.participants,_that.state,_that.endedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String callId,  String roomId,  String hostProfileId,  DateTime startedAt,  List<GroupCallParticipant> participants,  GroupCallState state,  DateTime? endedAt)  $default,) {final _that = this;
switch (_that) {
case _GroupCall():
return $default(_that.callId,_that.roomId,_that.hostProfileId,_that.startedAt,_that.participants,_that.state,_that.endedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String callId,  String roomId,  String hostProfileId,  DateTime startedAt,  List<GroupCallParticipant> participants,  GroupCallState state,  DateTime? endedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupCall() when $default != null:
return $default(_that.callId,_that.roomId,_that.hostProfileId,_that.startedAt,_that.participants,_that.state,_that.endedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupCall extends GroupCall {
  const _GroupCall({required this.callId, required this.roomId, required this.hostProfileId, required this.startedAt, final  List<GroupCallParticipant> participants = const [], this.state = GroupCallState.initiating, this.endedAt}): _participants = participants,super._();
  factory _GroupCall.fromJson(Map<String, dynamic> json) => _$GroupCallFromJson(json);

/// Unique identifier for this call
@override final  String callId;
/// Room ID where this call is taking place
@override final  String roomId;
/// Profile ID of the user who started the call
@override final  String hostProfileId;
/// Timestamp when the call was started
@override final  DateTime startedAt;
/// List of participants in the call
 final  List<GroupCallParticipant> _participants;
/// List of participants in the call
@override@JsonKey() List<GroupCallParticipant> get participants {
  if (_participants is EqualUnmodifiableListView) return _participants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_participants);
}

/// Current state of the call
@override@JsonKey() final  GroupCallState state;
/// Timestamp when the call ended (null if still active)
@override final  DateTime? endedAt;

/// Create a copy of GroupCall
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCallCopyWith<_GroupCall> get copyWith => __$GroupCallCopyWithImpl<_GroupCall>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupCallToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCall&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.hostProfileId, hostProfileId) || other.hostProfileId == hostProfileId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&const DeepCollectionEquality().equals(other._participants, _participants)&&(identical(other.state, state) || other.state == state)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,callId,roomId,hostProfileId,startedAt,const DeepCollectionEquality().hash(_participants),state,endedAt);

@override
String toString() {
  return 'GroupCall(callId: $callId, roomId: $roomId, hostProfileId: $hostProfileId, startedAt: $startedAt, participants: $participants, state: $state, endedAt: $endedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupCallCopyWith<$Res> implements $GroupCallCopyWith<$Res> {
  factory _$GroupCallCopyWith(_GroupCall value, $Res Function(_GroupCall) _then) = __$GroupCallCopyWithImpl;
@override @useResult
$Res call({
 String callId, String roomId, String hostProfileId, DateTime startedAt, List<GroupCallParticipant> participants, GroupCallState state, DateTime? endedAt
});




}
/// @nodoc
class __$GroupCallCopyWithImpl<$Res>
    implements _$GroupCallCopyWith<$Res> {
  __$GroupCallCopyWithImpl(this._self, this._then);

  final _GroupCall _self;
  final $Res Function(_GroupCall) _then;

/// Create a copy of GroupCall
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? callId = null,Object? roomId = null,Object? hostProfileId = null,Object? startedAt = null,Object? participants = null,Object? state = null,Object? endedAt = freezed,}) {
  return _then(_GroupCall(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,hostProfileId: null == hostProfileId ? _self.hostProfileId : hostProfileId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,participants: null == participants ? _self._participants : participants // ignore: cast_nullable_to_non_nullable
as List<GroupCallParticipant>,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as GroupCallState,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
