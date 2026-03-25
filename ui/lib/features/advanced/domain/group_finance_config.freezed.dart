// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_finance_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupFinanceConfig {

 GroupType get groupType; String get groupCurrency; PeriodType? get periodType; double? get periodicSaving; DateTime? get groupSavingsDay; DateTime? get terminationDate; int? get groupTenure; double? get registrationFee; int? get membersRequired;
/// Create a copy of GroupFinanceConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupFinanceConfigCopyWith<GroupFinanceConfig> get copyWith => _$GroupFinanceConfigCopyWithImpl<GroupFinanceConfig>(this as GroupFinanceConfig, _$identity);

  /// Serializes this GroupFinanceConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupFinanceConfig&&(identical(other.groupType, groupType) || other.groupType == groupType)&&(identical(other.groupCurrency, groupCurrency) || other.groupCurrency == groupCurrency)&&(identical(other.periodType, periodType) || other.periodType == periodType)&&(identical(other.periodicSaving, periodicSaving) || other.periodicSaving == periodicSaving)&&(identical(other.groupSavingsDay, groupSavingsDay) || other.groupSavingsDay == groupSavingsDay)&&(identical(other.terminationDate, terminationDate) || other.terminationDate == terminationDate)&&(identical(other.groupTenure, groupTenure) || other.groupTenure == groupTenure)&&(identical(other.registrationFee, registrationFee) || other.registrationFee == registrationFee)&&(identical(other.membersRequired, membersRequired) || other.membersRequired == membersRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupType,groupCurrency,periodType,periodicSaving,groupSavingsDay,terminationDate,groupTenure,registrationFee,membersRequired);

@override
String toString() {
  return 'GroupFinanceConfig(groupType: $groupType, groupCurrency: $groupCurrency, periodType: $periodType, periodicSaving: $periodicSaving, groupSavingsDay: $groupSavingsDay, terminationDate: $terminationDate, groupTenure: $groupTenure, registrationFee: $registrationFee, membersRequired: $membersRequired)';
}


}

/// @nodoc
abstract mixin class $GroupFinanceConfigCopyWith<$Res>  {
  factory $GroupFinanceConfigCopyWith(GroupFinanceConfig value, $Res Function(GroupFinanceConfig) _then) = _$GroupFinanceConfigCopyWithImpl;
@useResult
$Res call({
 GroupType groupType, String groupCurrency, PeriodType? periodType, double? periodicSaving, DateTime? groupSavingsDay, DateTime? terminationDate, int? groupTenure, double? registrationFee, int? membersRequired
});




}
/// @nodoc
class _$GroupFinanceConfigCopyWithImpl<$Res>
    implements $GroupFinanceConfigCopyWith<$Res> {
  _$GroupFinanceConfigCopyWithImpl(this._self, this._then);

  final GroupFinanceConfig _self;
  final $Res Function(GroupFinanceConfig) _then;

/// Create a copy of GroupFinanceConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupType = null,Object? groupCurrency = null,Object? periodType = freezed,Object? periodicSaving = freezed,Object? groupSavingsDay = freezed,Object? terminationDate = freezed,Object? groupTenure = freezed,Object? registrationFee = freezed,Object? membersRequired = freezed,}) {
  return _then(_self.copyWith(
groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as GroupType,groupCurrency: null == groupCurrency ? _self.groupCurrency : groupCurrency // ignore: cast_nullable_to_non_nullable
as String,periodType: freezed == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as PeriodType?,periodicSaving: freezed == periodicSaving ? _self.periodicSaving : periodicSaving // ignore: cast_nullable_to_non_nullable
as double?,groupSavingsDay: freezed == groupSavingsDay ? _self.groupSavingsDay : groupSavingsDay // ignore: cast_nullable_to_non_nullable
as DateTime?,terminationDate: freezed == terminationDate ? _self.terminationDate : terminationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,groupTenure: freezed == groupTenure ? _self.groupTenure : groupTenure // ignore: cast_nullable_to_non_nullable
as int?,registrationFee: freezed == registrationFee ? _self.registrationFee : registrationFee // ignore: cast_nullable_to_non_nullable
as double?,membersRequired: freezed == membersRequired ? _self.membersRequired : membersRequired // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupFinanceConfig].
extension GroupFinanceConfigPatterns on GroupFinanceConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupFinanceConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupFinanceConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupFinanceConfig value)  $default,){
final _that = this;
switch (_that) {
case _GroupFinanceConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupFinanceConfig value)?  $default,){
final _that = this;
switch (_that) {
case _GroupFinanceConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupType groupType,  String groupCurrency,  PeriodType? periodType,  double? periodicSaving,  DateTime? groupSavingsDay,  DateTime? terminationDate,  int? groupTenure,  double? registrationFee,  int? membersRequired)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupFinanceConfig() when $default != null:
return $default(_that.groupType,_that.groupCurrency,_that.periodType,_that.periodicSaving,_that.groupSavingsDay,_that.terminationDate,_that.groupTenure,_that.registrationFee,_that.membersRequired);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupType groupType,  String groupCurrency,  PeriodType? periodType,  double? periodicSaving,  DateTime? groupSavingsDay,  DateTime? terminationDate,  int? groupTenure,  double? registrationFee,  int? membersRequired)  $default,) {final _that = this;
switch (_that) {
case _GroupFinanceConfig():
return $default(_that.groupType,_that.groupCurrency,_that.periodType,_that.periodicSaving,_that.groupSavingsDay,_that.terminationDate,_that.groupTenure,_that.registrationFee,_that.membersRequired);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupType groupType,  String groupCurrency,  PeriodType? periodType,  double? periodicSaving,  DateTime? groupSavingsDay,  DateTime? terminationDate,  int? groupTenure,  double? registrationFee,  int? membersRequired)?  $default,) {final _that = this;
switch (_that) {
case _GroupFinanceConfig() when $default != null:
return $default(_that.groupType,_that.groupCurrency,_that.periodType,_that.periodicSaving,_that.groupSavingsDay,_that.terminationDate,_that.groupTenure,_that.registrationFee,_that.membersRequired);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupFinanceConfig extends GroupFinanceConfig {
  const _GroupFinanceConfig({required this.groupType, required this.groupCurrency, this.periodType, this.periodicSaving, this.groupSavingsDay, this.terminationDate, this.groupTenure, this.registrationFee, this.membersRequired}): super._();
  factory _GroupFinanceConfig.fromJson(Map<String, dynamic> json) => _$GroupFinanceConfigFromJson(json);

@override final  GroupType groupType;
@override final  String groupCurrency;
@override final  PeriodType? periodType;
@override final  double? periodicSaving;
@override final  DateTime? groupSavingsDay;
@override final  DateTime? terminationDate;
@override final  int? groupTenure;
@override final  double? registrationFee;
@override final  int? membersRequired;

/// Create a copy of GroupFinanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupFinanceConfigCopyWith<_GroupFinanceConfig> get copyWith => __$GroupFinanceConfigCopyWithImpl<_GroupFinanceConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupFinanceConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupFinanceConfig&&(identical(other.groupType, groupType) || other.groupType == groupType)&&(identical(other.groupCurrency, groupCurrency) || other.groupCurrency == groupCurrency)&&(identical(other.periodType, periodType) || other.periodType == periodType)&&(identical(other.periodicSaving, periodicSaving) || other.periodicSaving == periodicSaving)&&(identical(other.groupSavingsDay, groupSavingsDay) || other.groupSavingsDay == groupSavingsDay)&&(identical(other.terminationDate, terminationDate) || other.terminationDate == terminationDate)&&(identical(other.groupTenure, groupTenure) || other.groupTenure == groupTenure)&&(identical(other.registrationFee, registrationFee) || other.registrationFee == registrationFee)&&(identical(other.membersRequired, membersRequired) || other.membersRequired == membersRequired));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupType,groupCurrency,periodType,periodicSaving,groupSavingsDay,terminationDate,groupTenure,registrationFee,membersRequired);

@override
String toString() {
  return 'GroupFinanceConfig(groupType: $groupType, groupCurrency: $groupCurrency, periodType: $periodType, periodicSaving: $periodicSaving, groupSavingsDay: $groupSavingsDay, terminationDate: $terminationDate, groupTenure: $groupTenure, registrationFee: $registrationFee, membersRequired: $membersRequired)';
}


}

/// @nodoc
abstract mixin class _$GroupFinanceConfigCopyWith<$Res> implements $GroupFinanceConfigCopyWith<$Res> {
  factory _$GroupFinanceConfigCopyWith(_GroupFinanceConfig value, $Res Function(_GroupFinanceConfig) _then) = __$GroupFinanceConfigCopyWithImpl;
@override @useResult
$Res call({
 GroupType groupType, String groupCurrency, PeriodType? periodType, double? periodicSaving, DateTime? groupSavingsDay, DateTime? terminationDate, int? groupTenure, double? registrationFee, int? membersRequired
});




}
/// @nodoc
class __$GroupFinanceConfigCopyWithImpl<$Res>
    implements _$GroupFinanceConfigCopyWith<$Res> {
  __$GroupFinanceConfigCopyWithImpl(this._self, this._then);

  final _GroupFinanceConfig _self;
  final $Res Function(_GroupFinanceConfig) _then;

/// Create a copy of GroupFinanceConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupType = null,Object? groupCurrency = null,Object? periodType = freezed,Object? periodicSaving = freezed,Object? groupSavingsDay = freezed,Object? terminationDate = freezed,Object? groupTenure = freezed,Object? registrationFee = freezed,Object? membersRequired = freezed,}) {
  return _then(_GroupFinanceConfig(
groupType: null == groupType ? _self.groupType : groupType // ignore: cast_nullable_to_non_nullable
as GroupType,groupCurrency: null == groupCurrency ? _self.groupCurrency : groupCurrency // ignore: cast_nullable_to_non_nullable
as String,periodType: freezed == periodType ? _self.periodType : periodType // ignore: cast_nullable_to_non_nullable
as PeriodType?,periodicSaving: freezed == periodicSaving ? _self.periodicSaving : periodicSaving // ignore: cast_nullable_to_non_nullable
as double?,groupSavingsDay: freezed == groupSavingsDay ? _self.groupSavingsDay : groupSavingsDay // ignore: cast_nullable_to_non_nullable
as DateTime?,terminationDate: freezed == terminationDate ? _self.terminationDate : terminationDate // ignore: cast_nullable_to_non_nullable
as DateTime?,groupTenure: freezed == groupTenure ? _self.groupTenure : groupTenure // ignore: cast_nullable_to_non_nullable
as int?,registrationFee: freezed == registrationFee ? _self.registrationFee : registrationFee // ignore: cast_nullable_to_non_nullable
as double?,membersRequired: freezed == membersRequired ? _self.membersRequired : membersRequired // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
