import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:antinvestor_api_chat/antinvestor_api_chat.dart' as pb;
import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    as common_types;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/messages/data/message_providers.dart';
import '../../features/messages/data/message_repository.dart';
import '../../features/messages/data/read_receipt_repository.dart';
import '../../features/messages/domain/room_event.dart' as domain;
import '../../features/rooms/data/room_repository.dart';
import '../../features/rooms/data/room_subscription_repository.dart';
import '../../features/rooms/data/room_subscription_service.dart';
import '../../features/rooms/data/room_sync_manager.dart';
import '../../features/rooms/data/room_sync_state.dart';
import '../auth/token_refresh_coordinator.dart';
import '../crypto/e2e_encryption_service.dart';
import '../db/database.dart';
import '../files/files_config_service.dart';
import '../logging/app_logger.dart';
import '../networking/api_config.dart';
import '../networking/client.dart';
import 'pending_job.dart' as domain_job;
import 'pending_job_repository.dart';
import 'sync_health_monitor.dart';

final pendingJobRepositoryProvider = Provider<PendingJobRepository>(
  (ref) => PendingJobRepository(AppDatabase.instance),
);

/// Stream provider for watching failed job count
/// Useful for showing notification badges or banners
final failedJobCountProvider = StreamProvider<int>((ref) {
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  return jobRepo.watchFailedJobCount();
});

/// Provider to get recent failed jobs for display
final recentFailedJobsProvider = FutureProvider<List<domain_job.PendingJob>>((
  ref,
) async {
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  return jobRepo.getRecentFailedJobs();
});

/// Exception thrown when token refresh fails permanently and user must re-authenticate
class TokenRefreshPermanentError implements Exception {
  TokenRefreshPermanentError(this.message);
  final String message;

  @override
  String toString() => 'TokenRefreshPermanentError: $message';
}

/// Exception used to defer a job when subscription ID is not available yet.
class MissingSubscriptionIdException implements Exception {
  MissingSubscriptionIdException(this.roomId);
  final String roomId;

  @override
  String toString() => 'MissingSubscriptionIdException(roomId: $roomId)';
}

/// Async provider for SyncEngine since it depends on async client providers
final syncEngineProvider = FutureProvider<SyncEngine>((ref) async {
  final gatewayClient = await ref.watch(gatewayServiceClientProvider.future);
  final chatClient = await ref.watch(chatServiceClientProvider.future);
  final authRepo = ref.watch(authRepositoryProvider);
  final encryptionService = ref.watch(e2eEncryptionServiceProvider);
  final coordinator = ref.watch(tokenRefreshCoordinatorProvider);
  final roomSyncManager = ref.watch(roomSyncManagerProvider);
  final healthMonitor = ref.watch(syncHealthMonitorProvider);

  // Initialize encryption service
  await encryptionService.initialize();

  // Start health monitoring
  healthMonitor.start();

  final engine = SyncEngine(
    gatewayClient,
    chatClient,
    ref.watch(messageRepositoryProvider),
    ref.watch(pendingJobRepositoryProvider),
    authRepo,
    ref.watch(roomSubscriptionRepositoryProvider),
    ref.watch(roomSubscriptionServiceProvider),
    encryptionService,
    ref.watch(readReceiptRepositoryProvider),
    roomSyncManager,
    RoomRepository(AppDatabase.instance),
    healthMonitor: healthMonitor,
    onTokenRefresh: () async {
      // Delegate ALL token refresh logic to the coordinator
      // This ensures consistent behavior across TokenManager, SyncEngine,
      // and TokenRefreshService
      AppLogger.debug(
        'SyncEngine: Token refresh requested, delegating to coordinator',
      );

      final result = await coordinator.refresh(source: 'SyncEngine');

      if (!result.success) {
        if (result.result == common_types.TokenRefreshResult.permanentError) {
          throw TokenRefreshPermanentError(
            result.error ?? 'User must re-authenticate',
          );
        }
        // Transient error - return null to signal retry later
        AppLogger.warning(
          'SyncEngine: Token refresh failed (transient)',
          data: {'error': result.error},
        );
        return null;
      }

      AppLogger.debug('SyncEngine: Token refresh successful via coordinator');
      return result.accessToken;
    },
  );

  // Register lifecycle observer
  engine._registerLifecycleObserver();

  // Cleanup on dispose
  ref.onDispose(engine.dispose);

  return engine;
});

/// Connection state for the real-time sync engine
///
/// Example:
/// ```dart
/// final state = ref.watch(connectionStateProvider);
/// if (state == SyncConnectionState.connected) {
///   print('Connected to server');
/// }
/// ```
enum SyncConnectionState { disconnected, connecting, connected }

/// Stream provider for monitoring sync connection state
final connectionStateProvider = StreamProvider<SyncConnectionState>((
  ref,
) async* {
  final syncEngine = await ref.watch(syncEngineProvider.future);
  yield* syncEngine.connectionState;
});

/// Callback type for token refresh operations
typedef TokenRefreshCallback = Future<String?> Function();

/// Real-time synchronization engine for bidirectional message streaming
///
/// Manages the WebSocket-like connection to the gateway service for:
/// - Receiving incoming messages and events
/// - Uploading pending messages from the offline queue
/// - Handling typing indicators and read receipts
/// - Managing connection state with automatic reconnection
/// - Pausing on app background and resuming on foreground
///
/// Example:
/// ```dart
/// final syncEngine = await ref.watch(syncEngineProvider.future);
/// syncEngine.start();
///
/// // Monitor connection state
/// syncEngine.connectionState.listen((state) {
///   print('Connection: $state');
/// });
///
/// // Send a message
/// await syncEngine.sendSignal(event);
/// ```
class SyncEngine with WidgetsBindingObserver {
  SyncEngine(
    this._gatewayClient,
    this._chatClient,
    this._messageRepo,
    this._jobRepo,
    this._authRepository,
    this._roomSubscriptionRepository,
    this._subscriptionService,
    this._encryptionService,
    this._readReceiptRepo,
    this._roomSyncManager,
    this._roomRepository, {
    TokenRefreshCallback? onTokenRefresh,
    SyncHealthMonitor? healthMonitor,
  }) : _onTokenRefresh = onTokenRefresh,
       _healthMonitor = healthMonitor;

  final pb.GatewayServiceClient _gatewayClient;
  final pb.ChatServiceClient _chatClient;
  final MessageRepository _messageRepo;
  final PendingJobRepository _jobRepo;
  final AuthRepository _authRepository;
  final RoomSubscriptionRepository _roomSubscriptionRepository;
  final RoomSubscriptionService _subscriptionService;
  final E2EEncryptionService _encryptionService;
  final ReadReceiptRepository _readReceiptRepo;
  final RoomSyncManager _roomSyncManager;
  final RoomRepository _roomRepository;
  final TokenRefreshCallback? _onTokenRefresh;
  final SyncHealthMonitor? _healthMonitor;

  StreamSubscription? _connectSubscription;
  StreamSubscription<List<domain_job.PendingJob>>? _jobWatchSubscription;
  Completer<void>? _uploadLock;
  bool _isConnected = false;
  bool _shouldStop = false; // Flag to stop the download loop
  bool _isPostConnectionSyncing = false;
  bool _isPaused = false; // Flag to track if paused due to app lifecycle
  int _reconnectAttempts = 0;
  int _authErrorCount = 0; // Track consecutive auth errors

  // Lock to prevent multiple concurrent connection attempts
  Completer<void>? _connectionLock;

  // Random for jitter in reconnection backoff
  final _random = Random();

  // Controller for bidirectional stream requests
  // This keeps the stream open so we can send multiple messages (hello, typing, receipts, etc.)
  StreamController<pb.StreamRequest>? _requestController;

  // Completer for graceful stop/start coordination
  Completer<void>? _stopCompleter;
  bool _isLifecycleObserverRegistered = false;

  // Configuration
  static const _maxAuthErrors = 3; // Max auth errors before giving up
  static const _streamReadTimeout = Duration(seconds: 60); // Read timeout

  final _typingEventsController = StreamController<pb.TypingEvent>.broadcast();
  Stream<pb.TypingEvent> get typingEvents => _typingEventsController.stream;

  final _signalingEventsController =
      StreamController<domain.RoomEvent>.broadcast();
  Stream<domain.RoomEvent> get signalingEvents =>
      _signalingEventsController.stream;

  final _connectionStateController =
      StreamController<SyncConnectionState>.broadcast();
  Stream<SyncConnectionState> get connectionState =>
      _connectionStateController.stream;

  /// Get current connection state synchronously
  SyncConnectionState get currentConnectionState => _isConnected
      ? SyncConnectionState.connected
      : SyncConnectionState.disconnected;

  // Exponential backoff configuration
  static const _initialBackoffMs = 1000; // 1 second
  static const _maxBackoffMs = 30000; // 30 seconds

  // Room member sync cache to avoid redundant syncs
  final Map<String, DateTime> _roomMemberSyncCache = {};
  static const _roomMemberSyncCacheDuration = Duration(minutes: 5);

  /// Register the lifecycle observer
  void _registerLifecycleObserver() {
    if (!_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isLifecycleObserverRegistered = true;
      AppLogger.debug('SyncEngine: Lifecycle observer registered');
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppBackgrounded();
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being destroyed or hidden
        break;
    }
  }

  /// Called when app comes to foreground
  void _onAppResumed() {
    if (_isPaused) {
      AppLogger.info('SyncEngine: App resumed, restarting sync');
      _isPaused = false;
      start();
    }
  }

  /// Called when app goes to background
  void _onAppBackgrounded() {
    // Stop sync if connected OR if currently attempting to connect
    // This prevents wasting resources on connection attempts while backgrounded
    if (!_isPaused && (_isConnected || _connectionLock != null)) {
      AppLogger.info('SyncEngine: App backgrounded, pausing sync');
      _isPaused = true;
      stop();
    }
  }

  void start() {
    // Don't start if paused due to app lifecycle
    if (_isPaused) {
      AppLogger.debug('SyncEngine: Ignoring start() while paused');
      return;
    }

    _shouldStop = false;
    _startDownloadLoop();
    _startUploadLoop();
  }

  /// Stop the sync engine and wait for it to fully stop
  Future<void> stopAsync() async {
    if (_stopCompleter != null) {
      // Already stopping, wait for completion
      await _stopCompleter!.future;
      return;
    }

    _stopCompleter = Completer<void>();
    _shouldStop = true;

    _connectSubscription?.cancel();
    _connectSubscription = null;
    _jobWatchSubscription?.cancel();
    _jobWatchSubscription = null;
    _isConnected = false;

    // Wait for any in-flight upload to complete instead of using a magic delay
    final currentUpload = _uploadLock;
    if (currentUpload != null && !currentUpload.isCompleted) {
      await currentUpload.future;
    }

    _stopCompleter?.complete();
    _stopCompleter = null;
  }

  void stop() {
    _shouldStop = true; // Signal download loop to stop
    _connectSubscription?.cancel();
    _connectSubscription = null;
    _jobWatchSubscription?.cancel();
    _jobWatchSubscription = null;
    _isConnected = false;

    // Close the request controller to end the bidirectional stream gracefully
    _requestController?.close();
    _requestController = null;

    // Release connection lock if held
    if (_connectionLock != null && !_connectionLock!.isCompleted) {
      _connectionLock!.complete();
    }
    _connectionLock = null;

    // Note: Don't close broadcast stream controllers here as they may be reused
    // They will be closed when the engine is disposed
  }

  /// Permanently dispose of the sync engine (call only when no longer needed)
  void dispose() {
    // Unregister lifecycle observer
    if (_isLifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isLifecycleObserverRegistered = false;
    }

    stop();
    _typingEventsController.close();
    _signalingEventsController.close();
    _connectionStateController.close();
  }

  /// Fetch historical messages for a room
  /// Returns number of events fetched (0 if none available)
  Future<int> getHistory(
    String roomId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      // Don't pass manual headers - let the interceptor handle authorization
      final pageCursor = common_types.PageCursor(limit: limit, page: cursor);

      final request = pb.GetHistoryRequest(
        roomId: roomId,
        cursor: pageCursor,
        forward: false, // Get newer->older by default
      );

      final response = await _chatClient.getHistory(request);

      // Process each event in the response
      for (final roomEvent in response.events) {
        await _processPbRoomEvent(roomEvent);
      }

      return response.events.length;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get history',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId, 'limit': limit},
      );
      return 0;
    }
  }

  Future<void> sendSignal(domain.RoomEvent event) async {
    // Insert into DB first (optional for signals, but good for history)
    await _messageRepo.insertMessage(event);

    // Create pending job
    await _jobRepo.addJob(domain_job.JobType.sendMessage, {
      'roomId': event.roomId,
      'type': event.type.toString(),
      'content': event.content,
      'localId': event.localId,
    });

    // Trigger immediate upload if connected
    if (_isConnected) {
      _startUploadLoop();
    }
  }

  Future<void> _startDownloadLoop() async {
    // Prevent multiple concurrent connection attempts
    if (_connectionLock != null) {
      AppLogger.debug('Connection attempt already in progress, skipping');
      return;
    }
    if (_isConnected || _shouldStop) return;

    // Acquire connection lock
    _connectionLock = Completer<void>();

    _connectionStateController.add(SyncConnectionState.connecting);

    // Run connection loop in a way that doesn't block the main thread
    while (!_shouldStop) {
      // Check circuit breaker before attempting connection
      final healthMonitor = _healthMonitor;
      if (healthMonitor != null && !healthMonitor.isConnectionAllowed) {
        AppLogger.warning(
          'Circuit breaker open, delaying connection attempt',
          data: {'circuitState': healthMonitor.circuitState.name},
        );
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      try {
        // Create a StreamController for bidirectional communication
        // This stays open so we can send multiple requests (hello, typing, receipts, etc.)
        _requestController = StreamController<pb.StreamRequest>();

        // Add client capabilities for server-side feature detection
        final hello = pb.StreamHello(
          capabilities: {
            'version': '1.0.0',
            'platform': 'flutter',
            'e2ee': 'vodozemac-0.4',
            'calls': 'webrtc',
            'offline': 'true',
          },
          clientTime: common_types.Timestamp.fromDateTime(DateTime.now()),
        );
        final helloRequest = pb.StreamRequest(hello: hello);

        // Send hello as the first message
        _requestController!.add(helloRequest);

        // Don't pass manual headers - let the interceptor handle authorization
        // This ensures token refresh works correctly on 401
        // Use the controller's stream which stays open for bidirectional communication
        final stream = _gatewayClient.stream(_requestController!.stream);
        _isConnected = true;
        _reconnectAttempts = 0;
        _authErrorCount = 0; // Reset auth error count on successful connection
        _connectionStateController.add(SyncConnectionState.connected);

        // Record successful connection with health monitor
        _healthMonitor?.recordConnectionSuccess();

        // Proactively sync rooms that need it (provisional subscriptions, etc.)
        unawaited(_performPostConnectionSync());

        // Process stream events with timeout to detect stalled connections
        await _processStreamWithTimeout(stream);
      } catch (e, stackTrace) {
        final errorStr = e.toString().toLowerCase();
        final isAuthError = _isAuthenticationError(errorStr);
        final isNormalDisconnect = _isNormalDisconnect(errorStr);
        final isTimeout = e is TimeoutException;

        // Record failure with health monitor (not for normal disconnects)
        if (!isNormalDisconnect) {
          _healthMonitor?.recordConnectionFailure(
            isAuthError ? 'auth_error' : (isTimeout ? 'timeout' : errorStr),
          );
        }

        // Log appropriately based on error type
        if (isNormalDisconnect) {
          // Normal server disconnection - just log as debug, will auto-reconnect
          AppLogger.debug('Sync connection closed by server, will reconnect');
        } else if (isTimeout) {
          AppLogger.warning(
            'Sync connection timed out (no data for ${_streamReadTimeout.inSeconds}s), reconnecting',
          );
        } else {
          AppLogger.error(
            'Sync connection error',
            error: e,
            stackTrace: stackTrace,
            data: {
              'reconnectAttempts': _reconnectAttempts,
              'isAuthError': isAuthError,
              'authErrorCount': _authErrorCount,
            },
          );
        }

        // If it's an auth error, try to refresh token before reconnecting
        if (isAuthError) {
          _authErrorCount++;

          if (_authErrorCount > _maxAuthErrors) {
            AppLogger.error(
              'Max auth errors reached, stopping sync until re-login',
            );
            _connectionStateController.add(SyncConnectionState.disconnected);
            _connectionLock?.complete();
            _connectionLock = null;
            return; // Exit the loop - user needs to re-login
          }

          final refreshCallback = _onTokenRefresh;
          if (refreshCallback != null) {
            AppLogger.info(
              'Authentication error detected, attempting token refresh',
              data: {'attempt': _authErrorCount, 'maxAttempts': _maxAuthErrors},
            );

            try {
              final newToken = await refreshCallback();
              if (newToken != null) {
                AppLogger.info(
                  'Token refreshed after auth error, will retry connection',
                );
                _reconnectAttempts = 0;
                _authErrorCount = 0; // Reset on successful refresh
                // Small delay to prevent tight loop if refresh succeeds but connection still fails
                await Future.delayed(const Duration(milliseconds: 500));
              } else {
                // Refresh returned null - transient error, wait before retrying
                AppLogger.debug(
                  'Token refresh returned null (transient), waiting before retry',
                );
                await Future.delayed(const Duration(seconds: 2));
              }
            } on TokenRefreshPermanentError catch (e) {
              // Permanent token failure - user must re-authenticate
              // Stop the sync engine entirely
              AppLogger.error(
                'Permanent token refresh failure, stopping sync engine',
                data: {'error': e.message},
              );
              _connectionStateController.add(SyncConnectionState.disconnected);
              _connectionLock?.complete();
              _connectionLock = null;
              return; // Exit the loop - user needs to re-login
            } catch (refreshError) {
              AppLogger.warning(
                'Token refresh failed with transient error',
                data: {'error': refreshError.toString()},
              );
              // Transient error - continue with backoff and retry
            }

            // Continue with reconnection attempt
            continue;
          }
        } else {
          // Not an auth error, reset auth error count after successful backoff
          _authErrorCount = 0;
        }
      } finally {
        _isConnected = false;
        _connectionStateController.add(SyncConnectionState.disconnected);

        // Close the request controller to clean up resources
        await _requestController?.close();
        _requestController = null;
      }

      // Check if we should stop before waiting
      if (_shouldStop) {
        AppLogger.debug('Sync engine stopped, exiting download loop');
        break;
      }

      // Exponential backoff
      final delay = _getBackoffDelay();
      AppLogger.info(
        'Reconnecting to sync',
        data: {
          'delaySeconds': delay.inSeconds,
          'attempt': _reconnectAttempts + 1,
        },
      );
      await Future.delayed(delay);

      // Check again after delay in case stop was called during wait
      if (_shouldStop) {
        AppLogger.debug('Sync engine stopped during backoff, exiting');
        break;
      }

      _reconnectAttempts++;
    }

    // Release connection lock when loop exits
    _connectionLock?.complete();
    _connectionLock = null;
  }

  /// Process stream events with a timeout to detect stalled connections
  ///
  /// Uses Stream.timeout() for proper timeout detection - this triggers
  /// even when no messages arrive (unlike manual checks which only run
  /// when messages are received).
  Future<void> _processStreamWithTimeout(
    Stream<pb.StreamResponse> stream,
  ) async {
    // Use Stream.timeout() for proper timeout detection
    // This will throw TimeoutException if no data arrives within the timeout
    final timedStream = stream.timeout(
      _streamReadTimeout,
      onTimeout: (sink) {
        sink.addError(
          TimeoutException(
            'No data received for ${_streamReadTimeout.inSeconds} seconds',
          ),
        );
        sink.close();
      },
    );

    // Process messages sequentially to maintain order and prevent queue overflow
    // Using await for ensures backpressure - we won't accept new messages
    // until the current one is processed
    await for (final response in timedStream) {
      // Check if we should stop
      if (_shouldStop) {
        AppLogger.debug('Stop requested during stream processing');
        break;
      }

      // Reset auth error count on successful data receipt
      _authErrorCount = 0;

      // Process synchronously to maintain message order
      // This also provides natural backpressure
      try {
        await _handleConnectResponse(response);
      } catch (e, stackTrace) {
        AppLogger.error(
          'Error handling stream response',
          error: e,
          stackTrace: stackTrace,
        );
        // Continue processing other messages even if one fails
      }
    }
  }

  /// Check if this is a normal/expected disconnection (not a real error)
  bool _isNormalDisconnect(String errorStr) =>
      errorStr.contains('connection closed') ||
      errorStr.contains('stream was reset') ||
      errorStr.contains('connection reset') ||
      errorStr.contains('eof') ||
      errorStr.contains('cancelled');

  /// Check if an error is an authentication/authorization error
  bool _isAuthenticationError(String errorStr) {
    // Exclude database errors - these are NOT auth errors
    if (errorStr.contains('sqliteexception') ||
        errorStr.contains('foreign key') ||
        errorStr.contains('constraint failed') ||
        errorStr.contains('database') ||
        errorStr.contains('sqlite')) {
      return false;
    }

    return errorStr.contains('unauthenticated') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('invalid authorization') ||
        errorStr.contains('invalid token') ||
        errorStr.contains('token expired') ||
        errorStr.contains('jwt expired') ||
        errorStr.contains('401') ||
        errorStr.contains('403');
  }

  Duration _getBackoffDelay() {
    var delay = _initialBackoffMs * (1 << _reconnectAttempts);
    if (delay > _maxBackoffMs) {
      delay = _maxBackoffMs;
    }
    // Add jitter (0-25% of delay) to prevent thundering herd
    final jitter = (_random.nextDouble() * 0.25 * delay).toInt();
    return Duration(milliseconds: delay + jitter);
  }

  /// Send a request through the bidirectional stream
  ///
  /// Returns true if the request was sent, false if not connected
  bool _sendRequest(pb.StreamRequest request) {
    final controller = _requestController;
    if (controller == null || controller.isClosed) {
      AppLogger.warning(
        'Cannot send request: stream not connected',
        data: {'hasController': controller != null},
      );
      return false;
    }

    try {
      controller.add(request);
      return true;
    } catch (e) {
      AppLogger.error('Failed to send request through stream', error: e);
      return false;
    }
  }

  Future<void> _handleConnectResponse(pb.StreamResponse response) async {
    final startTime = DateTime.now();

    try {
      // Handle different event types
      if (response.hasMessage()) {
        await _processPbRoomEvent(response.message);

        // Track message processing success with latency
        final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
        _healthMonitor?.recordMessageSuccess(latencyMs: latencyMs);
      } else if (response.hasTypingEvent()) {
        _typingEventsController.add(response.typingEvent);
      } else if (response.hasPresenceEvent()) {
        // Note: Presence events will be handled when needed
      } else if (response.hasReceiptEvent()) {
        await _processReceiptEvent(response.receiptEvent);
      } else if (response.hasReadEvent()) {
        // Note: Read marker events will be handled when needed
      }
    } catch (e) {
      // Track message processing failure
      if (response.hasMessage()) {
        _healthMonitor?.recordMessageFailure();
      }
      rethrow;
    }
  }

  Future<void> _processPbRoomEvent(pb.RoomEvent event) async {
    // Skip events with missing required fields
    if (event.id.isEmpty) {
      AppLogger.warning('Skipping event with empty id');
      return;
    }

    // Handle system events that don't have roomId
    if (event.roomId.isEmpty) {
      AppLogger.debug(
        'Processing system event with no room',
        data: {'eventId': event.id, 'type': event.type.toString()},
      );

      // Process system events (like token refresh, auth status, etc.)
      await _processSystemEvent(event);
      return;
    }

    // Note: Deduplication is handled by the database's unique constraint on event ID
    // XIDs provide natural ordering, so we rely on the DB for both ordering and uniqueness

    // Extract content from typed payload fields
    var content = <String, dynamic>{};
    var isRoomKeyEvent = false;
    if (event.hasPayload()) {
      final payload = event.payload;
      if (payload.hasText()) {
        final textBody = payload.text.body;
        // Check if this is a roomKey event (session key sharing for E2EE)
        if (textBody.startsWith('{"type":"roomKey"') ||
            textBody.contains('"algorithm":"megolm')) {
          try {
            final keyData = jsonDecode(textBody) as Map<String, dynamic>;
            if (keyData['type'] == 'roomKey' ||
                keyData['algorithm'] == 'megolm.v1') {
              // Process the session key
              await _processRoomKeyEvent(keyData, event.roomId);
              isRoomKeyEvent = true;
              content = {
                'type': 'roomKey',
                'processed': true,
                'sessionId': keyData['sessionId'],
              };
            }
          } catch (e) {
            // Not a valid JSON roomKey, treat as regular text
            AppLogger.debug('Text is not a roomKey event: $e');
          }
        }
        if (!isRoomKeyEvent) {
          content = {'text': textBody};
        }
      } else if (payload.hasAttachment()) {
        final contentUrl = FilesConfigService.buildContentUrlFrom(
          ApiConfig.filesBaseUrl,
          payload.attachment.attachmentId,
        );
        content = {
          'attachmentId': payload.attachment.attachmentId,
          'fileName': payload.attachment.filename,
          'mimeType': payload.attachment.mimeType,
          'size': payload.attachment.sizeBytes.toInt(),
          'mediaId': payload.attachment.attachmentId,
          'contentUri': contentUrl,
          'url': contentUrl,
        };
      } else if (payload.hasEncrypted()) {
        // Decrypt the message using E2EE service
        try {
          final encrypted = payload.encrypted;
          // Convert ciphertext bytes to base64 string for decryption
          final ciphertext = base64Encode(encrypted.ciphertext);
          final sessionId = encrypted.sessionId;
          // Use sender's subscription ID as sender key for session lookup
          final senderKey = event.hasSubscriptionId()
              ? event.subscriptionId
              : '';

          // senderKey is required for E2EE decryption
          if (senderKey.isEmpty) {
            AppLogger.warning(
              'Encrypted message missing sender info',
              data: {'roomId': event.roomId, 'sessionId': sessionId},
            );
            content = {
              'text': '[Unable to decrypt - unknown sender]',
              'encrypted': true,
              'decrypted': false,
              'error': 'missing_sender_key',
            };
          } else if (_encryptionService.hasInboundSession(
            event.roomId,
            senderKey,
          )) {
            // Try to get the inbound session for this room/sender
            final plaintext = await _encryptionService.decryptGroup(
              event.roomId,
              ciphertext,
              senderKey: senderKey,
            );
            // If plaintext is JSON, treat as structured content (e.g. media)
            try {
              final decoded = jsonDecode(plaintext);
              if (decoded is Map<String, dynamic>) {
                content = {...decoded, 'encrypted': true, 'decrypted': true};
              } else {
                content = {
                  'text': plaintext,
                  'encrypted': true, // Mark as was encrypted for UI indicator
                  'decrypted': true,
                };
              }
            } catch (_) {
              content = {
                'text': plaintext,
                'encrypted': true, // Mark as was encrypted for UI indicator
                'decrypted': true,
              };
            }
            AppLogger.debug(
              'Message decrypted',
              data: {'roomId': event.roomId, 'sessionId': sessionId},
            );
          } else {
            // Need to request session key from sender
            AppLogger.warning(
              'Missing session key for decryption',
              data: {
                'roomId': event.roomId,
                'sessionId': sessionId,
                'senderKey': senderKey,
              },
            );
            content = {
              'text': '[Unable to decrypt - missing session key]',
              'encrypted': true,
              'decrypted': false,
              'sessionId': sessionId,
              'senderKey': senderKey,
            };
          }
        } catch (e, stackTrace) {
          AppLogger.error(
            'Decryption failed',
            error: e,
            stackTrace: stackTrace,
          );
          content = {
            'text': '[Unable to decrypt message]',
            'encrypted': true,
            'decrypted': false,
            'error': e.toString(),
          };
        }
      } else if (payload.hasCall()) {
        // Extract call data
        content = {
          'callId': payload.call.callId,
          'callType': payload.call.action.toString(),
        };
      } else if (payload.hasRoomChange()) {
        // Handle room change events (typed replacement for moderation)
        await _processRoomChangeEvent(
          event.roomId,
          payload.roomChange,
          event.hasSubscriptionId() ? event.subscriptionId : '',
        );

        // Extract room change content for display as system message
        final roomChange = payload.roomChange;
        content = {
          'text': roomChange.body, // For text rendering compatibility
          'body': roomChange.body,
          'action': roomChange.action.name,
          'actorSubscriptionId': roomChange.actorSubscriptionId,
          'targetSubscriptionIds': roomChange.targetSubscriptionIds.toList(),
          'isRoomChange': true,
          if (roomChange.hasDetails())
            'details': _structToMap(roomChange.details),
        };
      } else if (payload.hasModeration()) {
        // Handle legacy moderation events (backward compatibility)
        await _processModerationEvent(
          event.roomId,
          payload.moderation,
          event.hasSubscriptionId() ? event.subscriptionId : '',
        );

        // Extract moderation content for display as system message
        final moderation = payload.moderation;
        content = {
          'text': moderation.body, // For text rendering compatibility
          'body': moderation.body,
          'actorSubscriptionId': moderation.actorSubscriptionId,
          'targetSubscriptionIds': moderation.targetSubscriptionIds.toList(),
          'isModeration': true,
        };
      }
    }

    // Extract sender subscription ID directly from server event
    // senderId stores the subscription ID, not profile ID
    // Profile ID can be looked up via RoomSubscriptions when needed for display
    final subscriptionId = event.hasSubscriptionId()
        ? event.subscriptionId
        : '';

    // Optionally get contact ID for the sender (for additional context)
    String? senderContactId;
    if (subscriptionId.isNotEmpty) {
      final member = await _roomSubscriptionRepository.getSubscription(
        subscriptionId,
      );
      senderContactId = member?.contactId;
    }

    // Determine domain event type - override for room change/moderation events
    final domainType =
        (content['isRoomChange'] == true || content['isModeration'] == true)
        ? domain.RoomEventType.roomChange
        : _mapProtoEventType(event.type);

    // Check if this event already exists locally (e.g. own message echo from server)
    // If it does and its status is already >= sent, only advance status - never regress.
    final existingEvent = await _messageRepo.getEventById(event.id);
    if (existingEvent != null) {
      // Event already exists by server ID - ack was processed first (normal case)
      if (existingEvent.status.index >= domain.EventStatus.sent.index) {
        // Already sent/delivered/read - only advance status, never regress
        if (existingEvent.status == domain.EventStatus.sent) {
          // Advance from sent → delivered (server confirmed delivery to stream)
          await _messageRepo.updateMessageStatus(
            event.id,
            domain.EventStatus.delivered,
          );
        }
        // Update serverTs if we didn't have it
        if (existingEvent.serverTs == null && event.hasSentAt()) {
          final serverTs =
              event.sentAt.seconds.toInt() * 1000 +
              event.sentAt.nanos ~/ 1000000;
          await _messageRepo.updateServerTimestamp(event.id, serverTs);
        }
        return;
      }
    } else {
      // No row with server ID yet - check if there's a pending row with this
      // event's ID stored as localId (echo arrived before ack response)
      final pendingByLocalId = await _messageRepo.getEventByLocalId(event.id);
      if (pendingByLocalId != null &&
          pendingByLocalId.status == domain.EventStatus.pending) {
        // Race condition: echo arrived before ack. Update the pending row
        // to use the server ID and advance to delivered status.
        final serverTs = event.hasSentAt()
            ? event.sentAt.seconds.toInt() * 1000 +
                  event.sentAt.nanos ~/ 1000000
            : null;
        await _messageRepo.updateMessageIdFromEcho(
          pendingByLocalId.id,
          serverId: event.id,
          senderId: subscriptionId.isNotEmpty
              ? subscriptionId
              : pendingByLocalId.senderId,
          serverTs: serverTs,
        );
        return;
      }
    }

    final roomEvent = domain.RoomEvent(
      id: event.id,
      roomId: event.roomId,
      senderId: subscriptionId, // Store subscription ID directly
      senderContactId: senderContactId,
      type: domainType,
      content: content,
      parentId: event.hasParentId() ? event.parentId : null,
      status: domain.EventStatus.delivered,
      createdAt: event.hasSentAt()
          ? event.sentAt.seconds.toInt() * 1000 + event.sentAt.nanos ~/ 1000000
          : DateTime.now().millisecondsSinceEpoch,
      serverTs: event.hasSentAt()
          ? event.sentAt.seconds.toInt() * 1000 + event.sentAt.nanos ~/ 1000000
          : null,
    );

    await _messageRepo.insertMessage(roomEvent);

    // Note: Server handles message forwarding to off-platform members
    // No client-side forwarding needed - server determines routing based on
    // member platform status, credit balance, and handles billing

    // Emit signaling events for real-time handling
    if (_isCallEvent(roomEvent.type)) {
      _signalingEventsController.add(roomEvent);
    }
  }

  bool _isCallEvent(domain.RoomEventType type) =>
      type == domain.RoomEventType.callOffer ||
      type == domain.RoomEventType.callAnswer ||
      type == domain.RoomEventType.callIce ||
      type == domain.RoomEventType.callEnd;

  /// Process system events that don't have roomId (like auth events, token refresh, etc.)
  Future<void> _processSystemEvent(pb.RoomEvent event) async {
    try {
      AppLogger.debug(
        'Processing system event',
        data: {
          'eventId': event.id,
          'type': event.type.toString(),
          'hasPayload': event.hasPayload(),
        },
      );

      // Handle different types of system events
      switch (event.type) {
        case pb.RoomEventType.ROOM_EVENT_TYPE_EVENT:
          // Generic system event - extract and handle payload
          if (event.hasPayload()) {
            final payload = event.payload;
            AppLogger.debug(
              'System event payload',
              data: {
                'hasText': payload.hasText(),
                'hasAttachment': payload.hasAttachment(),
                'hasCall': payload.hasCall(),
              },
            );
          }
          break;

        default:
          AppLogger.debug(
            'Unhandled system event type',
            data: {'type': event.type.toString()},
          );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error processing system event',
        error: e,
        stackTrace: stackTrace,
        data: {'eventId': event.id, 'type': event.type.toString()},
      );
    }
  }

  /// Process moderation events (room created, members added/removed)
  ///
  /// These events contain subscription IDs for room members.
  /// When we receive a moderation event:
  /// 1. Store all subscription IDs in the RoomSubscriptions table
  /// 2. Notify RoomSyncManager to check if we now have current user's subscription
  /// 3. Handle member removals by cleaning up local state
  Future<void> _processModerationEvent(
    String roomId,
    pb.ModerationContent moderation,
    String actorSubscriptionId,
  ) async {
    try {
      final targetSubscriptionIds = moderation.targetSubscriptionIds.toList();
      final body = moderation.body.toLowerCase();

      AppLogger.info(
        'Processing moderation event',
        data: {
          'roomId': roomId,
          'body': moderation.body,
          'actorSubscriptionId': actorSubscriptionId.isNotEmpty
              ? actorSubscriptionId.substring(0, 8)
              : 'unknown',
          'targetCount': targetSubscriptionIds.length,
        },
      );

      // Determine action type from body text
      final isRoomCreated =
          body.contains('created') || body.contains('room created');
      final isMemberAdded = body.contains('added') || body.contains('joined');
      final isMemberRemoved =
          body.contains('removed') ||
          body.contains('left') ||
          body.contains('kicked');

      if (isRoomCreated || isMemberAdded) {
        // Store all subscription IDs from the event
        for (final subscriptionId in targetSubscriptionIds) {
          final created = await _roomSubscriptionRepository.createSubscription(
            id: subscriptionId,
            roomId: roomId,
            // Note: profileId/contactId not available in moderation event
            // Will be populated when profile info is fetched or from API sync
          );

          if (created) {
            AppLogger.debug(
              'Created subscription from moderation event',
              data: {
                'subscriptionId': subscriptionId.substring(0, 8),
                'roomId': roomId,
              },
            );
          }
        }

        // Notify RoomSyncManager about new members
        if (isRoomCreated) {
          // For room creation, all members are in targetSubscriptionIds
          _roomSyncManager.onMembersReceived(roomId, targetSubscriptionIds);
        } else {
          // For member addition, notify for each added member
          for (final subscriptionId in targetSubscriptionIds) {
            await _roomSyncManager.onMemberAdded(roomId, subscriptionId);
          }
        }
      } else if (isMemberRemoved) {
        // Handle member removal
        for (final subscriptionId in targetSubscriptionIds) {
          // Remove subscription from local database
          await _roomSubscriptionRepository.removeSubscription(subscriptionId);

          // Notify RoomSyncManager about member removal
          await _roomSyncManager.onMemberRemoved(roomId, subscriptionId);

          AppLogger.debug(
            'Removed subscription from moderation event',
            data: {
              'subscriptionId': subscriptionId.substring(0, 8),
              'roomId': roomId,
            },
          );
        }
      }

      // Also store the actor's subscription if provided and not empty
      if (actorSubscriptionId.isNotEmpty) {
        await _roomSubscriptionRepository.createSubscription(
          id: actorSubscriptionId,
          roomId: roomId,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error processing moderation event',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId, 'body': moderation.body},
      );
    }
  }

  /// Process room change events using the typed RoomChangeAction enum
  ///
  /// Replaces the legacy moderation event text parsing with structured actions:
  /// - CREATED: Store subscription IDs, notify RoomSyncManager
  /// - UPDATED: Apply room metadata changes from details Struct
  /// - DELETED: Mark room as deleted locally
  /// - MEMBER_ADDED: Store new member subscriptions
  /// - MEMBER_REMOVED: Remove member subscriptions
  /// - ROLE_CHANGED: Update member roles
  Future<void> _processRoomChangeEvent(
    String roomId,
    pb.RoomChangeContent roomChange,
    String actorSubscriptionId,
  ) async {
    try {
      final targetSubscriptionIds = roomChange.targetSubscriptionIds.toList();
      final action = roomChange.action;

      AppLogger.info(
        'Processing room change event',
        data: {
          'roomId': roomId,
          'action': action.name,
          'actorSubscriptionId': actorSubscriptionId.isNotEmpty
              ? actorSubscriptionId.substring(
                  0,
                  actorSubscriptionId.length < 8
                      ? actorSubscriptionId.length
                      : 8,
                )
              : 'unknown',
          'targetCount': targetSubscriptionIds.length,
        },
      );

      switch (action) {
        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_CREATED:
          // Store all subscription IDs from the event
          for (final subscriptionId in targetSubscriptionIds) {
            await _roomSubscriptionRepository.createSubscription(
              id: subscriptionId,
              roomId: roomId,
            );
          }
          // Notify RoomSyncManager - all members in targetSubscriptionIds
          _roomSyncManager.onMembersReceived(roomId, targetSubscriptionIds);

        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_UPDATED:
          // Apply room changes from the details Struct
          if (roomChange.hasDetails()) {
            final details = _structToMap(roomChange.details);
            final name = details['name'] as String?;
            final description = details['description'] as String?;
            final avatarUrl = details['avatarUrl'] as String?;

            if (name != null) {
              await _roomRepository.updateRoomName(roomId, name);
            }

            // Build metadata updates from details
            final metadataUpdates = <String, dynamic>{};
            if (description != null) {
              metadataUpdates['description'] = description;
            }
            if (avatarUrl != null) {
              metadataUpdates['avatarUrl'] = avatarUrl;
            }
            // Forward any other detail fields as metadata
            for (final entry in details.entries) {
              if (!{'name', 'description', 'avatarUrl'}.contains(entry.key)) {
                metadataUpdates[entry.key] = entry.value;
              }
            }
            if (metadataUpdates.isNotEmpty) {
              await _roomRepository.updateRoomMetadata(roomId, metadataUpdates);
            }
          }

          AppLogger.info('Room updated from server', data: {'roomId': roomId});

        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_DELETED:
          await _roomRepository.markRoomDeleted(roomId);
          _roomSyncManager.disposeRoom(roomId);

          AppLogger.info(
            'Room marked deleted from server',
            data: {'roomId': roomId},
          );

        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_MEMBER_ADDED:
          for (final subscriptionId in targetSubscriptionIds) {
            await _roomSubscriptionRepository.createSubscription(
              id: subscriptionId,
              roomId: roomId,
            );
          }
          // Notify RoomSyncManager for each added member
          for (final subscriptionId in targetSubscriptionIds) {
            await _roomSyncManager.onMemberAdded(roomId, subscriptionId);
          }

        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_MEMBER_REMOVED:
          for (final subscriptionId in targetSubscriptionIds) {
            await _roomSubscriptionRepository.removeSubscription(
              subscriptionId,
            );
            await _roomSyncManager.onMemberRemoved(roomId, subscriptionId);
          }

        case pb.RoomChangeAction.ROOM_CHANGE_ACTION_ROLE_CHANGED:
          // Extract new role from details
          if (roomChange.hasDetails()) {
            final details = _structToMap(roomChange.details);
            final newRole = details['role'] as String?;
            if (newRole != null) {
              for (final subscriptionId in targetSubscriptionIds) {
                await _roomSubscriptionRepository.updateMemberRole(
                  id: subscriptionId,
                  newRole: newRole,
                );
              }
            }
          }

        default:
          AppLogger.debug(
            'Unhandled room change action',
            data: {'action': action.name, 'roomId': roomId},
          );
      }

      // Also store the actor's subscription if provided
      if (actorSubscriptionId.isNotEmpty) {
        await _roomSubscriptionRepository.createSubscription(
          id: actorSubscriptionId,
          roomId: roomId,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error processing room change event',
        error: e,
        stackTrace: stackTrace,
        data: {
          'roomId': roomId,
          'action': roomChange.action.name,
          'body': roomChange.body,
        },
      );
    }
  }

  Future<void> _processReceiptEvent(pb.ReceiptEvent event) async {
    // Update status for received read receipts
    final eventIds = event.eventId.toList();
    if (eventIds.isEmpty) return;

    // Get the subscription ID of the reader
    final subscriptionId = event.hasSubscriptionId()
        ? event.subscriptionId
        : null;

    // Get the room ID from one of the events (for storing receipts)
    String? roomId;
    String? readerProfileId;

    if (subscriptionId != null) {
      // Look up the profile ID from the subscription
      final member = await _roomSubscriptionRepository.getSubscription(
        subscriptionId,
      );
      if (member != null) {
        roomId = member.roomId;
        readerProfileId = member.profileId;
      }
    }

    // If we have reader info, store read receipts
    if (roomId != null && readerProfileId != null) {
      final readAt = DateTime.now().millisecondsSinceEpoch;
      for (final eventId in eventIds) {
        await _readReceiptRepo.saveReadReceipt(
          eventId: eventId,
          roomId: roomId,
          profileId: readerProfileId,
          readAt: readAt,
        );
      }

      // Mark messages as read (since someone read them)
      await _messageRepo.updateMessagesStatus(
        eventIds,
        domain.EventStatus.read,
      );

      AppLogger.debug(
        'Processed read receipts',
        data: {
          'eventCount': eventIds.length,
          'reader': readerProfileId.substring(0, 8),
        },
      );
    } else {
      // Cannot identify the reader - log and skip rather than
      // incorrectly setting delivered status for a read receipt
      AppLogger.warning(
        'Cannot process read receipt: reader subscription not found',
        data: {'subscriptionId': subscriptionId, 'eventCount': eventIds.length},
      );
    }
  }

  /// Process a roomKey event containing E2EE session key data
  ///
  /// When another user shares their Megolm session key with us, we need to
  /// add it as an inbound session so we can decrypt their messages.
  Future<void> _processRoomKeyEvent(
    Map<String, dynamic> keyData,
    String eventRoomId,
  ) async {
    try {
      final roomId = keyData['roomId'] as String? ?? eventRoomId;
      final sessionId = keyData['sessionId'] as String?;
      final sessionKey = keyData['sessionKey'] as String?;
      final senderKey = keyData['senderKey'] as String?;

      if (sessionId == null || sessionKey == null || senderKey == null) {
        AppLogger.warning(
          'Invalid roomKey event: missing required fields',
          data: {
            'hasSessionId': sessionId != null,
            'hasSessionKey': sessionKey != null,
            'hasSenderKey': senderKey != null,
          },
        );
        return;
      }

      // Add the session key as an inbound group session
      await _encryptionService.addInboundGroupSession(
        roomId,
        sessionId,
        sessionKey,
        senderKey: senderKey,
      );

      AppLogger.info(
        'Received and stored session key',
        data: {
          'roomId': roomId,
          'sessionId': sessionId,
          'senderKey': senderKey.substring(0, 8),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to process roomKey event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Trigger an immediate upload of pending jobs.
  ///
  /// Use this after queueing high-priority jobs (e.g. room creation) to
  /// avoid waiting for the reactive watch stream to fire. If an upload
  /// is already in progress, the jobs will be picked up when it finishes.
  Future<void> triggerUpload() async {
    if (_uploadLock != null || !_isConnected || _shouldStop) return;

    // Acquire lock before any await to prevent the watch stream listener from
    // concurrently processing the same jobs.
    _uploadLock = Completer<void>();

    try {
      final jobs = await _jobRepo.getPendingJobs();
      if (jobs.isEmpty) return;

      AppLogger.debug(
        'Triggered upload of pending jobs',
        data: {'count': jobs.length},
      );

      for (final job in jobs) {
        if (_shouldStop || !_isConnected) break;
        try {
          await _processJob(job);
        } catch (e, stackTrace) {
          AppLogger.error(
            'Error processing job',
            error: e,
            stackTrace: stackTrace,
            data: {'jobId': job.id, 'jobType': job.type.toString()},
          );
        }
      }
    } finally {
      _uploadLock?.complete();
      _uploadLock = null;
    }
  }

  void _startUploadLoop() {
    // Cancel existing subscription to prevent multiple watchers
    _jobWatchSubscription?.cancel();

    if (_shouldStop) return;

    // Use reactive database watching instead of polling
    _jobWatchSubscription = _jobRepo.watchPendingJobs().listen(
      (jobs) async {
        // Only process if connected and not already uploading
        if (_uploadLock != null || !_isConnected || _shouldStop) return;
        if (jobs.isEmpty) return;

        _uploadLock = Completer<void>();
        AppLogger.debug(
          'Processing pending jobs',
          data: {'count': jobs.length},
        );

        try {
          // Process jobs sequentially to avoid overwhelming the server
          for (final job in jobs) {
            if (_shouldStop || !_isConnected) break;

            try {
              await _processJob(job);
            } catch (e, stackTrace) {
              AppLogger.error(
                'Error processing job',
                error: e,
                stackTrace: stackTrace,
                data: {'jobId': job.id, 'jobType': job.type.toString()},
              );
            }
          }
        } catch (e, stackTrace) {
          // Log but don't crash
          AppLogger.error(
            'Upload loop error',
            error: e,
            stackTrace: stackTrace,
          );
        } finally {
          _uploadLock?.complete();
          _uploadLock = null;
        }
      },
      onError: (Object e, StackTrace stackTrace) {
        AppLogger.error(
          'Job watch stream error',
          error: e,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _processJob(domain_job.PendingJob job) async {
    // Skip jobs that have exceeded retry limit — mark as failed so they are
    // visible in the FailedJobsBanner instead of silently disappearing.
    if (job.retryCount >= PendingJobRepository.maxRetries) {
      await _jobRepo.markJobFailed(
        job.id,
        errorMessage: 'Max retries exceeded',
        errorCode: 'MAX_RETRIES',
      );
      return;
    }

    try {
      switch (job.type) {
        case domain_job.JobType.sendMessage:
        case domain_job.JobType.sendMediaMessage:
          await _processSendMessage(job);
          break;
        case domain_job.JobType.uploadFile:
          // File uploads are handled by FilesUploadService before queuing
          break;
        case domain_job.JobType.createRoom:
          await _processCreateRoom(job);
          break;
        case domain_job.JobType.updateRoom:
          await _processUpdateRoom(job);
          break;
        case domain_job.JobType.deleteRoom:
          await _processDeleteRoom(job);
          break;
        case domain_job.JobType.addRoomMembers:
          await _processAddRoomMembers(job);
          break;
        case domain_job.JobType.removeRoomMembers:
          await _processRemoveRoomMembers(job);
          break;
        case domain_job.JobType.leaveRoom:
          await _processLeaveRoom(job);
          break;
        case domain_job.JobType.vote:
          await _processVote(job);
          break;
        case domain_job.JobType.syncContacts:
          // Contact sync is handled by ContactSyncRepository
          break;
        case domain_job.JobType.editMessage:
          await _processEditMessage(job);
          break;
        case domain_job.JobType.deleteMessage:
          await _processDeleteMessage(job);
          break;
        case domain_job.JobType.updateRoomAvatar:
          // Avatar updates are included in updateRoom job
          await _processUpdateRoom(job);
          break;
        case domain_job.JobType.updateRoomPermissions:
          // Permission updates are included in updateRoom job
          await _processUpdateRoom(job);
          break;
        case domain_job.JobType.changeMemberRole:
          await _processChangeMemberRole(job);
          break;
        case domain_job.JobType.forwardMessage:
          await _processForwardMessage(job);
          break;
        case domain_job.JobType.custom:
          // Custom jobs are handled by their respective services
          break;
        case domain_job.JobType.createInviteLink:
        case domain_job.JobType.revokeInviteLink:
        case domain_job.JobType.useInviteLink:
        case domain_job.JobType.approveJoinRequest:
        case domain_job.JobType.rejectJoinRequest:
          // Invite link jobs are handled by InviteLinkService
          break;
      }
      await _jobRepo.deleteJob(job.id);
    } on MissingSubscriptionIdException catch (e) {
      await _jobRepo.deferJob(
        job.id,
        reason: 'subscription_missing:${e.roomId}',
      );
      AppLogger.debug(
        'Deferred job due to missing subscription',
        data: {'jobId': job.id, 'roomId': e.roomId},
      );
      return;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Job processing failed',
        error: e,
        stackTrace: stackTrace,
        data: {
          'jobId': job.id,
          'jobType': job.type.toString(),
          'retryCount': job.retryCount,
        },
      );
      await _jobRepo.incrementRetry(job.id);
    }
  }

  Future<void> _processCreateRoom(domain_job.PendingJob job) async {
    final payload = job.payload;

    // Convert contact IDs to ContactLink objects for server routing
    final contactIds =
        (payload['contactIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final memberLinks = contactIds
        .map((id) => common_types.ContactLink(contactId: id))
        .toList();

    final request = pb.CreateRoomRequest(
      id: payload['id'] as String,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String? ?? '',
      isPrivate: payload['isPrivate'] as bool? ?? false,
      members: memberLinks,
    );

    if (payload['metadata'] != null) {
      request.metadata = _mapToStruct(
        payload['metadata'] as Map<String, dynamic>,
      );
    }

    final response = await _chatClient.createRoom(request);

    if (response.hasRoom()) {
      final roomId = response.room.id;
      AppLogger.info(
        'Room created on server',
        data: {'localId': payload['id'], 'serverId': roomId},
      );

      // Sync room members immediately to get the current user's subscription ID.
      // This goes directly from CREATING → READY, skipping the intermediate
      // SYNCING state and its timeout-based fallback. The timeout/moderation-event
      // path is only useful when we can't do an inline API sync, but here we can.
      try {
        await _syncRoomMembers(roomId);
        AppLogger.debug(
          'Room members synced after creation',
          data: {'roomId': roomId},
        );

        // Replace provisional subscription with the real one
        await _replaceProvisionalSubscription(roomId);
      } catch (e) {
        AppLogger.warning(
          'API sync failed after room creation, provisional subscription kept',
          data: {'roomId': roomId, 'error': e.toString()},
        );
        // Even on failure, mark as API sync complete so room is usable.
        // Provisional subscription remains in place and will be replaced
        // on the next reconnection sync.
      }

      // Transition directly to READY - room exists on server,
      // user should be able to use it immediately
      await _roomSyncManager.onApiSyncComplete(roomId);
    } else if (response.hasError()) {
      AppLogger.error(
        'Server rejected room creation',
        data: {'error': response.error.message},
      );
      throw Exception('Room creation failed: ${response.error.message}');
    }
  }

  Future<void> _processUpdateRoom(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['id'] as String;

    final request = pb.UpdateRoomRequest(
      roomId: roomId,
      name: payload['name'] as String? ?? '',
      description: payload['description'] as String? ?? '',
    );

    // Build metadata including avatar and permissions if present
    final metadataMap = <String, dynamic>{};
    if (payload['metadata'] != null) {
      metadataMap.addAll(payload['metadata'] as Map<String, dynamic>);
    }
    if (payload['avatarUrl'] != null) {
      metadataMap['avatarUrl'] = payload['avatarUrl'];
    }
    if (payload['editInfoPermission'] != null) {
      metadataMap['editInfoPermission'] = payload['editInfoPermission'];
    }
    if (payload['sendMessagesPermission'] != null) {
      metadataMap['sendMessagesPermission'] = payload['sendMessagesPermission'];
    }
    if (payload['addMembersPermission'] != null) {
      metadataMap['addMembersPermission'] = payload['addMembersPermission'];
    }

    if (metadataMap.isNotEmpty) {
      request.metadata = _mapToStruct(metadataMap);
    }

    await _chatClient.updateRoom(request);
    AppLogger.info('Room updated on server', data: {'roomId': roomId});
  }

  Future<void> _processDeleteRoom(domain_job.PendingJob job) async {
    final payload = job.payload;

    final request = pb.DeleteRoomRequest(roomId: payload['id'] as String);

    await _chatClient.deleteRoom(request);
    AppLogger.info('Room deleted on server', data: {'roomId': payload['id']});
  }

  Future<void> _processAddRoomMembers(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['roomId'] as String;
    final profileIds = (payload['profileIds'] as List<dynamic>).cast<String>();

    // Convert profileIds to RoomSubscription objects with ContactLink
    final members = profileIds
        .map(
          (profileId) => pb.RoomSubscription(
            roomId: roomId,
            member: common_types.ContactLink(profileId: profileId),
          ),
        )
        .toList();

    final request = pb.AddRoomSubscriptionsRequest(
      roomId: roomId,
      members: members,
    );

    await _chatClient.addRoomSubscriptions(request);
    AppLogger.info(
      'Members added to room on server',
      data: {'roomId': roomId, 'memberCount': profileIds.length},
    );
  }

  Future<void> _processRemoveRoomMembers(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['roomId'] as String;

    // Note: The API now expects subscription_id instead of profileIds
    // Prefer explicit subscription IDs, else map profile IDs to subscriptions
    final explicitIds = (payload['subscriptionIds'] as List<dynamic>?)
        ?.cast<String>();
    final subscriptionIds = <String>[];
    if (explicitIds != null && explicitIds.isNotEmpty) {
      subscriptionIds.addAll(explicitIds);
    } else {
      final profileIds =
          (payload['profileIds'] as List<dynamic>?)?.cast<String>() ?? [];
      for (final profileId in profileIds) {
        final member = await _roomSubscriptionRepository.getMemberByProfileId(
          roomId,
          profileId,
        );
        if (member != null) {
          subscriptionIds.add(member.id);
        } else {
          AppLogger.warning(
            'Subscription not found for profile removal',
            data: {'roomId': roomId, 'profileId': profileId},
          );
        }
      }
    }
    if (subscriptionIds.isEmpty) {
      throw StateError('No subscription IDs found for removal');
    }

    final request = pb.RemoveRoomSubscriptionsRequest(
      roomId: roomId,
      subscriptionId: subscriptionIds,
    );

    await _chatClient.removeRoomSubscriptions(request);
    AppLogger.info(
      'Members removed from room on server',
      data: {
        'roomId': payload['roomId'],
        'memberCount': subscriptionIds.length,
      },
    );
  }

  Future<void> _processChangeMemberRole(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['roomId'] as String?;
    final subscriptionId = payload['subscriptionId'] as String?;
    final newRole = payload['role'] as String?;

    if (roomId == null || subscriptionId == null || newRole == null) {
      AppLogger.error(
        'Invalid payload for changeMemberRole job',
        data: {'jobId': job.id},
      );
      return;
    }

    // Update the role locally (already done in RoomService.changeMemberRole)
    // The server sync can be handled via UpdateRoomSubscription API when available
    // For now, log the role change request
    AppLogger.info(
      'Member role change queued for sync',
      data: {
        'roomId': roomId,
        'subscriptionId': subscriptionId,
        'newRole': newRole,
      },
    );

    // TODO(antinvestor): Add server API call when backend supports role changes
    // Example: await _chatClient.updateRoomSubscription(request);
  }

  Future<void> _processLeaveRoom(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['id'] as String;

    // Get current profile's subscription ID to remove their subscription
    final subscriptionId = await getCurrentSubscriptionId(
      roomId,
      syncIfMissing: true,
    );
    if (subscriptionId == null) {
      throw MissingSubscriptionIdException(roomId);
    }

    final request = pb.RemoveRoomSubscriptionsRequest(
      roomId: roomId,
      subscriptionId: [subscriptionId], // Remove current profile's subscription
    );

    await _chatClient.removeRoomSubscriptions(request);
    AppLogger.info('Left room on server', data: {'roomId': roomId});
  }

  Future<void> _processSendMessage(domain_job.PendingJob job) async {
    final payload = job.payload;
    final roomId = payload['roomId'] as String;

    // Get subscription ID for the room (consistent with UI's isMe detection)
    final subscriptionId = await getCurrentSubscriptionId(
      roomId,
      syncIfMissing: true,
    );
    if (subscriptionId == null || subscriptionId.isEmpty) {
      throw MissingSubscriptionIdException(roomId);
    }

    // Create timestamp
    final now = DateTime.now();
    final timestamp = common_types.Timestamp.fromDateTime(now);

    // Extract content and type
    final content = payload['content'] as Map<String, dynamic>;
    final localType = domain.RoomEventType.values.firstWhere(
      (t) => t.toString() == payload['type'],
      orElse: () => domain.RoomEventType.text,
    );
    final protoType = _mapLocalEventTypeToProto(localType);

    // Build event with payload-based content
    final pbPayload = pb.Payload();
    if (content['encrypted'] == true && content['ciphertext'] != null) {
      pbPayload.encrypted = pb.EncryptedContent(
        algorithm: content['algorithm'] as String? ?? 'megolm.v1',
        ciphertext: base64Decode(content['ciphertext'] as String),
        senderKeyId: content['senderKey'] as String? ?? '',
        sessionId: content['sessionId'] as String? ?? '',
      );
    } else if (localType == domain.RoomEventType.text) {
      pbPayload.text = pb.TextContent(
        body: content['text'] as String? ?? '',
        format: 'plain',
      );
    } else if (localType == domain.RoomEventType.roomKey) {
      // Room key events are sent as JSON-encoded text for key sharing
      pbPayload.text = pb.TextContent(
        body: content['text'] as String? ?? '',
        format: 'plain',
      );
    } else if (localType == domain.RoomEventType.image ||
        localType == domain.RoomEventType.video ||
        localType == domain.RoomEventType.audio ||
        localType == domain.RoomEventType.file) {
      final attachmentId = content['attachmentId'] as String?;
      if (attachmentId == null || attachmentId.isEmpty) {
        throw StateError('Missing attachmentId for media message');
      }
      pbPayload.attachment = pb.AttachmentContent(
        attachmentId: attachmentId,
        filename: content['fileName'] as String? ?? '',
        mimeType: content['mimeType'] as String? ?? '',
        sizeBytes: Int64(content['size'] as int? ?? 0),
      );
    }

    final event = pb.RoomEvent(
      id: payload['localId'] as String? ?? '',
      roomId: roomId,
      subscriptionId: subscriptionId ?? '',
      type: protoType,
      sentAt: timestamp,
      payload: pbPayload,
    );

    // Add parentId if this is a reply
    if (payload['parentId'] != null) {
      event.parentId = payload['parentId'] as String;
    }

    final request = pb.SendEventRequest(event: [event]);
    final response = await _chatClient.sendEvent(request);

    // Update the existing local row (id=localId) with the server-assigned ID
    // Use subscriptionId (not profileId) as senderId to match UI's isMe detection
    if (payload['localId'] != null && response.ack.isNotEmpty) {
      final ackEventId = response.ack.first.eventId;
      final localId = payload['localId'] as String;
      // Use the same subscriptionId that was used at message creation time
      // so the UI's isMe check (senderId == currentUserSubscriptionId) stays consistent
      final senderSubId = subscriptionId;
      await _messageRepo.updateMessageIdAfterAck(
        localId,
        serverId: ackEventId.first,
        senderId: senderSubId,
        status: domain.EventStatus.sent,
        serverTs: now.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _processVote(domain_job.PendingJob job) async {
    final payload = job.payload;
    final currentProfileId = await _authRepository.getCurrentProfileId();

    // Create timestamp
    final now = DateTime.now();
    final timestamp = common_types.Timestamp.fromDateTime(now);
    // Source is no longer used in new API

    // Build vote payload - use text content since VoteContent doesn't exist yet
    final pbPayload = pb.Payload();
    final voteData = {
      'motionId': payload['motionId'],
      'option': payload['option'],
      'type': 'vote',
    };
    pbPayload.text = pb.TextContent(body: voteData.toString(), format: 'plain');

    final event = pb.RoomEvent(
      id: payload['localId'] as String? ?? '',
      roomId: payload['roomId'] as String,
      type:
          pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE, // Vote not in protobuf yet
      sentAt: timestamp,
      payload: pbPayload,
    );

    final request = pb.SendEventRequest(event: [event]);
    await _chatClient.sendEvent(request);

    // Update local motion event with the new vote
    await _updateMotionVote(
      payload['motionId'] as String,
      currentProfileId ?? 'unknown',
      payload['option'] as String,
    );
  }

  Future<void> _updateMotionVote(
    String motionId,
    String profileId,
    String option,
  ) async {
    final motionEvent = await _messageRepo.getEventById(motionId);
    if (motionEvent == null) return;

    final votes = Map<String, dynamic>.from(
      motionEvent.content['votes'] as Map<String, dynamic>? ?? {},
    );

    // Update or add the vote
    votes[profileId] = option;

    final updatedContent = Map<String, dynamic>.from(motionEvent.content);
    updatedContent['votes'] = votes;

    final updatedEvent = motionEvent.copyWith(content: updatedContent);
    await _messageRepo.insertMessage(updatedEvent);
  }

  Future<void> _processEditMessage(domain_job.PendingJob job) async {
    final payload = job.payload;
    final messageId = payload['messageId'] as String;
    final roomId = payload['roomId'] as String;
    final content = payload['content'] as Map<String, dynamic>;

    // Build the edit request
    final timestamp = common_types.Timestamp.fromDateTime(DateTime.now());

    final pbPayload = pb.Payload();
    pbPayload.text = pb.TextContent(
      body: content['text'] as String? ?? '',
      format: 'plain',
    );

    // Send as an edit event to the server
    // Note: Backend API for editing may need to be implemented
    // For now, we send as a regular message with edit metadata
    final event = pb.RoomEvent(
      id: messageId,
      roomId: roomId,
      type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
      sentAt: timestamp,
      payload: pbPayload,
    );

    final request = pb.SendEventRequest(event: [event]);
    await _chatClient.sendEvent(request);

    AppLogger.info('Edit message synced', data: {'messageId': messageId});
  }

  Future<void> _processDeleteMessage(domain_job.PendingJob job) async {
    final payload = job.payload;
    final messageId = payload['messageId'] as String;
    final roomId = payload['roomId'] as String;

    // Send a redacted event to mark the message as deleted
    final timestamp = common_types.Timestamp.fromDateTime(DateTime.now());

    final event = pb.RoomEvent(
      id: messageId,
      roomId: roomId,
      type: pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE,
      sentAt: timestamp,
      redacted: true,
    );

    final request = pb.SendEventRequest(event: [event]);
    await _chatClient.sendEvent(request);

    AppLogger.info('Delete message synced', data: {'messageId': messageId});
  }

  Future<void> _processForwardMessage(domain_job.PendingJob job) async {
    final payload = job.payload;
    final originalMessageId = payload['originalMessageId'] as String;
    final destinationRoomId = payload['destinationRoomId'] as String;
    final localId = payload['localId'] as String?;
    final subscriptionId = await getCurrentSubscriptionId(
      destinationRoomId,
      syncIfMissing: true,
    );
    if (subscriptionId == null || subscriptionId.isEmpty) {
      throw MissingSubscriptionIdException(destinationRoomId);
    }

    // Get original message content
    final content = payload['content'] as Map<String, dynamic>;
    final localType = domain.RoomEventType.values.firstWhere(
      (t) => t.toString() == payload['type'],
      orElse: () => domain.RoomEventType.text,
    );
    final protoType = _mapLocalEventTypeToProto(localType);

    // Build event with forwarded content
    final timestamp = common_types.Timestamp.fromDateTime(DateTime.now());
    final pbPayload = pb.Payload();

    if (localType == domain.RoomEventType.text) {
      pbPayload.text = pb.TextContent(
        body: content['text'] as String? ?? '',
        format: 'plain',
      );
    } else if (localType == domain.RoomEventType.image ||
        localType == domain.RoomEventType.video ||
        localType == domain.RoomEventType.audio ||
        localType == domain.RoomEventType.file) {
      pbPayload.attachment = pb.AttachmentContent(
        attachmentId: content['attachmentId'] as String? ?? '',
        filename: content['fileName'] as String? ?? '',
        mimeType: content['mimeType'] as String? ?? '',
        sizeBytes: Int64(content['size'] as int? ?? 0),
      );
    }

    final event = pb.RoomEvent(
      id: localId ?? '',
      roomId: destinationRoomId,
      subscriptionId: subscriptionId,
      type: protoType,
      sentAt: timestamp,
      payload: pbPayload,
    );

    final request = pb.SendEventRequest(event: [event]);
    final response = await _chatClient.sendEvent(request);

    // Update local message with server ID
    if (localId != null && response.ack.isNotEmpty) {
      final ackEventId = response.ack.first.eventId;
      final updatedEvent = domain.RoomEvent(
        id: ackEventId.first,
        roomId: destinationRoomId,
        senderId: subscriptionId,
        type: localType,
        content: content,
        status: domain.EventStatus.sent,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        localId: localId,
        forwardedFromEvent: originalMessageId,
      );
      await _messageRepo.insertMessage(updatedEvent);
    }

    AppLogger.info(
      'Forward message synced',
      data: {
        'originalMessageId': originalMessageId,
        'destinationRoomId': destinationRoomId,
      },
    );
  }

  // Helper methods for type conversion

  // ignore: unused_element - kept for future use in reconnection logic
  domain.RoomEventType _mapProtoEventType(pb.RoomEventType type) {
    switch (type) {
      case pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE:
        return domain.RoomEventType.text;
      case pb.RoomEventType.ROOM_EVENT_TYPE_REACTION:
        return domain.RoomEventType.reaction;
      case pb.RoomEventType.ROOM_EVENT_TYPE_CALL:
        // Map the unified CALL type to callOffer by default
        // The specific call action can be determined from the call content
        return domain.RoomEventType.callOffer;
      case pb.RoomEventType.ROOM_EVENT_TYPE_MOTION:
        return domain.RoomEventType.motion;
      case pb.RoomEventType.ROOM_EVENT_TYPE_EVENT:
        // System event - map to a special type or text for now
        return domain
            .RoomEventType
            .text; // Could create a new system event type
      default:
        return domain.RoomEventType.text;
    }
  }

  pb.RoomEventType _mapLocalEventTypeToProto(domain.RoomEventType type) {
    switch (type) {
      case domain.RoomEventType.text:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.image:
      case domain.RoomEventType.video:
      case domain.RoomEventType.audio:
      case domain.RoomEventType.file:
        // All media types map to MESSAGE with attachment payload
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.reaction:
        return pb.RoomEventType.ROOM_EVENT_TYPE_REACTION;
      case domain.RoomEventType.callOffer:
      case domain.RoomEventType.callAnswer:
      case domain.RoomEventType.callIce:
      case domain.RoomEventType.callEnd:
      case domain.RoomEventType.groupCallStart:
      case domain.RoomEventType.groupCallJoin:
      case domain.RoomEventType.groupCallLeave:
      case domain.RoomEventType.groupCallEnd:
      case domain.RoomEventType.groupCallOffer:
      case domain.RoomEventType.groupCallAnswer:
      case domain.RoomEventType.groupCallIce:
      case domain.RoomEventType.groupCallMuteUpdate:
        // All call types (1-on-1 and group) map to a single ROOM_EVENT_TYPE_CALL
        return pb.RoomEventType.ROOM_EVENT_TYPE_CALL;
      case domain.RoomEventType.motion:
        return pb.RoomEventType.ROOM_EVENT_TYPE_MOTION;
      case domain.RoomEventType.vote:
      case domain.RoomEventType.transaction:
      case domain.RoomEventType.groupConfig:
        // These might not be in protobuf yet, map to MESSAGE for now
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.roomKey:
        // Room key events are sent as encrypted messages for key exchange
        return pb.RoomEventType.ROOM_EVENT_TYPE_MESSAGE;
      case domain.RoomEventType.roomChange:
        // Room change events are system events
        return pb.RoomEventType.ROOM_EVENT_TYPE_EVENT;
    }
  }

  // Convert protobuf Struct to Dart Map
  Map<String, dynamic> _structToMap(common_types.Struct struct) {
    final result = <String, dynamic>{};
    for (final entry in struct.fields.entries) {
      result[entry.key] = _valueToObject(entry.value);
    }
    return result;
  }

  dynamic _valueToObject(common_types.Value value) {
    if (value.hasStringValue()) return value.stringValue;
    if (value.hasNumberValue()) return value.numberValue;
    if (value.hasBoolValue()) return value.boolValue;
    if (value.hasNullValue()) return null;
    if (value.hasListValue()) {
      return value.listValue.values.map(_valueToObject).toList();
    }
    if (value.hasStructValue()) {
      return _structToMap(value.structValue);
    }
    return null;
  }

  // Convert Dart Map to protobuf Struct
  common_types.Struct _mapToStruct(Map<String, dynamic> map) {
    final struct = common_types.Struct();
    for (final entry in map.entries) {
      struct.fields[entry.key] = _objectToValue(entry.value);
    }
    return struct;
  }

  common_types.Value _objectToValue(Object? obj) {
    final value = common_types.Value();
    if (obj == null) {
      value.nullValue = common_types.NullValue.NULL_VALUE;
    } else if (obj is String) {
      value.stringValue = obj;
    } else if (obj is num) {
      value.numberValue = obj.toDouble();
    } else if (obj is bool) {
      value.boolValue = obj;
    } else if (obj is List) {
      final listValue = common_types.ListValue();
      listValue.values.addAll(obj.map(_objectToValue));
      value.listValue = listValue;
    } else if (obj is Map) {
      value.structValue = _mapToStruct(obj.cast<String, dynamic>());
    }
    return value;
  }

  /// Get the current profile's SUBSCRIPTION ID for a specific room
  /// Returns null if the profile is not a member of the room
  ///
  /// IMPORTANT: This returns a SUBSCRIPTION ID (room-specific presence),
  /// not a PROFILE ID (global identity). Use this for room operations.
  ///
  /// Note: This method works for both authenticated and anonymous subscriptions
  /// The subscription ID is independent of profile ID.
  ///
  /// @param roomId The room to get subscription for
  /// @param syncIfMissing If true, sync room members when subscription not found
  /// @param maxRetries Number of sync attempts before giving up (only used if syncIfMissing)
  Future<String?> getCurrentSubscriptionId(
    String roomId, {
    bool syncIfMissing = false,
    int maxRetries = 2,
  }) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final currentContactId = await _authRepository.getCurrentContactId();
    if (currentContactId == null) return null;

    // First attempt - check local database
    var subscriptionId = await _roomSubscriptionRepository
        .getCurrentSubscriptionId(
          roomId,
          currentProfileId ?? '', // Empty string for anonymous subscriptions
          currentContactId,
        );

    if (subscriptionId != null) {
      return subscriptionId;
    }

    // Subscription not found - try syncing if enabled
    if (!syncIfMissing) {
      return null;
    }

    AppLogger.debug(
      'Subscription not found locally, attempting sync',
      data: {'roomId': roomId, 'maxRetries': maxRetries},
    );

    // Sync and retry
    for (var retry = 0; retry < maxRetries; retry++) {
      try {
        await _syncRoomMembersIfNeeded(roomId, forceSync: retry > 0);

        subscriptionId = await _roomSubscriptionRepository
            .getCurrentSubscriptionId(
              roomId,
              currentProfileId ?? '',
              currentContactId,
            );

        if (subscriptionId != null) {
          AppLogger.info(
            'Subscription found after sync',
            data: {'roomId': roomId, 'attempt': retry + 1},
          );
          return subscriptionId;
        }
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Room member sync failed',
          data: {'roomId': roomId, 'attempt': retry + 1, 'error': e.toString()},
        );
        if (retry == maxRetries - 1) {
          AppLogger.error(
            'All sync attempts failed',
            error: e,
            stackTrace: stackTrace,
            data: {'roomId': roomId},
          );
        }
      }
    }

    return null;
  }

  /// Sync room members from server if not recently synced
  ///
  /// @param roomId The room to sync members for
  /// @param forceSync If true, sync even if recently synced
  Future<void> _syncRoomMembersIfNeeded(
    String roomId, {
    bool forceSync = false,
  }) async {
    // Check cache
    if (!forceSync) {
      final lastSync = _roomMemberSyncCache[roomId];
      if (lastSync != null) {
        final elapsed = DateTime.now().difference(lastSync);
        if (elapsed < _roomMemberSyncCacheDuration) {
          AppLogger.debug(
            'Skipping room member sync - recently synced',
            data: {
              'roomId': roomId,
              'elapsedSeconds': elapsed.inSeconds,
              'cacheSeconds': _roomMemberSyncCacheDuration.inSeconds,
            },
          );
          return;
        }
      }
    }

    // Perform sync
    await _syncRoomMembers(roomId);

    // Update cache
    _roomMemberSyncCache[roomId] = DateTime.now();
  }

  /// Sync room members from server
  ///
  /// @param roomId The room to sync members for
  Future<void> _syncRoomMembers(String roomId) async {
    try {
      // Create request to search room subscriptions
      final request = pb.SearchRoomSubscriptionsRequest(roomId: roomId);

      // Fetch subscriptions from API
      final response = await _chatClient.searchRoomSubscriptions(request);

      var memberCount = 0;

      // Process each subscription from the response
      for (final subscription in response.members) {
        // Extract subscription ID from API response
        final subscriptionId = subscription.id;

        // Extract profileId and contactId from ContactLink
        final profileId =
            subscription.hasMember() && subscription.member.hasProfileId()
            ? subscription.member.profileId
            : null;
        final contactId =
            subscription.hasMember() && subscription.member.hasContactId()
            ? subscription.member.contactId
            : null;

        // Extract role (use first role if multiple, or null)
        final role = subscription.roles.isNotEmpty
            ? subscription.roles.first
            : null;

        // Note: joinedAt is available via subscription.joinedAt but
        // createSubscription uses current timestamp for simplicity

        // Insert or update room member using repository
        await _roomSubscriptionRepository.createSubscription(
          id: subscriptionId,
          roomId: subscription.roomId,
          profileId: profileId,
          contactId: contactId,
          role: role,
        );

        memberCount++;
      }

      AppLogger.info(
        'Room members synced via SyncEngine',
        data: {'roomId': roomId, 'memberCount': memberCount},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to sync room members',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      rethrow;
    }
  }

  /// Public method to sync room members for a specific room
  /// Can be called by external services when needed
  Future<void> syncRoomMembers(String roomId, {bool forceSync = false}) async {
    await _syncRoomMembersIfNeeded(roomId, forceSync: forceSync);
  }

  /// Replace a provisional subscription with the real server-assigned one.
  ///
  /// Looks up `provisional_<roomId>` in the local DB. If found, uses the
  /// profileId/contactId from it to find the real subscription, then:
  /// 1. Updates all messages' senderId from provisional → real
  /// 2. Removes the provisional subscription record
  /// 3. Marks the room as ready with the real subscription
  ///
  /// Returns true if a replacement was performed.
  Future<bool> _replaceProvisionalSubscription(String roomId) async {
    final provisionalId = 'provisional_$roomId';
    final provisional = await _roomSubscriptionRepository.getSubscription(
      provisionalId,
    );

    if (provisional == null) return false;

    final profileId = provisional.profileId ?? '';
    final contactId = provisional.contactId ?? '';

    if (contactId.isEmpty) {
      AppLogger.warning(
        'Provisional subscription has no contactId, cannot find real subscription',
        data: {'roomId': roomId},
      );
      return false;
    }

    // Look up the real subscription using the same profileId/contactId
    final realSubId = await _subscriptionService.getCurrentSubscriptionId(
      roomId,
      profileId,
      contactId,
    );

    if (realSubId == null || realSubId == provisionalId) {
      AppLogger.debug(
        'No real subscription found yet for room',
        data: {'roomId': roomId},
      );
      return false;
    }

    // 1. Update messages that used the provisional ID as senderId
    final updated = await _messageRepo.updateSenderIdForRoom(
      roomId,
      provisionalId,
      realSubId,
    );

    // 2. Remove the provisional subscription record
    await _roomSubscriptionRepository.removeSubscription(provisionalId);

    // 3. Mark room as ready with the real subscription
    _roomSyncManager.markReady(roomId, realSubId);

    AppLogger.info(
      'Provisional subscription replaced with real one',
      data: {
        'roomId': roomId,
        'provisionalId': provisionalId,
        'realSubId': realSubId.substring(
          0,
          realSubId.length < 8 ? realSubId.length : 8,
        ),
        'messagesUpdated': updated,
      },
    );

    return true;
  }

  /// Sync all rooms that need it after a successful connection.
  ///
  /// This handles rooms that were created offline (still have provisional
  /// subscriptions) or rooms that failed to sync before disconnection.
  Future<void> _performPostConnectionSync() async {
    if (_isPostConnectionSyncing) return;
    _isPostConnectionSyncing = true;
    try {
      final rooms = await _roomRepository.getAllRooms();
      var syncedCount = 0;
      var failedCount = 0;

      for (final room in rooms) {
        final status = _roomSyncManager.getStatus(room.id);

        // Sync rooms that:
        // 1. Have no status tracked yet (unknown state)
        // 2. Are not in READY state
        // 3. Have a provisional subscription
        final needsSync =
            status == null ||
            status.state != RoomSyncState.ready ||
            status.isProvisional;

        if (!needsSync) continue;

        try {
          await _syncRoomMembers(room.id);

          // Replace provisional subscription if one exists
          final replaced = await _replaceProvisionalSubscription(room.id);

          if (!replaced) {
            // No provisional to replace, just mark sync complete
            await _roomSyncManager.onApiSyncComplete(room.id);
          }

          syncedCount++;
        } catch (e) {
          failedCount++;
          AppLogger.debug(
            'Post-connection sync failed for room',
            data: {'roomId': room.id, 'error': e.toString()},
          );
        }
      }

      if (syncedCount > 0 || failedCount > 0) {
        AppLogger.info(
          'Post-connection sync complete',
          data: {'synced': syncedCount, 'failed': failedCount},
        );
      }
    } catch (e, stackTrace) {
      // Post-connection sync failure should never crash the engine
      AppLogger.warning(
        'Post-connection sync failed',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isPostConnectionSyncing = false;
    }
  }

  /// Check if a SUBSCRIPTION ID belongs to the current profile's contact
  /// Used to verify if incoming events are from the current profile
  ///
  /// @param roomId The room context
  /// @param subscriptionId The subscription ID to check (room-specific)
  /// @return true if this subscription belongs to current profile's contact
  ///
  /// Note: This method will return false for anonymous subscriptions (no contact ID)
  Future<bool> isCurrentUserSubscription(
    String roomId,
    String subscriptionId,
  ) async {
    final currentProfileId = await _authRepository.getCurrentProfileId();
    final currentContactId = await _authRepository.getCurrentContactId();
    if (currentContactId == null) return false;

    // Use repository to check if this subscription belongs to current profile's contact
    // Pass empty string for profileId if null to handle anonymous subscriptions
    return _roomSubscriptionRepository.isCurrentUserSubscription(
      roomId,
      subscriptionId,
      currentProfileId ?? '', // Empty string for anonymous subscriptions
      currentContactId,
    );
  }

  /// Update profile ID for an existing subscription
  /// Used when a user authenticates and their profile ID becomes known
  ///
  /// @param id The room subscription to update
  /// @param profileId The profile ID to associate with this subscription
  /// @param contactId Optional contact ID used for this subscription
  /// @return true if update was successful, false if subscription not found
  Future<bool> updateSubscriptionProfile({
    required String id,
    required String profileId,
    String? contactId,
  }) async => _subscriptionService.updateSubscriptionProfile(
    id: id,
    profileId: profileId,
    contactId: contactId,
  );

  /// Get all subscriptions without a profile ID (anonymous subscriptions)
  /// Useful for finding subscriptions that need profile assignment
  ///
  /// @param roomId Optional room filter
  /// @return List of anonymous subscriptions
  Future<List<RoomSubscription>> getAnonymousSubscriptions({
    String? roomId,
  }) async => _subscriptionService.getAnonymousSubscriptions(roomId: roomId);

  /// Send typing event to server
  ///
  /// If subscription is not found locally, attempts to sync room members
  /// and retry before giving up.
  Future<void> sendTyping(String roomId, bool isTyping) async {
    try {
      // Get current profile's subscription ID with sync fallback
      final subscriptionId = await getCurrentSubscriptionId(
        roomId,
        syncIfMissing: true,
        maxRetries: 1, // Single retry for typing (low priority)
      );

      if (subscriptionId == null) {
        // Even after sync, subscription not found - user may not be in room
        AppLogger.debug(
          'Cannot send typing event: subscription not found after sync',
          data: {'roomId': roomId},
        );
        return;
      }

      // Create typing event
      final typingEvent = pb.TypingEvent(
        subscriptionId: subscriptionId,
        roomId: roomId,
        typing: isTyping,
        since: common_types.Timestamp.fromDateTime(DateTime.now()),
      );

      // Wrap in ClientCommand
      final command = pb.ClientCommand(typing: typingEvent);

      // Send via existing bidirectional stream
      final request = pb.StreamRequest(command: command);
      if (_sendRequest(request)) {
        AppLogger.debug(
          'Typing event sent',
          data: {'roomId': roomId, 'typing': isTyping},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to send typing event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send read receipts for messages
  ///
  /// If subscription is not found locally, attempts to sync room members
  /// and retry before giving up.
  Future<void> sendReadReceipts(String roomId, List<String> messageIds) async {
    try {
      // Get current profile's subscription ID with sync fallback
      final subscriptionId = await getCurrentSubscriptionId(
        roomId,
        syncIfMissing: true,
        maxRetries: 1, // Single retry for read receipts (low priority)
      );

      if (subscriptionId == null) {
        // Even after sync, subscription not found - user may not be in room
        AppLogger.debug(
          'Cannot send read receipts: subscription not found after sync',
          data: {'roomId': roomId},
        );
        return;
      }

      // For read receipts, we send the latest message ID as upToEventId
      // This marks all messages up to and including this one as read
      if (messageIds.isEmpty) return;

      final latestMessageId = messageIds.last; // Assuming messages are ordered

      // Create read marker event
      final readEvent = pb.ReadMarker(
        subscriptionId: subscriptionId,
        roomId: roomId,
        upToEventId: latestMessageId,
      );

      // Wrap in ClientCommand
      final command = pb.ClientCommand(readMarker: readEvent);

      // Send via existing bidirectional stream
      final request = pb.StreamRequest(command: command);
      if (_sendRequest(request)) {
        AppLogger.debug(
          'Read receipt sent',
          data: {'roomId': roomId, 'upToEventId': latestMessageId},
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to send read receipts',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send message immediately through live connection
  /// Falls back to job queue if connection is not available
  ///
  /// If subscription is not found locally, attempts to sync room members
  /// and retry before failing.
  Future<void> sendMessageDirect(domain.RoomEvent event) async {
    if (!_isConnected) {
      throw Exception('Not connected to server');
    }

    try {
      // Get current profile's subscription ID with sync fallback
      final subscriptionId = await getCurrentSubscriptionId(
        event.roomId,
        syncIfMissing: true,
      );

      if (subscriptionId == null) {
        throw Exception('Subscription not found for room ${event.roomId}');
      }

      // Create timestamp
      final now = DateTime.now();
      final timestamp = common_types.Timestamp.fromDateTime(now);

      // Create payload based on event type
      final pbPayload = pb.Payload();
      switch (event.type) {
        case domain.RoomEventType.text:
          final textContent = event.content['text'] as String? ?? '';
          pbPayload.text = pb.TextContent(body: textContent, format: 'plain');
          break;
        case domain.RoomEventType.image:
          final imageUrl = event.content['url'] as String? ?? '';
          final imageData = {'url': imageUrl, 'type': 'image'};
          pbPayload.text = pb.TextContent(
            body: imageData.toString(),
            format: 'plain',
          );
          break;
        case domain.RoomEventType.file:
          final fileUrl = event.content['url'] as String? ?? '';
          final fileName = event.content['name'] as String? ?? '';
          final fileData = {'url': fileUrl, 'name': fileName, 'type': 'file'};
          pbPayload.text = pb.TextContent(
            body: fileData.toString(),
            format: 'plain',
          );
          break;
        default:
          throw Exception('Unsupported event type: ${event.type}');
      }

      // Create room event
      final roomEvent = pb.RoomEvent(
        id: event.localId ?? event.id,
        roomId: event.roomId,
        subscriptionId: subscriptionId,
        type: _mapLocalEventTypeToProto(event.type),
        sentAt: timestamp,
        payload: pbPayload,
      );

      // Wrap in ClientCommand
      final command = pb.ClientCommand(event: roomEvent);

      // Send via existing bidirectional stream
      final request = pb.StreamRequest(command: command);
      if (!_sendRequest(request)) {
        throw Exception('Failed to send message: stream not connected');
      }

      // Note: Do NOT mark as 'sent' here. This is fire-and-forget over the stream.
      // The message stays as 'pending' until the server echo arrives via
      // _processPbRoomEvent, which will advance it to 'delivered'.
      // This prevents marking lost messages as 'sent'.

      AppLogger.debug(
        'Message pushed to live connection stream',
        data: {'eventId': event.id, 'roomId': event.roomId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to send message via live connection',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Re-throw so caller can handle fallback
    }
  }
}
