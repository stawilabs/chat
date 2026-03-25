import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_manager.dart';

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
    // Listen to streams
    ref.listen<AsyncValue<MediaStream?>>(
      StreamProvider((ref) => callManager.localStreamStream),
      (previous, next) {
        next.whenData((stream) {
          if (stream != null) {
            _localRenderer.srcObject = stream;
          }
        });
      },
    );

    ref.listen<AsyncValue<MediaStream?>>(
      StreamProvider((ref) => callManager.remoteStreamStream),
      (previous, next) {
        next.whenData((stream) {
          if (stream != null) {
            _remoteRenderer.srcObject = stream;
          }
        });
      },
    );

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
