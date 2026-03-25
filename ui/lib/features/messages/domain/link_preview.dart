import 'package:freezed_annotation/freezed_annotation.dart';

part 'link_preview.freezed.dart';
part 'link_preview.g.dart';

/// Link preview metadata from OpenGraph tags
@freezed
abstract class LinkPreview with _$LinkPreview {
  const factory LinkPreview({
    /// The original URL
    required String url,

    /// Page title (og:title or <title>)
    required String title,

    /// Page description (og:description or meta description)
    String? description,

    /// Preview image URL (og:image)
    String? imageUrl,

    /// Site name (og:site_name or domain)
    String? siteName,

    /// Favicon URL
    String? favicon,
  }) = _LinkPreview;

  factory LinkPreview.fromJson(Map<String, dynamic> json) =>
      _$LinkPreviewFromJson(json);
}
