// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CallStats {

/// Round-trip time in milliseconds
 double get roundTripTimeMs;/// Jitter in milliseconds
 double get jitterMs;/// Packet loss percentage (0-100)
 double get packetLossPercent;/// Available outgoing bandwidth in bits per second
 int get availableBandwidthBps;/// Current video bitrate in bits per second
 int get videoBitrateBps;/// Current audio bitrate in bits per second
 int get audioBitrateBps;/// Frames per second being sent
 double get framesSentPerSecond;/// Frames per second being received
 double get framesReceivedPerSecond;/// Video resolution width being sent
 int get videoWidthSent;/// Video resolution height being sent
 int get videoHeightSent;/// Video resolution width being received
 int get videoWidthReceived;/// Video resolution height being received
 int get videoHeightReceived;/// Total bytes sent
 int get bytesSent;/// Total bytes received
 int get bytesReceived;/// Number of packets sent
 int get packetsSent;/// Number of packets received
 int get packetsReceived;/// Number of packets lost
 int get packetsLost;/// Timestamp when stats were collected
 DateTime? get timestamp;/// Connection quality derived from stats
 ConnectionQuality get quality;/// Whether video is currently disabled due to poor connection
 bool get isVideoDisabledDueToPoorConnection;/// Whether reconnection is in progress
 bool get isReconnecting;/// Reconnection attempt count
 int get reconnectionAttempts;
/// Create a copy of CallStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallStatsCopyWith<CallStats> get copyWith => _$CallStatsCopyWithImpl<CallStats>(this as CallStats, _$identity);

  /// Serializes this CallStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallStats&&(identical(other.roundTripTimeMs, roundTripTimeMs) || other.roundTripTimeMs == roundTripTimeMs)&&(identical(other.jitterMs, jitterMs) || other.jitterMs == jitterMs)&&(identical(other.packetLossPercent, packetLossPercent) || other.packetLossPercent == packetLossPercent)&&(identical(other.availableBandwidthBps, availableBandwidthBps) || other.availableBandwidthBps == availableBandwidthBps)&&(identical(other.videoBitrateBps, videoBitrateBps) || other.videoBitrateBps == videoBitrateBps)&&(identical(other.audioBitrateBps, audioBitrateBps) || other.audioBitrateBps == audioBitrateBps)&&(identical(other.framesSentPerSecond, framesSentPerSecond) || other.framesSentPerSecond == framesSentPerSecond)&&(identical(other.framesReceivedPerSecond, framesReceivedPerSecond) || other.framesReceivedPerSecond == framesReceivedPerSecond)&&(identical(other.videoWidthSent, videoWidthSent) || other.videoWidthSent == videoWidthSent)&&(identical(other.videoHeightSent, videoHeightSent) || other.videoHeightSent == videoHeightSent)&&(identical(other.videoWidthReceived, videoWidthReceived) || other.videoWidthReceived == videoWidthReceived)&&(identical(other.videoHeightReceived, videoHeightReceived) || other.videoHeightReceived == videoHeightReceived)&&(identical(other.bytesSent, bytesSent) || other.bytesSent == bytesSent)&&(identical(other.bytesReceived, bytesReceived) || other.bytesReceived == bytesReceived)&&(identical(other.packetsSent, packetsSent) || other.packetsSent == packetsSent)&&(identical(other.packetsReceived, packetsReceived) || other.packetsReceived == packetsReceived)&&(identical(other.packetsLost, packetsLost) || other.packetsLost == packetsLost)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.isVideoDisabledDueToPoorConnection, isVideoDisabledDueToPoorConnection) || other.isVideoDisabledDueToPoorConnection == isVideoDisabledDueToPoorConnection)&&(identical(other.isReconnecting, isReconnecting) || other.isReconnecting == isReconnecting)&&(identical(other.reconnectionAttempts, reconnectionAttempts) || other.reconnectionAttempts == reconnectionAttempts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,roundTripTimeMs,jitterMs,packetLossPercent,availableBandwidthBps,videoBitrateBps,audioBitrateBps,framesSentPerSecond,framesReceivedPerSecond,videoWidthSent,videoHeightSent,videoWidthReceived,videoHeightReceived,bytesSent,bytesReceived,packetsSent,packetsReceived,packetsLost,timestamp,quality,isVideoDisabledDueToPoorConnection,isReconnecting,reconnectionAttempts]);

@override
String toString() {
  return 'CallStats(roundTripTimeMs: $roundTripTimeMs, jitterMs: $jitterMs, packetLossPercent: $packetLossPercent, availableBandwidthBps: $availableBandwidthBps, videoBitrateBps: $videoBitrateBps, audioBitrateBps: $audioBitrateBps, framesSentPerSecond: $framesSentPerSecond, framesReceivedPerSecond: $framesReceivedPerSecond, videoWidthSent: $videoWidthSent, videoHeightSent: $videoHeightSent, videoWidthReceived: $videoWidthReceived, videoHeightReceived: $videoHeightReceived, bytesSent: $bytesSent, bytesReceived: $bytesReceived, packetsSent: $packetsSent, packetsReceived: $packetsReceived, packetsLost: $packetsLost, timestamp: $timestamp, quality: $quality, isVideoDisabledDueToPoorConnection: $isVideoDisabledDueToPoorConnection, isReconnecting: $isReconnecting, reconnectionAttempts: $reconnectionAttempts)';
}


}

/// @nodoc
abstract mixin class $CallStatsCopyWith<$Res>  {
  factory $CallStatsCopyWith(CallStats value, $Res Function(CallStats) _then) = _$CallStatsCopyWithImpl;
@useResult
$Res call({
 double roundTripTimeMs, double jitterMs, double packetLossPercent, int availableBandwidthBps, int videoBitrateBps, int audioBitrateBps, double framesSentPerSecond, double framesReceivedPerSecond, int videoWidthSent, int videoHeightSent, int videoWidthReceived, int videoHeightReceived, int bytesSent, int bytesReceived, int packetsSent, int packetsReceived, int packetsLost, DateTime? timestamp, ConnectionQuality quality, bool isVideoDisabledDueToPoorConnection, bool isReconnecting, int reconnectionAttempts
});




}
/// @nodoc
class _$CallStatsCopyWithImpl<$Res>
    implements $CallStatsCopyWith<$Res> {
  _$CallStatsCopyWithImpl(this._self, this._then);

  final CallStats _self;
  final $Res Function(CallStats) _then;

/// Create a copy of CallStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roundTripTimeMs = null,Object? jitterMs = null,Object? packetLossPercent = null,Object? availableBandwidthBps = null,Object? videoBitrateBps = null,Object? audioBitrateBps = null,Object? framesSentPerSecond = null,Object? framesReceivedPerSecond = null,Object? videoWidthSent = null,Object? videoHeightSent = null,Object? videoWidthReceived = null,Object? videoHeightReceived = null,Object? bytesSent = null,Object? bytesReceived = null,Object? packetsSent = null,Object? packetsReceived = null,Object? packetsLost = null,Object? timestamp = freezed,Object? quality = null,Object? isVideoDisabledDueToPoorConnection = null,Object? isReconnecting = null,Object? reconnectionAttempts = null,}) {
  return _then(_self.copyWith(
roundTripTimeMs: null == roundTripTimeMs ? _self.roundTripTimeMs : roundTripTimeMs // ignore: cast_nullable_to_non_nullable
as double,jitterMs: null == jitterMs ? _self.jitterMs : jitterMs // ignore: cast_nullable_to_non_nullable
as double,packetLossPercent: null == packetLossPercent ? _self.packetLossPercent : packetLossPercent // ignore: cast_nullable_to_non_nullable
as double,availableBandwidthBps: null == availableBandwidthBps ? _self.availableBandwidthBps : availableBandwidthBps // ignore: cast_nullable_to_non_nullable
as int,videoBitrateBps: null == videoBitrateBps ? _self.videoBitrateBps : videoBitrateBps // ignore: cast_nullable_to_non_nullable
as int,audioBitrateBps: null == audioBitrateBps ? _self.audioBitrateBps : audioBitrateBps // ignore: cast_nullable_to_non_nullable
as int,framesSentPerSecond: null == framesSentPerSecond ? _self.framesSentPerSecond : framesSentPerSecond // ignore: cast_nullable_to_non_nullable
as double,framesReceivedPerSecond: null == framesReceivedPerSecond ? _self.framesReceivedPerSecond : framesReceivedPerSecond // ignore: cast_nullable_to_non_nullable
as double,videoWidthSent: null == videoWidthSent ? _self.videoWidthSent : videoWidthSent // ignore: cast_nullable_to_non_nullable
as int,videoHeightSent: null == videoHeightSent ? _self.videoHeightSent : videoHeightSent // ignore: cast_nullable_to_non_nullable
as int,videoWidthReceived: null == videoWidthReceived ? _self.videoWidthReceived : videoWidthReceived // ignore: cast_nullable_to_non_nullable
as int,videoHeightReceived: null == videoHeightReceived ? _self.videoHeightReceived : videoHeightReceived // ignore: cast_nullable_to_non_nullable
as int,bytesSent: null == bytesSent ? _self.bytesSent : bytesSent // ignore: cast_nullable_to_non_nullable
as int,bytesReceived: null == bytesReceived ? _self.bytesReceived : bytesReceived // ignore: cast_nullable_to_non_nullable
as int,packetsSent: null == packetsSent ? _self.packetsSent : packetsSent // ignore: cast_nullable_to_non_nullable
as int,packetsReceived: null == packetsReceived ? _self.packetsReceived : packetsReceived // ignore: cast_nullable_to_non_nullable
as int,packetsLost: null == packetsLost ? _self.packetsLost : packetsLost // ignore: cast_nullable_to_non_nullable
as int,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as ConnectionQuality,isVideoDisabledDueToPoorConnection: null == isVideoDisabledDueToPoorConnection ? _self.isVideoDisabledDueToPoorConnection : isVideoDisabledDueToPoorConnection // ignore: cast_nullable_to_non_nullable
as bool,isReconnecting: null == isReconnecting ? _self.isReconnecting : isReconnecting // ignore: cast_nullable_to_non_nullable
as bool,reconnectionAttempts: null == reconnectionAttempts ? _self.reconnectionAttempts : reconnectionAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CallStats].
extension CallStatsPatterns on CallStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CallStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CallStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CallStats value)  $default,){
final _that = this;
switch (_that) {
case _CallStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CallStats value)?  $default,){
final _that = this;
switch (_that) {
case _CallStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double roundTripTimeMs,  double jitterMs,  double packetLossPercent,  int availableBandwidthBps,  int videoBitrateBps,  int audioBitrateBps,  double framesSentPerSecond,  double framesReceivedPerSecond,  int videoWidthSent,  int videoHeightSent,  int videoWidthReceived,  int videoHeightReceived,  int bytesSent,  int bytesReceived,  int packetsSent,  int packetsReceived,  int packetsLost,  DateTime? timestamp,  ConnectionQuality quality,  bool isVideoDisabledDueToPoorConnection,  bool isReconnecting,  int reconnectionAttempts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CallStats() when $default != null:
return $default(_that.roundTripTimeMs,_that.jitterMs,_that.packetLossPercent,_that.availableBandwidthBps,_that.videoBitrateBps,_that.audioBitrateBps,_that.framesSentPerSecond,_that.framesReceivedPerSecond,_that.videoWidthSent,_that.videoHeightSent,_that.videoWidthReceived,_that.videoHeightReceived,_that.bytesSent,_that.bytesReceived,_that.packetsSent,_that.packetsReceived,_that.packetsLost,_that.timestamp,_that.quality,_that.isVideoDisabledDueToPoorConnection,_that.isReconnecting,_that.reconnectionAttempts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double roundTripTimeMs,  double jitterMs,  double packetLossPercent,  int availableBandwidthBps,  int videoBitrateBps,  int audioBitrateBps,  double framesSentPerSecond,  double framesReceivedPerSecond,  int videoWidthSent,  int videoHeightSent,  int videoWidthReceived,  int videoHeightReceived,  int bytesSent,  int bytesReceived,  int packetsSent,  int packetsReceived,  int packetsLost,  DateTime? timestamp,  ConnectionQuality quality,  bool isVideoDisabledDueToPoorConnection,  bool isReconnecting,  int reconnectionAttempts)  $default,) {final _that = this;
switch (_that) {
case _CallStats():
return $default(_that.roundTripTimeMs,_that.jitterMs,_that.packetLossPercent,_that.availableBandwidthBps,_that.videoBitrateBps,_that.audioBitrateBps,_that.framesSentPerSecond,_that.framesReceivedPerSecond,_that.videoWidthSent,_that.videoHeightSent,_that.videoWidthReceived,_that.videoHeightReceived,_that.bytesSent,_that.bytesReceived,_that.packetsSent,_that.packetsReceived,_that.packetsLost,_that.timestamp,_that.quality,_that.isVideoDisabledDueToPoorConnection,_that.isReconnecting,_that.reconnectionAttempts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double roundTripTimeMs,  double jitterMs,  double packetLossPercent,  int availableBandwidthBps,  int videoBitrateBps,  int audioBitrateBps,  double framesSentPerSecond,  double framesReceivedPerSecond,  int videoWidthSent,  int videoHeightSent,  int videoWidthReceived,  int videoHeightReceived,  int bytesSent,  int bytesReceived,  int packetsSent,  int packetsReceived,  int packetsLost,  DateTime? timestamp,  ConnectionQuality quality,  bool isVideoDisabledDueToPoorConnection,  bool isReconnecting,  int reconnectionAttempts)?  $default,) {final _that = this;
switch (_that) {
case _CallStats() when $default != null:
return $default(_that.roundTripTimeMs,_that.jitterMs,_that.packetLossPercent,_that.availableBandwidthBps,_that.videoBitrateBps,_that.audioBitrateBps,_that.framesSentPerSecond,_that.framesReceivedPerSecond,_that.videoWidthSent,_that.videoHeightSent,_that.videoWidthReceived,_that.videoHeightReceived,_that.bytesSent,_that.bytesReceived,_that.packetsSent,_that.packetsReceived,_that.packetsLost,_that.timestamp,_that.quality,_that.isVideoDisabledDueToPoorConnection,_that.isReconnecting,_that.reconnectionAttempts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CallStats extends CallStats {
  const _CallStats({this.roundTripTimeMs = 0, this.jitterMs = 0, this.packetLossPercent = 0, this.availableBandwidthBps = 0, this.videoBitrateBps = 0, this.audioBitrateBps = 0, this.framesSentPerSecond = 0, this.framesReceivedPerSecond = 0, this.videoWidthSent = 0, this.videoHeightSent = 0, this.videoWidthReceived = 0, this.videoHeightReceived = 0, this.bytesSent = 0, this.bytesReceived = 0, this.packetsSent = 0, this.packetsReceived = 0, this.packetsLost = 0, this.timestamp, this.quality = ConnectionQuality.unknown, this.isVideoDisabledDueToPoorConnection = false, this.isReconnecting = false, this.reconnectionAttempts = 0}): super._();
  factory _CallStats.fromJson(Map<String, dynamic> json) => _$CallStatsFromJson(json);

/// Round-trip time in milliseconds
@override@JsonKey() final  double roundTripTimeMs;
/// Jitter in milliseconds
@override@JsonKey() final  double jitterMs;
/// Packet loss percentage (0-100)
@override@JsonKey() final  double packetLossPercent;
/// Available outgoing bandwidth in bits per second
@override@JsonKey() final  int availableBandwidthBps;
/// Current video bitrate in bits per second
@override@JsonKey() final  int videoBitrateBps;
/// Current audio bitrate in bits per second
@override@JsonKey() final  int audioBitrateBps;
/// Frames per second being sent
@override@JsonKey() final  double framesSentPerSecond;
/// Frames per second being received
@override@JsonKey() final  double framesReceivedPerSecond;
/// Video resolution width being sent
@override@JsonKey() final  int videoWidthSent;
/// Video resolution height being sent
@override@JsonKey() final  int videoHeightSent;
/// Video resolution width being received
@override@JsonKey() final  int videoWidthReceived;
/// Video resolution height being received
@override@JsonKey() final  int videoHeightReceived;
/// Total bytes sent
@override@JsonKey() final  int bytesSent;
/// Total bytes received
@override@JsonKey() final  int bytesReceived;
/// Number of packets sent
@override@JsonKey() final  int packetsSent;
/// Number of packets received
@override@JsonKey() final  int packetsReceived;
/// Number of packets lost
@override@JsonKey() final  int packetsLost;
/// Timestamp when stats were collected
@override final  DateTime? timestamp;
/// Connection quality derived from stats
@override@JsonKey() final  ConnectionQuality quality;
/// Whether video is currently disabled due to poor connection
@override@JsonKey() final  bool isVideoDisabledDueToPoorConnection;
/// Whether reconnection is in progress
@override@JsonKey() final  bool isReconnecting;
/// Reconnection attempt count
@override@JsonKey() final  int reconnectionAttempts;

/// Create a copy of CallStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CallStatsCopyWith<_CallStats> get copyWith => __$CallStatsCopyWithImpl<_CallStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CallStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CallStats&&(identical(other.roundTripTimeMs, roundTripTimeMs) || other.roundTripTimeMs == roundTripTimeMs)&&(identical(other.jitterMs, jitterMs) || other.jitterMs == jitterMs)&&(identical(other.packetLossPercent, packetLossPercent) || other.packetLossPercent == packetLossPercent)&&(identical(other.availableBandwidthBps, availableBandwidthBps) || other.availableBandwidthBps == availableBandwidthBps)&&(identical(other.videoBitrateBps, videoBitrateBps) || other.videoBitrateBps == videoBitrateBps)&&(identical(other.audioBitrateBps, audioBitrateBps) || other.audioBitrateBps == audioBitrateBps)&&(identical(other.framesSentPerSecond, framesSentPerSecond) || other.framesSentPerSecond == framesSentPerSecond)&&(identical(other.framesReceivedPerSecond, framesReceivedPerSecond) || other.framesReceivedPerSecond == framesReceivedPerSecond)&&(identical(other.videoWidthSent, videoWidthSent) || other.videoWidthSent == videoWidthSent)&&(identical(other.videoHeightSent, videoHeightSent) || other.videoHeightSent == videoHeightSent)&&(identical(other.videoWidthReceived, videoWidthReceived) || other.videoWidthReceived == videoWidthReceived)&&(identical(other.videoHeightReceived, videoHeightReceived) || other.videoHeightReceived == videoHeightReceived)&&(identical(other.bytesSent, bytesSent) || other.bytesSent == bytesSent)&&(identical(other.bytesReceived, bytesReceived) || other.bytesReceived == bytesReceived)&&(identical(other.packetsSent, packetsSent) || other.packetsSent == packetsSent)&&(identical(other.packetsReceived, packetsReceived) || other.packetsReceived == packetsReceived)&&(identical(other.packetsLost, packetsLost) || other.packetsLost == packetsLost)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.quality, quality) || other.quality == quality)&&(identical(other.isVideoDisabledDueToPoorConnection, isVideoDisabledDueToPoorConnection) || other.isVideoDisabledDueToPoorConnection == isVideoDisabledDueToPoorConnection)&&(identical(other.isReconnecting, isReconnecting) || other.isReconnecting == isReconnecting)&&(identical(other.reconnectionAttempts, reconnectionAttempts) || other.reconnectionAttempts == reconnectionAttempts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,roundTripTimeMs,jitterMs,packetLossPercent,availableBandwidthBps,videoBitrateBps,audioBitrateBps,framesSentPerSecond,framesReceivedPerSecond,videoWidthSent,videoHeightSent,videoWidthReceived,videoHeightReceived,bytesSent,bytesReceived,packetsSent,packetsReceived,packetsLost,timestamp,quality,isVideoDisabledDueToPoorConnection,isReconnecting,reconnectionAttempts]);

@override
String toString() {
  return 'CallStats(roundTripTimeMs: $roundTripTimeMs, jitterMs: $jitterMs, packetLossPercent: $packetLossPercent, availableBandwidthBps: $availableBandwidthBps, videoBitrateBps: $videoBitrateBps, audioBitrateBps: $audioBitrateBps, framesSentPerSecond: $framesSentPerSecond, framesReceivedPerSecond: $framesReceivedPerSecond, videoWidthSent: $videoWidthSent, videoHeightSent: $videoHeightSent, videoWidthReceived: $videoWidthReceived, videoHeightReceived: $videoHeightReceived, bytesSent: $bytesSent, bytesReceived: $bytesReceived, packetsSent: $packetsSent, packetsReceived: $packetsReceived, packetsLost: $packetsLost, timestamp: $timestamp, quality: $quality, isVideoDisabledDueToPoorConnection: $isVideoDisabledDueToPoorConnection, isReconnecting: $isReconnecting, reconnectionAttempts: $reconnectionAttempts)';
}


}

/// @nodoc
abstract mixin class _$CallStatsCopyWith<$Res> implements $CallStatsCopyWith<$Res> {
  factory _$CallStatsCopyWith(_CallStats value, $Res Function(_CallStats) _then) = __$CallStatsCopyWithImpl;
@override @useResult
$Res call({
 double roundTripTimeMs, double jitterMs, double packetLossPercent, int availableBandwidthBps, int videoBitrateBps, int audioBitrateBps, double framesSentPerSecond, double framesReceivedPerSecond, int videoWidthSent, int videoHeightSent, int videoWidthReceived, int videoHeightReceived, int bytesSent, int bytesReceived, int packetsSent, int packetsReceived, int packetsLost, DateTime? timestamp, ConnectionQuality quality, bool isVideoDisabledDueToPoorConnection, bool isReconnecting, int reconnectionAttempts
});




}
/// @nodoc
class __$CallStatsCopyWithImpl<$Res>
    implements _$CallStatsCopyWith<$Res> {
  __$CallStatsCopyWithImpl(this._self, this._then);

  final _CallStats _self;
  final $Res Function(_CallStats) _then;

/// Create a copy of CallStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roundTripTimeMs = null,Object? jitterMs = null,Object? packetLossPercent = null,Object? availableBandwidthBps = null,Object? videoBitrateBps = null,Object? audioBitrateBps = null,Object? framesSentPerSecond = null,Object? framesReceivedPerSecond = null,Object? videoWidthSent = null,Object? videoHeightSent = null,Object? videoWidthReceived = null,Object? videoHeightReceived = null,Object? bytesSent = null,Object? bytesReceived = null,Object? packetsSent = null,Object? packetsReceived = null,Object? packetsLost = null,Object? timestamp = freezed,Object? quality = null,Object? isVideoDisabledDueToPoorConnection = null,Object? isReconnecting = null,Object? reconnectionAttempts = null,}) {
  return _then(_CallStats(
roundTripTimeMs: null == roundTripTimeMs ? _self.roundTripTimeMs : roundTripTimeMs // ignore: cast_nullable_to_non_nullable
as double,jitterMs: null == jitterMs ? _self.jitterMs : jitterMs // ignore: cast_nullable_to_non_nullable
as double,packetLossPercent: null == packetLossPercent ? _self.packetLossPercent : packetLossPercent // ignore: cast_nullable_to_non_nullable
as double,availableBandwidthBps: null == availableBandwidthBps ? _self.availableBandwidthBps : availableBandwidthBps // ignore: cast_nullable_to_non_nullable
as int,videoBitrateBps: null == videoBitrateBps ? _self.videoBitrateBps : videoBitrateBps // ignore: cast_nullable_to_non_nullable
as int,audioBitrateBps: null == audioBitrateBps ? _self.audioBitrateBps : audioBitrateBps // ignore: cast_nullable_to_non_nullable
as int,framesSentPerSecond: null == framesSentPerSecond ? _self.framesSentPerSecond : framesSentPerSecond // ignore: cast_nullable_to_non_nullable
as double,framesReceivedPerSecond: null == framesReceivedPerSecond ? _self.framesReceivedPerSecond : framesReceivedPerSecond // ignore: cast_nullable_to_non_nullable
as double,videoWidthSent: null == videoWidthSent ? _self.videoWidthSent : videoWidthSent // ignore: cast_nullable_to_non_nullable
as int,videoHeightSent: null == videoHeightSent ? _self.videoHeightSent : videoHeightSent // ignore: cast_nullable_to_non_nullable
as int,videoWidthReceived: null == videoWidthReceived ? _self.videoWidthReceived : videoWidthReceived // ignore: cast_nullable_to_non_nullable
as int,videoHeightReceived: null == videoHeightReceived ? _self.videoHeightReceived : videoHeightReceived // ignore: cast_nullable_to_non_nullable
as int,bytesSent: null == bytesSent ? _self.bytesSent : bytesSent // ignore: cast_nullable_to_non_nullable
as int,bytesReceived: null == bytesReceived ? _self.bytesReceived : bytesReceived // ignore: cast_nullable_to_non_nullable
as int,packetsSent: null == packetsSent ? _self.packetsSent : packetsSent // ignore: cast_nullable_to_non_nullable
as int,packetsReceived: null == packetsReceived ? _self.packetsReceived : packetsReceived // ignore: cast_nullable_to_non_nullable
as int,packetsLost: null == packetsLost ? _self.packetsLost : packetsLost // ignore: cast_nullable_to_non_nullable
as int,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as ConnectionQuality,isVideoDisabledDueToPoorConnection: null == isVideoDisabledDueToPoorConnection ? _self.isVideoDisabledDueToPoorConnection : isVideoDisabledDueToPoorConnection // ignore: cast_nullable_to_non_nullable
as bool,isReconnecting: null == isReconnecting ? _self.isReconnecting : isReconnecting // ignore: cast_nullable_to_non_nullable
as bool,reconnectionAttempts: null == reconnectionAttempts ? _self.reconnectionAttempts : reconnectionAttempts // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
