// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyticsEvent {

 String get id; AnalyticsEventType get type; String get name; DateTime get timestamp; String? get userId; String? get sessionId; String? get screenName; Map<String, dynamic>? get properties; Map<String, dynamic>? get userProperties; bool get isSynced;
/// Create a copy of AnalyticsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsEventCopyWith<AnalyticsEvent> get copyWith => _$AnalyticsEventCopyWithImpl<AnalyticsEvent>(this as AnalyticsEvent, _$identity);

  /// Serializes this AnalyticsEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.screenName, screenName) || other.screenName == screenName)&&const DeepCollectionEquality().equals(other.properties, properties)&&const DeepCollectionEquality().equals(other.userProperties, userProperties)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,timestamp,userId,sessionId,screenName,const DeepCollectionEquality().hash(properties),const DeepCollectionEquality().hash(userProperties),isSynced);

@override
String toString() {
  return 'AnalyticsEvent(id: $id, type: $type, name: $name, timestamp: $timestamp, userId: $userId, sessionId: $sessionId, screenName: $screenName, properties: $properties, userProperties: $userProperties, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class $AnalyticsEventCopyWith<$Res>  {
  factory $AnalyticsEventCopyWith(AnalyticsEvent value, $Res Function(AnalyticsEvent) _then) = _$AnalyticsEventCopyWithImpl;
@useResult
$Res call({
 String id, AnalyticsEventType type, String name, DateTime timestamp, String? userId, String? sessionId, String? screenName, Map<String, dynamic>? properties, Map<String, dynamic>? userProperties, bool isSynced
});




}
/// @nodoc
class _$AnalyticsEventCopyWithImpl<$Res>
    implements $AnalyticsEventCopyWith<$Res> {
  _$AnalyticsEventCopyWithImpl(this._self, this._then);

  final AnalyticsEvent _self;
  final $Res Function(AnalyticsEvent) _then;

/// Create a copy of AnalyticsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? timestamp = null,Object? userId = freezed,Object? sessionId = freezed,Object? screenName = freezed,Object? properties = freezed,Object? userProperties = freezed,Object? isSynced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnalyticsEventType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,screenName: freezed == screenName ? _self.screenName : screenName // ignore: cast_nullable_to_non_nullable
as String?,properties: freezed == properties ? _self.properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,userProperties: freezed == userProperties ? _self.userProperties : userProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsEvent].
extension AnalyticsEventPatterns on AnalyticsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsEvent value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AnalyticsEventType type,  String name,  DateTime timestamp,  String? userId,  String? sessionId,  String? screenName,  Map<String, dynamic>? properties,  Map<String, dynamic>? userProperties,  bool isSynced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsEvent() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.timestamp,_that.userId,_that.sessionId,_that.screenName,_that.properties,_that.userProperties,_that.isSynced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AnalyticsEventType type,  String name,  DateTime timestamp,  String? userId,  String? sessionId,  String? screenName,  Map<String, dynamic>? properties,  Map<String, dynamic>? userProperties,  bool isSynced)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsEvent():
return $default(_that.id,_that.type,_that.name,_that.timestamp,_that.userId,_that.sessionId,_that.screenName,_that.properties,_that.userProperties,_that.isSynced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AnalyticsEventType type,  String name,  DateTime timestamp,  String? userId,  String? sessionId,  String? screenName,  Map<String, dynamic>? properties,  Map<String, dynamic>? userProperties,  bool isSynced)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsEvent() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.timestamp,_that.userId,_that.sessionId,_that.screenName,_that.properties,_that.userProperties,_that.isSynced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsEvent extends AnalyticsEvent {
  const _AnalyticsEvent({required this.id, required this.type, required this.name, required this.timestamp, this.userId, this.sessionId, this.screenName, final  Map<String, dynamic>? properties, final  Map<String, dynamic>? userProperties, this.isSynced = false}): _properties = properties,_userProperties = userProperties,super._();
  factory _AnalyticsEvent.fromJson(Map<String, dynamic> json) => _$AnalyticsEventFromJson(json);

@override final  String id;
@override final  AnalyticsEventType type;
@override final  String name;
@override final  DateTime timestamp;
@override final  String? userId;
@override final  String? sessionId;
@override final  String? screenName;
 final  Map<String, dynamic>? _properties;
@override Map<String, dynamic>? get properties {
  final value = _properties;
  if (value == null) return null;
  if (_properties is EqualUnmodifiableMapView) return _properties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _userProperties;
@override Map<String, dynamic>? get userProperties {
  final value = _userProperties;
  if (value == null) return null;
  if (_userProperties is EqualUnmodifiableMapView) return _userProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey() final  bool isSynced;

/// Create a copy of AnalyticsEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsEventCopyWith<_AnalyticsEvent> get copyWith => __$AnalyticsEventCopyWithImpl<_AnalyticsEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.screenName, screenName) || other.screenName == screenName)&&const DeepCollectionEquality().equals(other._properties, _properties)&&const DeepCollectionEquality().equals(other._userProperties, _userProperties)&&(identical(other.isSynced, isSynced) || other.isSynced == isSynced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,timestamp,userId,sessionId,screenName,const DeepCollectionEquality().hash(_properties),const DeepCollectionEquality().hash(_userProperties),isSynced);

@override
String toString() {
  return 'AnalyticsEvent(id: $id, type: $type, name: $name, timestamp: $timestamp, userId: $userId, sessionId: $sessionId, screenName: $screenName, properties: $properties, userProperties: $userProperties, isSynced: $isSynced)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsEventCopyWith<$Res> implements $AnalyticsEventCopyWith<$Res> {
  factory _$AnalyticsEventCopyWith(_AnalyticsEvent value, $Res Function(_AnalyticsEvent) _then) = __$AnalyticsEventCopyWithImpl;
@override @useResult
$Res call({
 String id, AnalyticsEventType type, String name, DateTime timestamp, String? userId, String? sessionId, String? screenName, Map<String, dynamic>? properties, Map<String, dynamic>? userProperties, bool isSynced
});




}
/// @nodoc
class __$AnalyticsEventCopyWithImpl<$Res>
    implements _$AnalyticsEventCopyWith<$Res> {
  __$AnalyticsEventCopyWithImpl(this._self, this._then);

  final _AnalyticsEvent _self;
  final $Res Function(_AnalyticsEvent) _then;

/// Create a copy of AnalyticsEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? timestamp = null,Object? userId = freezed,Object? sessionId = freezed,Object? screenName = freezed,Object? properties = freezed,Object? userProperties = freezed,Object? isSynced = null,}) {
  return _then(_AnalyticsEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnalyticsEventType,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,screenName: freezed == screenName ? _self.screenName : screenName // ignore: cast_nullable_to_non_nullable
as String?,properties: freezed == properties ? _self._properties : properties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,userProperties: freezed == userProperties ? _self._userProperties : userProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,isSynced: null == isSynced ? _self.isSynced : isSynced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$AnalyticsUserProperties {

 String? get userId; String? get displayName; String? get email; String? get phoneNumber; DateTime? get accountCreatedAt; DateTime? get lastLoginAt; String? get appVersion; String? get platform; String? get deviceModel; String? get osVersion; String? get locale; int? get totalRooms; int? get totalContacts; Map<String, dynamic>? get customProperties;
/// Create a copy of AnalyticsUserProperties
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsUserPropertiesCopyWith<AnalyticsUserProperties> get copyWith => _$AnalyticsUserPropertiesCopyWithImpl<AnalyticsUserProperties>(this as AnalyticsUserProperties, _$identity);

  /// Serializes this AnalyticsUserProperties to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsUserProperties&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.accountCreatedAt, accountCreatedAt) || other.accountCreatedAt == accountCreatedAt)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.deviceModel, deviceModel) || other.deviceModel == deviceModel)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.totalRooms, totalRooms) || other.totalRooms == totalRooms)&&(identical(other.totalContacts, totalContacts) || other.totalContacts == totalContacts)&&const DeepCollectionEquality().equals(other.customProperties, customProperties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,email,phoneNumber,accountCreatedAt,lastLoginAt,appVersion,platform,deviceModel,osVersion,locale,totalRooms,totalContacts,const DeepCollectionEquality().hash(customProperties));

@override
String toString() {
  return 'AnalyticsUserProperties(userId: $userId, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, accountCreatedAt: $accountCreatedAt, lastLoginAt: $lastLoginAt, appVersion: $appVersion, platform: $platform, deviceModel: $deviceModel, osVersion: $osVersion, locale: $locale, totalRooms: $totalRooms, totalContacts: $totalContacts, customProperties: $customProperties)';
}


}

/// @nodoc
abstract mixin class $AnalyticsUserPropertiesCopyWith<$Res>  {
  factory $AnalyticsUserPropertiesCopyWith(AnalyticsUserProperties value, $Res Function(AnalyticsUserProperties) _then) = _$AnalyticsUserPropertiesCopyWithImpl;
@useResult
$Res call({
 String? userId, String? displayName, String? email, String? phoneNumber, DateTime? accountCreatedAt, DateTime? lastLoginAt, String? appVersion, String? platform, String? deviceModel, String? osVersion, String? locale, int? totalRooms, int? totalContacts, Map<String, dynamic>? customProperties
});




}
/// @nodoc
class _$AnalyticsUserPropertiesCopyWithImpl<$Res>
    implements $AnalyticsUserPropertiesCopyWith<$Res> {
  _$AnalyticsUserPropertiesCopyWithImpl(this._self, this._then);

  final AnalyticsUserProperties _self;
  final $Res Function(AnalyticsUserProperties) _then;

/// Create a copy of AnalyticsUserProperties
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = freezed,Object? displayName = freezed,Object? email = freezed,Object? phoneNumber = freezed,Object? accountCreatedAt = freezed,Object? lastLoginAt = freezed,Object? appVersion = freezed,Object? platform = freezed,Object? deviceModel = freezed,Object? osVersion = freezed,Object? locale = freezed,Object? totalRooms = freezed,Object? totalContacts = freezed,Object? customProperties = freezed,}) {
  return _then(_self.copyWith(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,accountCreatedAt: freezed == accountCreatedAt ? _self.accountCreatedAt : accountCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,deviceModel: freezed == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,totalRooms: freezed == totalRooms ? _self.totalRooms : totalRooms // ignore: cast_nullable_to_non_nullable
as int?,totalContacts: freezed == totalContacts ? _self.totalContacts : totalContacts // ignore: cast_nullable_to_non_nullable
as int?,customProperties: freezed == customProperties ? _self.customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsUserProperties].
extension AnalyticsUserPropertiesPatterns on AnalyticsUserProperties {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsUserProperties value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsUserProperties() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsUserProperties value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsUserProperties():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsUserProperties value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsUserProperties() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? userId,  String? displayName,  String? email,  String? phoneNumber,  DateTime? accountCreatedAt,  DateTime? lastLoginAt,  String? appVersion,  String? platform,  String? deviceModel,  String? osVersion,  String? locale,  int? totalRooms,  int? totalContacts,  Map<String, dynamic>? customProperties)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsUserProperties() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.phoneNumber,_that.accountCreatedAt,_that.lastLoginAt,_that.appVersion,_that.platform,_that.deviceModel,_that.osVersion,_that.locale,_that.totalRooms,_that.totalContacts,_that.customProperties);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? userId,  String? displayName,  String? email,  String? phoneNumber,  DateTime? accountCreatedAt,  DateTime? lastLoginAt,  String? appVersion,  String? platform,  String? deviceModel,  String? osVersion,  String? locale,  int? totalRooms,  int? totalContacts,  Map<String, dynamic>? customProperties)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsUserProperties():
return $default(_that.userId,_that.displayName,_that.email,_that.phoneNumber,_that.accountCreatedAt,_that.lastLoginAt,_that.appVersion,_that.platform,_that.deviceModel,_that.osVersion,_that.locale,_that.totalRooms,_that.totalContacts,_that.customProperties);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? userId,  String? displayName,  String? email,  String? phoneNumber,  DateTime? accountCreatedAt,  DateTime? lastLoginAt,  String? appVersion,  String? platform,  String? deviceModel,  String? osVersion,  String? locale,  int? totalRooms,  int? totalContacts,  Map<String, dynamic>? customProperties)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsUserProperties() when $default != null:
return $default(_that.userId,_that.displayName,_that.email,_that.phoneNumber,_that.accountCreatedAt,_that.lastLoginAt,_that.appVersion,_that.platform,_that.deviceModel,_that.osVersion,_that.locale,_that.totalRooms,_that.totalContacts,_that.customProperties);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsUserProperties implements AnalyticsUserProperties {
  const _AnalyticsUserProperties({this.userId, this.displayName, this.email, this.phoneNumber, this.accountCreatedAt, this.lastLoginAt, this.appVersion, this.platform, this.deviceModel, this.osVersion, this.locale, this.totalRooms, this.totalContacts, final  Map<String, dynamic>? customProperties}): _customProperties = customProperties;
  factory _AnalyticsUserProperties.fromJson(Map<String, dynamic> json) => _$AnalyticsUserPropertiesFromJson(json);

@override final  String? userId;
@override final  String? displayName;
@override final  String? email;
@override final  String? phoneNumber;
@override final  DateTime? accountCreatedAt;
@override final  DateTime? lastLoginAt;
@override final  String? appVersion;
@override final  String? platform;
@override final  String? deviceModel;
@override final  String? osVersion;
@override final  String? locale;
@override final  int? totalRooms;
@override final  int? totalContacts;
 final  Map<String, dynamic>? _customProperties;
@override Map<String, dynamic>? get customProperties {
  final value = _customProperties;
  if (value == null) return null;
  if (_customProperties is EqualUnmodifiableMapView) return _customProperties;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AnalyticsUserProperties
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsUserPropertiesCopyWith<_AnalyticsUserProperties> get copyWith => __$AnalyticsUserPropertiesCopyWithImpl<_AnalyticsUserProperties>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsUserPropertiesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsUserProperties&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.accountCreatedAt, accountCreatedAt) || other.accountCreatedAt == accountCreatedAt)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.deviceModel, deviceModel) || other.deviceModel == deviceModel)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.totalRooms, totalRooms) || other.totalRooms == totalRooms)&&(identical(other.totalContacts, totalContacts) || other.totalContacts == totalContacts)&&const DeepCollectionEquality().equals(other._customProperties, _customProperties));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,email,phoneNumber,accountCreatedAt,lastLoginAt,appVersion,platform,deviceModel,osVersion,locale,totalRooms,totalContacts,const DeepCollectionEquality().hash(_customProperties));

@override
String toString() {
  return 'AnalyticsUserProperties(userId: $userId, displayName: $displayName, email: $email, phoneNumber: $phoneNumber, accountCreatedAt: $accountCreatedAt, lastLoginAt: $lastLoginAt, appVersion: $appVersion, platform: $platform, deviceModel: $deviceModel, osVersion: $osVersion, locale: $locale, totalRooms: $totalRooms, totalContacts: $totalContacts, customProperties: $customProperties)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsUserPropertiesCopyWith<$Res> implements $AnalyticsUserPropertiesCopyWith<$Res> {
  factory _$AnalyticsUserPropertiesCopyWith(_AnalyticsUserProperties value, $Res Function(_AnalyticsUserProperties) _then) = __$AnalyticsUserPropertiesCopyWithImpl;
@override @useResult
$Res call({
 String? userId, String? displayName, String? email, String? phoneNumber, DateTime? accountCreatedAt, DateTime? lastLoginAt, String? appVersion, String? platform, String? deviceModel, String? osVersion, String? locale, int? totalRooms, int? totalContacts, Map<String, dynamic>? customProperties
});




}
/// @nodoc
class __$AnalyticsUserPropertiesCopyWithImpl<$Res>
    implements _$AnalyticsUserPropertiesCopyWith<$Res> {
  __$AnalyticsUserPropertiesCopyWithImpl(this._self, this._then);

  final _AnalyticsUserProperties _self;
  final $Res Function(_AnalyticsUserProperties) _then;

/// Create a copy of AnalyticsUserProperties
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = freezed,Object? displayName = freezed,Object? email = freezed,Object? phoneNumber = freezed,Object? accountCreatedAt = freezed,Object? lastLoginAt = freezed,Object? appVersion = freezed,Object? platform = freezed,Object? deviceModel = freezed,Object? osVersion = freezed,Object? locale = freezed,Object? totalRooms = freezed,Object? totalContacts = freezed,Object? customProperties = freezed,}) {
  return _then(_AnalyticsUserProperties(
userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,phoneNumber: freezed == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String?,accountCreatedAt: freezed == accountCreatedAt ? _self.accountCreatedAt : accountCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as DateTime?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,platform: freezed == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String?,deviceModel: freezed == deviceModel ? _self.deviceModel : deviceModel // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,totalRooms: freezed == totalRooms ? _self.totalRooms : totalRooms // ignore: cast_nullable_to_non_nullable
as int?,totalContacts: freezed == totalContacts ? _self.totalContacts : totalContacts // ignore: cast_nullable_to_non_nullable
as int?,customProperties: freezed == customProperties ? _self._customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$AnalyticsSession {

 String get id; DateTime get startTime; DateTime? get endTime; int get eventCount; int get screenViewCount; String? get entryScreen; String? get exitScreen; String? get userId; Map<String, dynamic>? get deviceInfo;
/// Create a copy of AnalyticsSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsSessionCopyWith<AnalyticsSession> get copyWith => _$AnalyticsSessionCopyWithImpl<AnalyticsSession>(this as AnalyticsSession, _$identity);

  /// Serializes this AnalyticsSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.screenViewCount, screenViewCount) || other.screenViewCount == screenViewCount)&&(identical(other.entryScreen, entryScreen) || other.entryScreen == entryScreen)&&(identical(other.exitScreen, exitScreen) || other.exitScreen == exitScreen)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other.deviceInfo, deviceInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,eventCount,screenViewCount,entryScreen,exitScreen,userId,const DeepCollectionEquality().hash(deviceInfo));

@override
String toString() {
  return 'AnalyticsSession(id: $id, startTime: $startTime, endTime: $endTime, eventCount: $eventCount, screenViewCount: $screenViewCount, entryScreen: $entryScreen, exitScreen: $exitScreen, userId: $userId, deviceInfo: $deviceInfo)';
}


}

/// @nodoc
abstract mixin class $AnalyticsSessionCopyWith<$Res>  {
  factory $AnalyticsSessionCopyWith(AnalyticsSession value, $Res Function(AnalyticsSession) _then) = _$AnalyticsSessionCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startTime, DateTime? endTime, int eventCount, int screenViewCount, String? entryScreen, String? exitScreen, String? userId, Map<String, dynamic>? deviceInfo
});




}
/// @nodoc
class _$AnalyticsSessionCopyWithImpl<$Res>
    implements $AnalyticsSessionCopyWith<$Res> {
  _$AnalyticsSessionCopyWithImpl(this._self, this._then);

  final AnalyticsSession _self;
  final $Res Function(AnalyticsSession) _then;

/// Create a copy of AnalyticsSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startTime = null,Object? endTime = freezed,Object? eventCount = null,Object? screenViewCount = null,Object? entryScreen = freezed,Object? exitScreen = freezed,Object? userId = freezed,Object? deviceInfo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,screenViewCount: null == screenViewCount ? _self.screenViewCount : screenViewCount // ignore: cast_nullable_to_non_nullable
as int,entryScreen: freezed == entryScreen ? _self.entryScreen : entryScreen // ignore: cast_nullable_to_non_nullable
as String?,exitScreen: freezed == exitScreen ? _self.exitScreen : exitScreen // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self.deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsSession].
extension AnalyticsSessionPatterns on AnalyticsSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsSession value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsSession value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startTime,  DateTime? endTime,  int eventCount,  int screenViewCount,  String? entryScreen,  String? exitScreen,  String? userId,  Map<String, dynamic>? deviceInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsSession() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.eventCount,_that.screenViewCount,_that.entryScreen,_that.exitScreen,_that.userId,_that.deviceInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startTime,  DateTime? endTime,  int eventCount,  int screenViewCount,  String? entryScreen,  String? exitScreen,  String? userId,  Map<String, dynamic>? deviceInfo)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsSession():
return $default(_that.id,_that.startTime,_that.endTime,_that.eventCount,_that.screenViewCount,_that.entryScreen,_that.exitScreen,_that.userId,_that.deviceInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startTime,  DateTime? endTime,  int eventCount,  int screenViewCount,  String? entryScreen,  String? exitScreen,  String? userId,  Map<String, dynamic>? deviceInfo)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsSession() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.eventCount,_that.screenViewCount,_that.entryScreen,_that.exitScreen,_that.userId,_that.deviceInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsSession extends AnalyticsSession {
  const _AnalyticsSession({required this.id, required this.startTime, this.endTime, this.eventCount = 0, this.screenViewCount = 0, this.entryScreen, this.exitScreen, this.userId, final  Map<String, dynamic>? deviceInfo}): _deviceInfo = deviceInfo,super._();
  factory _AnalyticsSession.fromJson(Map<String, dynamic> json) => _$AnalyticsSessionFromJson(json);

@override final  String id;
@override final  DateTime startTime;
@override final  DateTime? endTime;
@override@JsonKey() final  int eventCount;
@override@JsonKey() final  int screenViewCount;
@override final  String? entryScreen;
@override final  String? exitScreen;
@override final  String? userId;
 final  Map<String, dynamic>? _deviceInfo;
@override Map<String, dynamic>? get deviceInfo {
  final value = _deviceInfo;
  if (value == null) return null;
  if (_deviceInfo is EqualUnmodifiableMapView) return _deviceInfo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AnalyticsSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsSessionCopyWith<_AnalyticsSession> get copyWith => __$AnalyticsSessionCopyWithImpl<_AnalyticsSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.eventCount, eventCount) || other.eventCount == eventCount)&&(identical(other.screenViewCount, screenViewCount) || other.screenViewCount == screenViewCount)&&(identical(other.entryScreen, entryScreen) || other.entryScreen == entryScreen)&&(identical(other.exitScreen, exitScreen) || other.exitScreen == exitScreen)&&(identical(other.userId, userId) || other.userId == userId)&&const DeepCollectionEquality().equals(other._deviceInfo, _deviceInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,eventCount,screenViewCount,entryScreen,exitScreen,userId,const DeepCollectionEquality().hash(_deviceInfo));

@override
String toString() {
  return 'AnalyticsSession(id: $id, startTime: $startTime, endTime: $endTime, eventCount: $eventCount, screenViewCount: $screenViewCount, entryScreen: $entryScreen, exitScreen: $exitScreen, userId: $userId, deviceInfo: $deviceInfo)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsSessionCopyWith<$Res> implements $AnalyticsSessionCopyWith<$Res> {
  factory _$AnalyticsSessionCopyWith(_AnalyticsSession value, $Res Function(_AnalyticsSession) _then) = __$AnalyticsSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startTime, DateTime? endTime, int eventCount, int screenViewCount, String? entryScreen, String? exitScreen, String? userId, Map<String, dynamic>? deviceInfo
});




}
/// @nodoc
class __$AnalyticsSessionCopyWithImpl<$Res>
    implements _$AnalyticsSessionCopyWith<$Res> {
  __$AnalyticsSessionCopyWithImpl(this._self, this._then);

  final _AnalyticsSession _self;
  final $Res Function(_AnalyticsSession) _then;

/// Create a copy of AnalyticsSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startTime = null,Object? endTime = freezed,Object? eventCount = null,Object? screenViewCount = null,Object? entryScreen = freezed,Object? exitScreen = freezed,Object? userId = freezed,Object? deviceInfo = freezed,}) {
  return _then(_AnalyticsSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as DateTime?,eventCount: null == eventCount ? _self.eventCount : eventCount // ignore: cast_nullable_to_non_nullable
as int,screenViewCount: null == screenViewCount ? _self.screenViewCount : screenViewCount // ignore: cast_nullable_to_non_nullable
as int,entryScreen: freezed == entryScreen ? _self.entryScreen : entryScreen // ignore: cast_nullable_to_non_nullable
as String?,exitScreen: freezed == exitScreen ? _self.exitScreen : exitScreen // ignore: cast_nullable_to_non_nullable
as String?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String?,deviceInfo: freezed == deviceInfo ? _self._deviceInfo : deviceInfo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
