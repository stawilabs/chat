/// MXC URI value type for parsing and formatting `mxc://server_name/media_id` URIs.
///
/// MXC URIs are the canonical content identifier used by the Files API.
/// They follow the format: `mxc://<server_name>/<media_id>`
class MxcUri {
  const MxcUri._({required this.serverName, required this.mediaId});

  /// Parse an MXC URI string into its components.
  ///
  /// Throws [FormatException] if the URI is not a valid MXC URI.
  factory MxcUri.parse(String uri) {
    if (!isMxcUri(uri)) {
      throw FormatException('Invalid MXC URI: $uri');
    }

    final withoutScheme = uri.substring(6); // Remove 'mxc://'
    final slashIndex = withoutScheme.indexOf('/');
    if (slashIndex <= 0 || slashIndex >= withoutScheme.length - 1) {
      throw const FormatException(
        'Invalid MXC URI: missing server_name or media_id',
      );
    }

    return MxcUri._(
      serverName: withoutScheme.substring(0, slashIndex),
      mediaId: withoutScheme.substring(slashIndex + 1),
    );
  }

  /// Create an MXC URI from server name and media ID components.
  factory MxcUri.fromParts(String serverName, String mediaId) {
    if (serverName.isEmpty || mediaId.isEmpty) {
      throw ArgumentError('serverName and mediaId must not be empty');
    }
    return MxcUri._(serverName: serverName, mediaId: mediaId);
  }

  /// The server name component (e.g., "files.stawi.dev")
  final String serverName;

  /// The media ID component
  final String mediaId;

  /// Whether this MXC URI is structurally valid.
  bool get isValid => serverName.isNotEmpty && mediaId.isNotEmpty;

  /// Try to parse an MXC URI string, returning null if invalid.
  static MxcUri? tryParse(String uri) {
    try {
      return MxcUri.parse(uri);
    } on FormatException {
      return null;
    }
  }

  /// Check if a string is an MXC URI.
  static bool isMxcUri(String uri) =>
      uri.startsWith('mxc://') && uri.length > 6 && uri.indexOf('/', 6) > 6;

  /// Format as a full MXC URI string.
  @override
  String toString() => 'mxc://$serverName/$mediaId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MxcUri &&
          serverName == other.serverName &&
          mediaId == other.mediaId;

  @override
  int get hashCode => Object.hash(serverName, mediaId);
}
