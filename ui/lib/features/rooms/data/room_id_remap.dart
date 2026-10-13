import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A locally created room now lives under the id the server assigned.
class RoomIdRemap {
  const RoomIdRemap(this.oldId, this.newId);
  final String oldId;
  final String newId;
}

final _remaps = StreamController<RoomIdRemap>.broadcast();

/// Remaps announced by `RoomRepository.adoptServerRoomId`.
Stream<RoomIdRemap> get roomIdRemaps => _remaps.stream;

void announceRoomIdRemap(String oldId, String newId) =>
    _remaps.add(RoomIdRemap(oldId, newId));

/// Replaces the current route with the new room's chat when [roomId] is remapped.
class RoomIdRemapListener extends StatefulWidget {
  const RoomIdRemapListener({
    required this.roomId,
    required this.roomName,
    required this.child,
    super.key,
  });
  final String roomId;
  final String roomName;
  final Widget child;

  @override
  State<RoomIdRemapListener> createState() => _RoomIdRemapListenerState();
}

class _RoomIdRemapListenerState extends State<RoomIdRemapListener> {
  StreamSubscription<RoomIdRemap>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = roomIdRemaps.listen((r) {
      if (r.oldId != widget.roomId || !mounted) return;
      GoRouter.of(context).pushReplacement(
        '/chat/${r.newId}?name=${Uri.encodeComponent(widget.roomName)}',
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
