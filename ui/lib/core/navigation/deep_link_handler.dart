import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router.dart';
import '../../features/rooms/data/room_service.dart';
import '../logging/app_logger.dart';

/// Provides the app's [DeepLinkHandler]. Kept alive for the app lifetime.
final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  final handler = DeepLinkHandler(ref);
  ref.onDispose(handler.dispose);
  return handler;
});

/// Handles incoming deep links (cold start + warm) and routes them to the right
/// room. The link is untrusted input, so the target room is validated against
/// the local database (rooms the user belongs to) before navigating — unknown
/// rooms route to the room list rather than force-opening an arbitrary id.
///
/// Supported forms:
///   org.stawi.chat://room/{roomId}   (custom scheme; host == 'room')
///   https://{host}/room/{roomId}     (universal/app link)
class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final Ref _ref;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  /// Begins handling deep links. Safe to call once after the router exists.
  Future<void> initialize() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial);
      }
    } catch (e) {
      AppLogger.warning('Failed to read initial deep link', error: e);
    }

    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleUri(uri)),
      onError: (Object e) =>
          AppLogger.warning('Deep link stream error', error: e),
    );
  }

  Future<void> _handleUri(Uri uri) async {
    final roomId = _extractRoomId(uri);
    if (roomId == null || roomId.isEmpty) {
      AppLogger.debug(
        'Deep link did not match a room route',
        data: {'uri': uri.toString()},
      );
      return;
    }

    try {
      final router = _ref.read(routerProvider);
      final room = await _ref.read(roomRepositoryProvider).getRoomById(roomId);
      if (room == null) {
        AppLogger.warning(
          'Deep-link room not found locally; routing to room list',
          data: {'roomId': roomId},
        );
        router.go('/');
        return;
      }
      final displayName = room.name.isNotEmpty ? room.name : 'Chat';
      router.go('/chat/$roomId?name=${Uri.encodeComponent(displayName)}');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to handle deep link',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
    }
  }

  /// Extracts a room id from a supported deep-link URI, or null.
  String? _extractRoomId(Uri uri) {
    final segments = uri.pathSegments;
    // Custom scheme: org.stawi.chat://room/{id} -> host=room, segments=[id]
    if (uri.host == 'room' && segments.isNotEmpty) {
      return segments.first;
    }
    // Universal link: https://host/room/{id} -> segments=[room, id]
    if (segments.length >= 2 && segments[0] == 'room') {
      return segments[1];
    }
    return null;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
