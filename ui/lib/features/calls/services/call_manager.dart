import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/logging/app_logger.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../messages/domain/room_event.dart';
import '../domain/call_stats.dart';
import 'call_quality_service.dart';
import 'signaling_service.dart';
import 'turn_credentials_service.dart';

final callManagerProvider = FutureProvider<CallManager>((ref) async {
  final signalingService = await ref.watch(signalingServiceProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  final turnService = await ref.watch(turnCredentialsServiceProvider.future);
  return CallManager(signalingService, authRepo, turnService);
});

enum CallState {
  idle,
  calling, // Outgoing call
  incoming, // Incoming call
  connected,
  reconnecting, // Connection lost, attempting to reconnect
  ended,
}

class CallManager {
  CallManager(
    this._signalingService,
    this._authRepository,
    this._turnCredentialsService,
  ) {
    _signalingService.onSignal.listen(_handleSignal);
  }
  final SignalingService _signalingService;
  final AuthRepository _authRepository;
  final TurnCredentialsService _turnCredentialsService;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;
  CallQualityService? _qualityService;

  // Reconnection handling
  static const Duration _reconnectTimeout = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  bool _isReconnecting = false;

  // Audio/video state
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isVideoDisabledByQuality = false;
  String? _callerSenderId;
  String? get callerSenderId => _callerSenderId;

  final _callStateController = StreamController<CallState>.broadcast();
  Stream<CallState> get callStateStream => _callStateController.stream;
  CallState _state = CallState.idle;
  CallState get state => _state;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get localStreamStream => _localStreamController.stream;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;

  final _statsController = StreamController<CallStats>.broadcast();
  Stream<CallStats> get statsStream => _statsController.stream;
  CallStats _currentStats = const CallStats();
  CallStats get currentStats => _currentStats;

  final _warningController = StreamController<String>.broadcast();
  Stream<String> get warningStream => _warningController.stream;

  // Getters for media state
  bool get isMicMuted => _isMicMuted;
  bool get isCameraOff => _isCameraOff || _isVideoDisabledByQuality;
  bool get isVideoDisabledByQuality => _isVideoDisabledByQuality;

  void _setState(CallState newState) {
    _state = newState;
    _callStateController.add(newState);
  }

  /// Start an outgoing call
  Future<void> startCall(String roomId) async {
    if (_state != CallState.idle) return;

    _currentRoomId = roomId;
    _setState(CallState.calling);

    try {
      await _initPeerConnection();
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      await _signalingService.sendOffer(roomId, {
        'sdp': offer.sdp,
        'type': offer.type,
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to start call',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      endCall();
    }
  }

  /// Answer an incoming call
  Future<void> answerCall() async {
    if (_state != CallState.incoming ||
        _peerConnection == null ||
        _currentRoomId == null) {
      return;
    }

    try {
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _signalingService.sendAnswer(_currentRoomId!, {
        'sdp': answer.sdp,
        'type': answer.type,
      });

      _setState(CallState.connected);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to answer call',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': _currentRoomId},
      );
      endCall();
    }
  }

  /// End the current call
  Future<void> endCall() async {
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    if (_currentRoomId != null) {
      await _signalingService.sendHangup(_currentRoomId!);
    }
    _close();
  }

  /// Toggle microphone mute
  void toggleMic() {
    _isMicMuted = !_isMicMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMicMuted;
    });
    AppLogger.debug('Microphone muted: $_isMicMuted');
  }

  /// Toggle camera on/off
  void toggleCamera() {
    if (_isVideoDisabledByQuality) {
      _warningController.add('Video disabled due to poor connection');
      return;
    }

    _isCameraOff = !_isCameraOff;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
    AppLogger.debug('Camera off: $_isCameraOff');
  }

  /// Manually enable/disable video
  void setVideoEnabled(bool enabled) {
    if (!enabled) {
      _isCameraOff = true;
    } else if (!_isVideoDisabledByQuality) {
      _isCameraOff = false;
    }

    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled && !_isVideoDisabledByQuality;
    });
  }

  void _close() {
    _qualityService?.dispose();
    _qualityService = null;
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.dispose();
    _localStream = null;
    _localStreamController.add(null);
    _remoteStream = null;
    _remoteStreamController.add(null);
    _currentRoomId = null;
    _callerSenderId = null;
    _isMicMuted = false;
    _isCameraOff = false;
    _isVideoDisabledByQuality = false;
    _reconnectAttempts = 0;
    _currentStats = const CallStats();
    _setState(CallState.idle);
  }

  Future<void> _initPeerConnection() async {
    // Request permissions
    await [Permission.camera, Permission.microphone].request();

    // Get ICE server configuration with TURN credentials
    final config = await _turnCredentialsService.getIceServers();

    AppLogger.info(
      'Initializing peer connection',
      data: {'iceServerCount': (config['iceServers'] as List).length},
    );

    _peerConnection = await createPeerConnection(config);

    // Get local stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });
    _localStreamController.add(_localStream);

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Handle remote stream
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        _remoteStreamController.add(_remoteStream);
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (_currentRoomId != null) {
        _signalingService.sendCandidate(_currentRoomId!, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (state) {
      AppLogger.debug('Peer connection state: $state');

      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _handleConnected();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _handleDisconnected();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _handleConnectionFailed();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          if (!_isReconnecting) {
            _close();
          }
          break;
        default:
          break;
      }
    };

    // Handle ICE connection state for more granular reconnection
    _peerConnection!.onIceConnectionState = (state) {
      AppLogger.debug('ICE connection state: $state');

      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _attemptIceRestart();
      }
    };

    // Initialize quality monitoring
    _initQualityMonitoring();
  }

  void _initQualityMonitoring() {
    if (_peerConnection == null) return;

    _qualityService = CallQualityService(
      peerConnection: _peerConnection!,
      onStatsUpdate: (stats) {
        _currentStats = stats;
        _statsController.add(stats);
        // Apply adaptive bitrate based on quality
        _applyAdaptiveBitrate();
      },
      onVideoStateChange: (enabled) {
        _isVideoDisabledByQuality = !enabled;
        _localStream?.getVideoTracks().forEach((track) {
          track.enabled = enabled && !_isCameraOff;
        });
      },
      onReconnectNeeded: () {
        if (!_isReconnecting) {
          _attemptReconnect();
        }
      },
      onWarning: _warningController.add,
    );

    _qualityService!.start();
  }

  void _handleConnected() {
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _qualityService?.notifyReconnectCompleted(true);
    _setState(CallState.connected);
    AppLogger.info('Call connected');
  }

  void _handleDisconnected() {
    // Connection temporarily lost, attempt reconnection
    if (_state == CallState.connected) {
      AppLogger.warning('Connection lost, attempting to reconnect');
      _attemptReconnect();
    }
  }

  void _handleConnectionFailed() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _attemptReconnect();
    } else {
      AppLogger.error(
        'Connection failed after $_maxReconnectAttempts attempts',
      );
      _warningController.add('Call ended due to connection failure');
      endCall();
    }
  }

  void _attemptReconnect() {
    if (_isReconnecting) return;

    _reconnectAttempts++;
    _isReconnecting = true;
    _setState(CallState.reconnecting);
    _qualityService?.notifyReconnectStarted();

    AppLogger.info(
      'Reconnection attempt',
      data: {
        'attempt': _reconnectAttempts,
        'maxAttempts': _maxReconnectAttempts,
      },
    );

    _warningController.add('Reconnecting... (attempt $_reconnectAttempts)');

    // Set timeout for reconnection
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectTimeout, () {
      if (_isReconnecting) {
        AppLogger.warning('Reconnection timed out');
        _qualityService?.notifyReconnectCompleted(false);
        if (_reconnectAttempts >= _maxReconnectAttempts) {
          _warningController.add('Call ended due to connection timeout');
          endCall();
        } else {
          _attemptIceRestart();
        }
      }
    });

    _attemptIceRestart();
  }

  Future<void> _attemptIceRestart() async {
    if (_peerConnection == null || _currentRoomId == null) return;

    try {
      AppLogger.debug('Attempting ICE restart');

      // Create a new offer with ICE restart flag
      final offer = await _peerConnection!.createOffer({'iceRestart': true});

      await _peerConnection!.setLocalDescription(offer);

      await _signalingService.sendOffer(_currentRoomId!, {
        'sdp': offer.sdp,
        'type': offer.type,
        'iceRestart': true,
      });
    } catch (e, stackTrace) {
      AppLogger.error('ICE restart failed', error: e, stackTrace: stackTrace);
      _qualityService?.notifyReconnectCompleted(false);
    }
  }

  /// Apply adaptive bitrate based on quality
  Future<void> _applyAdaptiveBitrate() async {
    if (_peerConnection == null || _qualityService == null) return;

    final recommendedBitrate = _qualityService!.getRecommendedVideoBitrate();
    final recommendedFrameRate = _qualityService!.getRecommendedFrameRate();

    try {
      final senders = await _peerConnection!.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          final params = sender.parameters;
          if (params.encodings != null && params.encodings!.isNotEmpty) {
            params.encodings![0].maxBitrate = recommendedBitrate;
            params.encodings![0].maxFramerate = recommendedFrameRate;
            await sender.setParameters(params);

            AppLogger.debug(
              'Applied adaptive bitrate',
              data: {
                'bitrate': recommendedBitrate,
                'frameRate': recommendedFrameRate,
              },
            );
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to apply adaptive bitrate',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleSignal(RoomEvent event) async {
    // Ignore own signals
    final currentProfileId = await _authRepository.getCurrentProfileId();
    if (currentProfileId != null && event.senderId == currentProfileId) return;

    switch (event.type) {
      case RoomEventType.callOffer:
        await _handleOffer(event);
        break;
      case RoomEventType.callAnswer:
        await _handleAnswer(event);
        break;
      case RoomEventType.callIce:
        await _handleCandidate(event);
        break;
      case RoomEventType.callEnd:
        _close();
        break;
      default:
        break;
    }
  }

  Future<void> _handleOffer(RoomEvent event) async {
    final isIceRestart = event.content['iceRestart'] == true;

    // Handle ICE restart during an active call
    if (isIceRestart && _state == CallState.reconnecting) {
      AppLogger.debug('Received ICE restart offer');
      final sdp = event.content['sdp'];
      final type = event.content['type'];
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, type),
      );

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _signalingService.sendAnswer(_currentRoomId!, {
        'sdp': answer.sdp,
        'type': answer.type,
        'iceRestart': true,
      });
      return;
    }

    if (_state != CallState.idle) {
      // Busy - could send busy signal here
      return;
    }

    _currentRoomId = event.roomId;
    _callerSenderId = event.senderId;
    _setState(CallState.incoming);

    await _initPeerConnection();

    final sdp = event.content['sdp'];
    final type = event.content['type'];
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
  }

  Future<void> _handleAnswer(RoomEvent event) async {
    if (_state != CallState.calling && _state != CallState.reconnecting) return;

    final sdp = event.content['sdp'];
    final type = event.content['type'];
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );

    // If this was a reconnection answer
    if (_isReconnecting) {
      AppLogger.debug('Received ICE restart answer');
    }
  }

  Future<void> _handleCandidate(RoomEvent event) async {
    if (_peerConnection == null) return;

    final candidate = RTCIceCandidate(
      event.content['candidate'],
      event.content['sdpMid'],
      event.content['sdpMLineIndex'],
    );
    await _peerConnection!.addCandidate(candidate);
  }

  /// Dispose of resources
  void dispose() {
    _reconnectTimer?.cancel();
    _callStateController.close();
    _localStreamController.close();
    _remoteStreamController.close();
    _statsController.close();
    _warningController.close();
    _qualityService?.dispose();
    _close();
  }
}
