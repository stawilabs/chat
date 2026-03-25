// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LinkPreview _$LinkPreviewFromJson(Map<String, dynamic> json) => _LinkPreview(
  url: json['url'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  imageUrl: json['imageUrl'] as String?,
  siteName: json['siteName'] as String?,
  favicon: json['favicon'] as String?,
);

Map<String, dynamic> _$LinkPreviewToJson(_LinkPreview instance) =>
    <String, dynamic>{
      'url': instance.url,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'siteName': instance.siteName,
      'favicon': instance.favicon,
    };
