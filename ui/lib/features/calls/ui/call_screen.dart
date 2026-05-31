import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_manager.dart';

/// Stable top-level providers for the call media streams. Defining them at file
/// scope (instead of `StreamProvider(...)` inline in build) means ref.listen
/// tracks the SAME provider across rebuilds — the inline form created a new
/// provider every frame (e.g. on each mute/camera toggle), leaking a stream
/// subscription each time.
final _localCallStreamProvider = StreamProvider.autoDispose<MediaStream?>((
  ref,
) async* {
  final manager = await ref.watch(callManagerProvider.future);
  yield* manager.localStreamStream;
});

final _remoteCallStreamProvider = StreamProvider.autoDispose<MediaStream?>((
  ref,
) async* {
  final manager = await ref.watch(callManagerProvider.future);
  yield* manager.remoteStreamStream;
});

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({required this.roomId, required this.roomName, super.key});
  final String roomId;
  final String roomName;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _isMicMuted = false;
  bool _isCameraOff = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    // Release camera/mic and tear down the peer connection if the user leaves
    // the call screen by ANY route (OS back gesture, navigation), not only via
    // the explicit end-call button. Without this the camera/mic stay live and
    // signalling keeps running after the screen is gone. Fire-and-forget since
    // dispose cannot await; endCall() is safe to call when already ended.
    ref.read(callManagerProvider).value?.endCall();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final callManager = await ref.read(callManagerProvider.future);
    callManager.toggleMic();
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  Future<void> _toggleCamera() async {
    final callManager = await ref.read(callManagerProvider.future);
    callManager.toggleCamera();
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
  }

  Future<void> _endCall() async {
    final callManager = await ref.read(callManagerProvider.future);
    await callManager.endCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final callManagerAsync = ref.watch(callManagerProvider);

    // Handle loading/error state for call manager
    return callManagerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
      data: (callManager) => _buildCallScreen(context, ref, callManager),
    );
  }

  Widget _buildCallScreen(
    BuildContext context,
    WidgetRef ref,
    CallManager callManager,
  ) {
    // Listen to the stable top-level stream providers (no per-build provider
    // churn). Bind each media stream to its renderer as it arrives.
    ref.listen<AsyncValue<MediaStream?>>(_localCallStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((stream) {
        if (stream != null) {
          _localRenderer.srcObject = stream;
        }
      });
    });

    ref.listen<AsyncValue<MediaStream?>>(_remoteCallStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((stream) {
        if (stream != null) {
          _remoteRenderer.srcObject = stream;
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video (Full Screen)
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),

          // Local Video (Small Overlay)
          Positioned(
            right: 16,
            top: 48,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  onPressed: _toggleMic,
                  style: IconButton.styleFrom(
                    backgroundColor: _isMicMuted
                        ? Colors.white
                        : Colors.white24,
                    foregroundColor: _isMicMuted ? Colors.black : Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                ),
                IconButton.filled(
                  onPressed: _endCall,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(24),
                  ),
                  icon: const Icon(Icons.call_end),
                ),
                IconButton.filled(
                  onPressed: _toggleCamera,
                  style: IconButton.styleFrom(
                    backgroundColor: _isCameraOff
                        ? Colors.white
                        : Colors.white24,
                    foregroundColor: _isCameraOff ? Colors.black : Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(
                    _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  ),
                ),
              ],
            ),
          ),

          // Room Name
          Positioned(
            top: 48,
            left: 16,
            child: Text(
              widget.roomName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
