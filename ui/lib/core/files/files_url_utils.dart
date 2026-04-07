/// URL builder utilities for the Files API.
///
/// These were previously exported by `antinvestor_api_files` but were
/// removed in v1.54.0. Inlined here for forward compatibility.
library;

import 'package:antinvestor_api_files/antinvestor_api_files.dart';

/// Extracts the host from [baseUrl] for use as the server name component
/// in media URLs.
String _serverName(String baseUrl) => Uri.parse(baseUrl).host;

/// Strips trailing slashes from [baseUrl].
String _trimBaseUrl(String baseUrl) => baseUrl.replaceAll(RegExp(r'/+$'), '');

/// Builds a download URL from [baseUrl] and [mediaId].
String contentUrl(String baseUrl, String mediaId) {
  return '${_trimBaseUrl(baseUrl)}/v1/media/download/${_serverName(baseUrl)}/$mediaId';
}

/// Builds a download URL with a [fileName] override.
String contentUrlWithName(String baseUrl, String mediaId, String fileName) {
  return '${_trimBaseUrl(baseUrl)}/v1/media/download/${_serverName(baseUrl)}/$mediaId/$fileName';
}

/// Builds a thumbnail URL from [baseUrl] and [mediaId] with dimensions
/// and resize [method].
String thumbnailUrl(
  String baseUrl,
  String mediaId, {
  int width = 256,
  int height = 256,
  ThumbnailMethod method = ThumbnailMethod.SCALE,
}) {
  final uri = Uri.parse(
    '${_trimBaseUrl(baseUrl)}/v1/media/thumbnail/${_serverName(baseUrl)}/$mediaId',
  );
  return uri
      .replace(queryParameters: {
        'width': '$width',
        'height': '$height',
        'method': method.name.toLowerCase(),
      })
      .toString();
}

/// Builds a download URL from an [UploadContentResponse].
String contentUrlFromResponse(String baseUrl, UploadContentResponse response) {
  if (response.contentUri.isNotEmpty) {
    return response.contentUri;
  }
  return contentUrl(baseUrl, response.mediaId);
}
