// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'link_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinkPreview {

/// The original URL
 String get url;/// Page title (og:title or <title>)
 String get title;/// Page description (og:description or meta description)
 String? get description;/// Preview image URL (og:image)
 String? get imageUrl;/// Site name (og:site_name or domain)
 String? get siteName;/// Favicon URL
 String? get favicon;
/// Create a copy of LinkPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkPreviewCopyWith<LinkPreview> get copyWith => _$LinkPreviewCopyWithImpl<LinkPreview>(this as LinkPreview, _$identity);

  /// Serializes this LinkPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkPreview&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.siteName, siteName) || other.siteName == siteName)&&(identical(other.favicon, favicon) || other.favicon == favicon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,title,description,imageUrl,siteName,favicon);

@override
String toString() {
  return 'LinkPreview(url: $url, title: $title, description: $description, imageUrl: $imageUrl, siteName: $siteName, favicon: $favicon)';
}


}

/// @nodoc
abstract mixin class $LinkPreviewCopyWith<$Res>  {
  factory $LinkPreviewCopyWith(LinkPreview value, $Res Function(LinkPreview) _then) = _$LinkPreviewCopyWithImpl;
@useResult
$Res call({
 String url, String title, String? description, String? imageUrl, String? siteName, String? favicon
});




}
/// @nodoc
class _$LinkPreviewCopyWithImpl<$Res>
    implements $LinkPreviewCopyWith<$Res> {
  _$LinkPreviewCopyWithImpl(this._self, this._then);

  final LinkPreview _self;
  final $Res Function(LinkPreview) _then;

/// Create a copy of LinkPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? title = null,Object? description = freezed,Object? imageUrl = freezed,Object? siteName = freezed,Object? favicon = freezed,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,favicon: freezed == favicon ? _self.favicon : favicon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkPreview].
extension LinkPreviewPatterns on LinkPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinkPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinkPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinkPreview value)  $default,){
final _that = this;
switch (_that) {
case _LinkPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinkPreview value)?  $default,){
final _that = this;
switch (_that) {
case _LinkPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String title,  String? description,  String? imageUrl,  String? siteName,  String? favicon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinkPreview() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.imageUrl,_that.siteName,_that.favicon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String title,  String? description,  String? imageUrl,  String? siteName,  String? favicon)  $default,) {final _that = this;
switch (_that) {
case _LinkPreview():
return $default(_that.url,_that.title,_that.description,_that.imageUrl,_that.siteName,_that.favicon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String title,  String? description,  String? imageUrl,  String? siteName,  String? favicon)?  $default,) {final _that = this;
switch (_that) {
case _LinkPreview() when $default != null:
return $default(_that.url,_that.title,_that.description,_that.imageUrl,_that.siteName,_that.favicon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinkPreview implements LinkPreview {
  const _LinkPreview({required this.url, required this.title, this.description, this.imageUrl, this.siteName, this.favicon});
  factory _LinkPreview.fromJson(Map<String, dynamic> json) => _$LinkPreviewFromJson(json);

/// The original URL
@override final  String url;
/// Page title (og:title or <title>)
@override final  String title;
/// Page description (og:description or meta description)
@override final  String? description;
/// Preview image URL (og:image)
@override final  String? imageUrl;
/// Site name (og:site_name or domain)
@override final  String? siteName;
/// Favicon URL
@override final  String? favicon;

/// Create a copy of LinkPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinkPreviewCopyWith<_LinkPreview> get copyWith => __$LinkPreviewCopyWithImpl<_LinkPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinkPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinkPreview&&(identical(other.url, url) || other.url == url)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.siteName, siteName) || other.siteName == siteName)&&(identical(other.favicon, favicon) || other.favicon == favicon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,title,description,imageUrl,siteName,favicon);

@override
String toString() {
  return 'LinkPreview(url: $url, title: $title, description: $description, imageUrl: $imageUrl, siteName: $siteName, favicon: $favicon)';
}


}

/// @nodoc
abstract mixin class _$LinkPreviewCopyWith<$Res> implements $LinkPreviewCopyWith<$Res> {
  factory _$LinkPreviewCopyWith(_LinkPreview value, $Res Function(_LinkPreview) _then) = __$LinkPreviewCopyWithImpl;
@override @useResult
$Res call({
 String url, String title, String? description, String? imageUrl, String? siteName, String? favicon
});




}
/// @nodoc
class __$LinkPreviewCopyWithImpl<$Res>
    implements _$LinkPreviewCopyWith<$Res> {
  __$LinkPreviewCopyWithImpl(this._self, this._then);

  final _LinkPreview _self;
  final $Res Function(_LinkPreview) _then;

/// Create a copy of LinkPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? title = null,Object? description = freezed,Object? imageUrl = freezed,Object? siteName = freezed,Object? favicon = freezed,}) {
  return _then(_LinkPreview(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,siteName: freezed == siteName ? _self.siteName : siteName // ignore: cast_nullable_to_non_nullable
as String?,favicon: freezed == favicon ? _self.favicon : favicon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
