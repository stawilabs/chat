// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_call_participant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupCallParticipant {

/// Unique profile ID of the participant
 String get profileId;/// Display name shown in the call UI
 String get displayName;/// Timestamp when the participant joined the call
 DateTime get joinedAt;/// URL to the participant's avatar image
 String? get avatarUrl;/// Whether the participant's microphone is muted
 bool get isAudioMuted;/// Whether the participant's camera is turned off
 bool get isVideoOff;/// Whether the participant is currently speaking
 bool get isSpeaking;/// Whether this participant is the host of the call
 bool get isHost;/// Current connection state of the participant
 ParticipantState get state;
/// Create a copy of GroupCallParticipant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCallParticipantCopyWith<GroupCallParticipant> get copyWith => _$GroupCallParticipantCopyWithImpl<GroupCallParticipant>(this as GroupCallParticipant, _$identity);

  /// Serializes this GroupCallParticipant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCallParticipant&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isAudioMuted, isAudioMuted) || other.isAudioMuted == isAudioMuted)&&(identical(other.isVideoOff, isVideoOff) || other.isVideoOff == isVideoOff)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileId,displayName,joinedAt,avatarUrl,isAudioMuted,isVideoOff,isSpeaking,isHost,state);

@override
String toString() {
  return 'GroupCallParticipant(profileId: $profileId, displayName: $displayName, joinedAt: $joinedAt, avatarUrl: $avatarUrl, isAudioMuted: $isAudioMuted, isVideoOff: $isVideoOff, isSpeaking: $isSpeaking, isHost: $isHost, state: $state)';
}


}

/// @nodoc
abstract mixin class $GroupCallParticipantCopyWith<$Res>  {
  factory $GroupCallParticipantCopyWith(GroupCallParticipant value, $Res Function(GroupCallParticipant) _then) = _$GroupCallParticipantCopyWithImpl;
@useResult
$Res call({
 String profileId, String displayName, DateTime joinedAt, String? avatarUrl, bool isAudioMuted, bool isVideoOff, bool isSpeaking, bool isHost, ParticipantState state
});




}
/// @nodoc
class _$GroupCallParticipantCopyWithImpl<$Res>
    implements $GroupCallParticipantCopyWith<$Res> {
  _$GroupCallParticipantCopyWithImpl(this._self, this._then);

  final GroupCallParticipant _self;
  final $Res Function(GroupCallParticipant) _then;

/// Create a copy of GroupCallParticipant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profileId = null,Object? displayName = null,Object? joinedAt = null,Object? avatarUrl = freezed,Object? isAudioMuted = null,Object? isVideoOff = null,Object? isSpeaking = null,Object? isHost = null,Object? state = null,}) {
  return _then(_self.copyWith(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isAudioMuted: null == isAudioMuted ? _self.isAudioMuted : isAudioMuted // ignore: cast_nullable_to_non_nullable
as bool,isVideoOff: null == isVideoOff ? _self.isVideoOff : isVideoOff // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ParticipantState,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCallParticipant].
extension GroupCallParticipantPatterns on GroupCallParticipant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCallParticipant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCallParticipant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCallParticipant value)  $default,){
final _that = this;
switch (_that) {
case _GroupCallParticipant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCallParticipant value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCallParticipant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String profileId,  String displayName,  DateTime joinedAt,  String? avatarUrl,  bool isAudioMuted,  bool isVideoOff,  bool isSpeaking,  bool isHost,  ParticipantState state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCallParticipant() when $default != null:
return $default(_that.profileId,_that.displayName,_that.joinedAt,_that.avatarUrl,_that.isAudioMuted,_that.isVideoOff,_that.isSpeaking,_that.isHost,_that.state);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String profileId,  String displayName,  DateTime joinedAt,  String? avatarUrl,  bool isAudioMuted,  bool isVideoOff,  bool isSpeaking,  bool isHost,  ParticipantState state)  $default,) {final _that = this;
switch (_that) {
case _GroupCallParticipant():
return $default(_that.profileId,_that.displayName,_that.joinedAt,_that.avatarUrl,_that.isAudioMuted,_that.isVideoOff,_that.isSpeaking,_that.isHost,_that.state);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String profileId,  String displayName,  DateTime joinedAt,  String? avatarUrl,  bool isAudioMuted,  bool isVideoOff,  bool isSpeaking,  bool isHost,  ParticipantState state)?  $default,) {final _that = this;
switch (_that) {
case _GroupCallParticipant() when $default != null:
return $default(_that.profileId,_that.displayName,_that.joinedAt,_that.avatarUrl,_that.isAudioMuted,_that.isVideoOff,_that.isSpeaking,_that.isHost,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupCallParticipant extends GroupCallParticipant {
  const _GroupCallParticipant({required this.profileId, required this.displayName, required this.joinedAt, this.avatarUrl, this.isAudioMuted = false, this.isVideoOff = false, this.isSpeaking = false, this.isHost = false, this.state = ParticipantState.joining}): super._();
  factory _GroupCallParticipant.fromJson(Map<String, dynamic> json) => _$GroupCallParticipantFromJson(json);

/// Unique profile ID of the participant
@override final  String profileId;
/// Display name shown in the call UI
@override final  String displayName;
/// Timestamp when the participant joined the call
@override final  DateTime joinedAt;
/// URL to the participant's avatar image
@override final  String? avatarUrl;
/// Whether the participant's microphone is muted
@override@JsonKey() final  bool isAudioMuted;
/// Whether the participant's camera is turned off
@override@JsonKey() final  bool isVideoOff;
/// Whether the participant is currently speaking
@override@JsonKey() final  bool isSpeaking;
/// Whether this participant is the host of the call
@override@JsonKey() final  bool isHost;
/// Current connection state of the participant
@override@JsonKey() final  ParticipantState state;

/// Create a copy of GroupCallParticipant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCallParticipantCopyWith<_GroupCallParticipant> get copyWith => __$GroupCallParticipantCopyWithImpl<_GroupCallParticipant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupCallParticipantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCallParticipant&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.isAudioMuted, isAudioMuted) || other.isAudioMuted == isAudioMuted)&&(identical(other.isVideoOff, isVideoOff) || other.isVideoOff == isVideoOff)&&(identical(other.isSpeaking, isSpeaking) || other.isSpeaking == isSpeaking)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileId,displayName,joinedAt,avatarUrl,isAudioMuted,isVideoOff,isSpeaking,isHost,state);

@override
String toString() {
  return 'GroupCallParticipant(profileId: $profileId, displayName: $displayName, joinedAt: $joinedAt, avatarUrl: $avatarUrl, isAudioMuted: $isAudioMuted, isVideoOff: $isVideoOff, isSpeaking: $isSpeaking, isHost: $isHost, state: $state)';
}


}

/// @nodoc
abstract mixin class _$GroupCallParticipantCopyWith<$Res> implements $GroupCallParticipantCopyWith<$Res> {
  factory _$GroupCallParticipantCopyWith(_GroupCallParticipant value, $Res Function(_GroupCallParticipant) _then) = __$GroupCallParticipantCopyWithImpl;
@override @useResult
$Res call({
 String profileId, String displayName, DateTime joinedAt, String? avatarUrl, bool isAudioMuted, bool isVideoOff, bool isSpeaking, bool isHost, ParticipantState state
});




}
/// @nodoc
class __$GroupCallParticipantCopyWithImpl<$Res>
    implements _$GroupCallParticipantCopyWith<$Res> {
  __$GroupCallParticipantCopyWithImpl(this._self, this._then);

  final _GroupCallParticipant _self;
  final $Res Function(_GroupCallParticipant) _then;

/// Create a copy of GroupCallParticipant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profileId = null,Object? displayName = null,Object? joinedAt = null,Object? avatarUrl = freezed,Object? isAudioMuted = null,Object? isVideoOff = null,Object? isSpeaking = null,Object? isHost = null,Object? state = null,}) {
  return _then(_GroupCallParticipant(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,isAudioMuted: null == isAudioMuted ? _self.isAudioMuted : isAudioMuted // ignore: cast_nullable_to_non_nullable
as bool,isVideoOff: null == isVideoOff ? _self.isVideoOff : isVideoOff // ignore: cast_nullable_to_non_nullable
as bool,isSpeaking: null == isSpeaking ? _self.isSpeaking : isSpeaking // ignore: cast_nullable_to_non_nullable
as bool,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as ParticipantState,
  ));
}


}

// dart format on
