// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invite_link.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InviteLink {

 String get id; String get roomId; String get code; String get createdBy; int get createdAt; int? get expiresAt; int? get maxUses; int get useCount; bool get revoked; bool get requiresApproval; String? get name;
/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteLinkCopyWith<InviteLink> get copyWith => _$InviteLinkCopyWithImpl<InviteLink>(this as InviteLink, _$identity);

  /// Serializes this InviteLink to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteLink&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.revoked, revoked) || other.revoked == revoked)&&(identical(other.requiresApproval, requiresApproval) || other.requiresApproval == requiresApproval)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,code,createdBy,createdAt,expiresAt,maxUses,useCount,revoked,requiresApproval,name);

@override
String toString() {
  return 'InviteLink(id: $id, roomId: $roomId, code: $code, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, maxUses: $maxUses, useCount: $useCount, revoked: $revoked, requiresApproval: $requiresApproval, name: $name)';
}


}

/// @nodoc
abstract mixin class $InviteLinkCopyWith<$Res>  {
  factory $InviteLinkCopyWith(InviteLink value, $Res Function(InviteLink) _then) = _$InviteLinkCopyWithImpl;
@useResult
$Res call({
 String id, String roomId, String code, String createdBy, int createdAt, int? expiresAt, int? maxUses, int useCount, bool revoked, bool requiresApproval, String? name
});




}
/// @nodoc
class _$InviteLinkCopyWithImpl<$Res>
    implements $InviteLinkCopyWith<$Res> {
  _$InviteLinkCopyWithImpl(this._self, this._then);

  final InviteLink _self;
  final $Res Function(InviteLink) _then;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomId = null,Object? code = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = freezed,Object? maxUses = freezed,Object? useCount = null,Object? revoked = null,Object? requiresApproval = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,requiresApproval: null == requiresApproval ? _self.requiresApproval : requiresApproval // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteLink].
extension InviteLinkPatterns on InviteLink {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteLink value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteLink value)  $default,){
final _that = this;
switch (_that) {
case _InviteLink():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteLink value)?  $default,){
final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String roomId,  String code,  String createdBy,  int createdAt,  int? expiresAt,  int? maxUses,  int useCount,  bool revoked,  bool requiresApproval,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
return $default(_that.id,_that.roomId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.useCount,_that.revoked,_that.requiresApproval,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String roomId,  String code,  String createdBy,  int createdAt,  int? expiresAt,  int? maxUses,  int useCount,  bool revoked,  bool requiresApproval,  String? name)  $default,) {final _that = this;
switch (_that) {
case _InviteLink():
return $default(_that.id,_that.roomId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.useCount,_that.revoked,_that.requiresApproval,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String roomId,  String code,  String createdBy,  int createdAt,  int? expiresAt,  int? maxUses,  int useCount,  bool revoked,  bool requiresApproval,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _InviteLink() when $default != null:
return $default(_that.id,_that.roomId,_that.code,_that.createdBy,_that.createdAt,_that.expiresAt,_that.maxUses,_that.useCount,_that.revoked,_that.requiresApproval,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteLink extends InviteLink {
  const _InviteLink({required this.id, required this.roomId, required this.code, required this.createdBy, required this.createdAt, this.expiresAt, this.maxUses, this.useCount = 0, this.revoked = false, this.requiresApproval = false, this.name}): super._();
  factory _InviteLink.fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);

@override final  String id;
@override final  String roomId;
@override final  String code;
@override final  String createdBy;
@override final  int createdAt;
@override final  int? expiresAt;
@override final  int? maxUses;
@override@JsonKey() final  int useCount;
@override@JsonKey() final  bool revoked;
@override@JsonKey() final  bool requiresApproval;
@override final  String? name;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteLinkCopyWith<_InviteLink> get copyWith => __$InviteLinkCopyWithImpl<_InviteLink>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteLinkToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteLink&&(identical(other.id, id) || other.id == id)&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.code, code) || other.code == code)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.maxUses, maxUses) || other.maxUses == maxUses)&&(identical(other.useCount, useCount) || other.useCount == useCount)&&(identical(other.revoked, revoked) || other.revoked == revoked)&&(identical(other.requiresApproval, requiresApproval) || other.requiresApproval == requiresApproval)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,roomId,code,createdBy,createdAt,expiresAt,maxUses,useCount,revoked,requiresApproval,name);

@override
String toString() {
  return 'InviteLink(id: $id, roomId: $roomId, code: $code, createdBy: $createdBy, createdAt: $createdAt, expiresAt: $expiresAt, maxUses: $maxUses, useCount: $useCount, revoked: $revoked, requiresApproval: $requiresApproval, name: $name)';
}


}

/// @nodoc
abstract mixin class _$InviteLinkCopyWith<$Res> implements $InviteLinkCopyWith<$Res> {
  factory _$InviteLinkCopyWith(_InviteLink value, $Res Function(_InviteLink) _then) = __$InviteLinkCopyWithImpl;
@override @useResult
$Res call({
 String id, String roomId, String code, String createdBy, int createdAt, int? expiresAt, int? maxUses, int useCount, bool revoked, bool requiresApproval, String? name
});




}
/// @nodoc
class __$InviteLinkCopyWithImpl<$Res>
    implements _$InviteLinkCopyWith<$Res> {
  __$InviteLinkCopyWithImpl(this._self, this._then);

  final _InviteLink _self;
  final $Res Function(_InviteLink) _then;

/// Create a copy of InviteLink
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomId = null,Object? code = null,Object? createdBy = null,Object? createdAt = null,Object? expiresAt = freezed,Object? maxUses = freezed,Object? useCount = null,Object? revoked = null,Object? requiresApproval = null,Object? name = freezed,}) {
  return _then(_InviteLink(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as int?,maxUses: freezed == maxUses ? _self.maxUses : maxUses // ignore: cast_nullable_to_non_nullable
as int?,useCount: null == useCount ? _self.useCount : useCount // ignore: cast_nullable_to_non_nullable
as int,revoked: null == revoked ? _self.revoked : revoked // ignore: cast_nullable_to_non_nullable
as bool,requiresApproval: null == requiresApproval ? _self.requiresApproval : requiresApproval // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InviteLinkJoin {

 int get id; String get inviteLinkId; String get profileId; int get joinedAt; String get status;
/// Create a copy of InviteLinkJoin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InviteLinkJoinCopyWith<InviteLinkJoin> get copyWith => _$InviteLinkJoinCopyWithImpl<InviteLinkJoin>(this as InviteLinkJoin, _$identity);

  /// Serializes this InviteLinkJoin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InviteLinkJoin&&(identical(other.id, id) || other.id == id)&&(identical(other.inviteLinkId, inviteLinkId) || other.inviteLinkId == inviteLinkId)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inviteLinkId,profileId,joinedAt,status);

@override
String toString() {
  return 'InviteLinkJoin(id: $id, inviteLinkId: $inviteLinkId, profileId: $profileId, joinedAt: $joinedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $InviteLinkJoinCopyWith<$Res>  {
  factory $InviteLinkJoinCopyWith(InviteLinkJoin value, $Res Function(InviteLinkJoin) _then) = _$InviteLinkJoinCopyWithImpl;
@useResult
$Res call({
 int id, String inviteLinkId, String profileId, int joinedAt, String status
});




}
/// @nodoc
class _$InviteLinkJoinCopyWithImpl<$Res>
    implements $InviteLinkJoinCopyWith<$Res> {
  _$InviteLinkJoinCopyWithImpl(this._self, this._then);

  final InviteLinkJoin _self;
  final $Res Function(InviteLinkJoin) _then;

/// Create a copy of InviteLinkJoin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? inviteLinkId = null,Object? profileId = null,Object? joinedAt = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,inviteLinkId: null == inviteLinkId ? _self.inviteLinkId : inviteLinkId // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InviteLinkJoin].
extension InviteLinkJoinPatterns on InviteLinkJoin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InviteLinkJoin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InviteLinkJoin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InviteLinkJoin value)  $default,){
final _that = this;
switch (_that) {
case _InviteLinkJoin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InviteLinkJoin value)?  $default,){
final _that = this;
switch (_that) {
case _InviteLinkJoin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String inviteLinkId,  String profileId,  int joinedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InviteLinkJoin() when $default != null:
return $default(_that.id,_that.inviteLinkId,_that.profileId,_that.joinedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String inviteLinkId,  String profileId,  int joinedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _InviteLinkJoin():
return $default(_that.id,_that.inviteLinkId,_that.profileId,_that.joinedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String inviteLinkId,  String profileId,  int joinedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _InviteLinkJoin() when $default != null:
return $default(_that.id,_that.inviteLinkId,_that.profileId,_that.joinedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InviteLinkJoin implements InviteLinkJoin {
  const _InviteLinkJoin({required this.id, required this.inviteLinkId, required this.profileId, required this.joinedAt, this.status = 'approved'});
  factory _InviteLinkJoin.fromJson(Map<String, dynamic> json) => _$InviteLinkJoinFromJson(json);

@override final  int id;
@override final  String inviteLinkId;
@override final  String profileId;
@override final  int joinedAt;
@override@JsonKey() final  String status;

/// Create a copy of InviteLinkJoin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InviteLinkJoinCopyWith<_InviteLinkJoin> get copyWith => __$InviteLinkJoinCopyWithImpl<_InviteLinkJoin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InviteLinkJoinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InviteLinkJoin&&(identical(other.id, id) || other.id == id)&&(identical(other.inviteLinkId, inviteLinkId) || other.inviteLinkId == inviteLinkId)&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,inviteLinkId,profileId,joinedAt,status);

@override
String toString() {
  return 'InviteLinkJoin(id: $id, inviteLinkId: $inviteLinkId, profileId: $profileId, joinedAt: $joinedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$InviteLinkJoinCopyWith<$Res> implements $InviteLinkJoinCopyWith<$Res> {
  factory _$InviteLinkJoinCopyWith(_InviteLinkJoin value, $Res Function(_InviteLinkJoin) _then) = __$InviteLinkJoinCopyWithImpl;
@override @useResult
$Res call({
 int id, String inviteLinkId, String profileId, int joinedAt, String status
});




}
/// @nodoc
class __$InviteLinkJoinCopyWithImpl<$Res>
    implements _$InviteLinkJoinCopyWith<$Res> {
  __$InviteLinkJoinCopyWithImpl(this._self, this._then);

  final _InviteLinkJoin _self;
  final $Res Function(_InviteLinkJoin) _then;

/// Create a copy of InviteLinkJoin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? inviteLinkId = null,Object? profileId = null,Object? joinedAt = null,Object? status = null,}) {
  return _then(_InviteLinkJoin(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,inviteLinkId: null == inviteLinkId ? _self.inviteLinkId : inviteLinkId // ignore: cast_nullable_to_non_nullable
as String,profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
