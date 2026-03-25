import 'dart:io' show Platform;

import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    as common_pb;
import 'package:antinvestor_api_device/antinvestor_api_device.dart' as pb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/networking/client.dart';
import '../../core/storage/key_manager.dart';
import '../settings/data/settings_providers.dart';
import 'mute_service.dart';
import 'notification_grouping_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase may not be configured - skip background handling
    return;
  }

  AppLogger.info(
    'Background message received',
    data: {'messageId': message.messageId, 'data': message.data},
  );

  // Background handling is limited - just log for now
  // Full handling happens when app is opened
}

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>(
  NotificationService.new,
);

/// Service for handling push notifications via Firebase Cloud Messaging
///
/// Manages:
/// - Firebase initialization
/// - FCM token retrieval and registration with backend
/// - Foreground notification handling
/// - Background notification handling
/// - Deep linking from notification taps
class NotificationService {
  NotificationService(this._ref);
  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;
  bool _initialized = false;

  /// Reference to the notification grouping service for local notifications
  NotificationGroupingService? _groupingService;

  /// Whether the notification service has been initialized
  bool get isInitialized => _initialized;

  /// Current FCM token (null if not yet retrieved)
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  ///
  /// Should be called after Firebase.initializeApp() and user authentication.
  /// This method does NOT request permission - it only sets up FCM if permission
  /// is already granted. Use [initializeAfterPermissionGranted] after the user
  /// grants permission via the NotificationPermissionDialog.
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug('NotificationService already initialized');
      return;
    }

    try {
      // Check current permission status without requesting
      final settings = await _messaging.getNotificationSettings();

      if (settings.authorizationStatus == AuthorizationStatus.denied ||
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        AppLogger.info(
          'Notification permission not granted, deferring FCM setup',
          data: {'status': settings.authorizationStatus.name},
        );
        // Setup message handlers anyway for when permission is granted later
        _setupMessageHandlers();
        return;
      }

      // Permission already granted - complete initialization
      await _completeInitialization();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Complete initialization after user grants notification permission
  ///
  /// Call this after the user grants notification permission via the dialog.
  Future<void> initializeAfterPermissionGranted() async {
    if (_initialized) {
      AppLogger.debug('NotificationService already initialized');
      return;
    }

    try {
      await _completeInitialization();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to complete NotificationService initialization',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Internal method to complete FCM initialization
  Future<void> _completeInitialization() async {
    // Get and register FCM token
    await _retrieveAndRegisterToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Setup message handlers (if not already setup)
    _setupMessageHandlers();

    // Initialize the grouping service for local notifications
    _groupingService = _ref.read(notificationGroupingServiceProvider);
    await _groupingService!.initialize();

    _initialized = true;
    AppLogger.info('NotificationService initialized successfully');
  }

  /// Retrieve FCM token and register it with the backend
  Future<void> _retrieveAndRegisterToken() async {
    try {
      _fcmToken = await _messaging.getToken();

      if (_fcmToken == null) {
        AppLogger.warning('Failed to retrieve FCM token');
        return;
      }

      AppLogger.debug(
        'FCM token retrieved',
        data: {'tokenPrefix': _fcmToken!.substring(0, 20)},
      );

      await _registerTokenWithBackend(_fcmToken!);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to retrieve/register FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle FCM token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    AppLogger.info('FCM token refreshed');
    _fcmToken = newToken;
    await _registerTokenWithBackend(newToken);
  }

  /// Register the FCM token with the backend Device API
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final keyManager = _ref.read(keyManagerProvider);
      final deviceId = await keyManager.getDeviceId();
      final deviceClient = await _ref.read(deviceServiceClientProvider.future);

      // Create extras struct with the FCM token
      final extras = common_pb.Struct();
      extras.fields['token'] = common_pb.Value(stringValue: token);

      final request = pb.RegisterKeyRequest(
        deviceId: deviceId,
        keyType: pb.KeyType.FCM_TOKEN,
        extras: extras,
      );

      await deviceClient.registerKey(request);

      AppLogger.info(
        'FCM token registered with backend',
        data: {'deviceId': deviceId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to register FCM token with backend',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Setup message handlers for foreground and background
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();
  }

  /// Check if app was opened from a notification when terminated
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.info('App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle foreground message - show as local notification or update UI
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info(
      'Foreground message received',
      data: {
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      },
    );

    // Show grouped local notification for foreground messages
    await _showGroupedNotification(message);
  }

  /// Show a grouped local notification for the received message
  ///
  /// Checks if the room is muted before showing the notification.
  /// If the room is muted, the notification is silently suppressed.
  Future<void> _showGroupedNotification(RemoteMessage message) async {
    if (_groupingService == null || !_groupingService!.isInitialized) {
      AppLogger.warning(
        'Grouping service not initialized, skipping notification',
      );
      return;
    }

    // Extract message data
    final roomId = message.data['roomId'] as String?;
    final roomName =
        message.data['roomName'] as String? ??
        message.notification?.title ??
        'Chat';
    final senderName = message.data['senderName'] as String? ?? 'Unknown';
    final messageText =
        message.data['message'] as String? ?? message.notification?.body ?? '';
    final messageId = message.messageId;

    if (roomId == null) {
      AppLogger.warning('No roomId in message data, cannot group notification');
      return;
    }

    // Check if the room is muted
    final muteService = _ref.read(muteServiceProvider);
    final isMuted = await muteService.isRoomMuted(roomId);

    if (isMuted) {
      AppLogger.debug(
        'Notification suppressed - room is muted',
        data: {'roomId': roomId, 'roomName': roomName},
      );
      return;
    }

    // Check global notification settings
    final settingsAsync = _ref.read(settingsProvider);
    final settings = settingsAsync.value ?? {};
    final messageNotificationsEnabled =
        settings['message_notifications'] ?? true;
    final groupNotificationsEnabled = settings['group_notifications'] ?? true;

    if (!messageNotificationsEnabled) {
      AppLogger.debug(
        'Notification suppressed - message notifications disabled',
      );
      return;
    }

    // Suppress group notifications if the setting is off and this is a group room
    final roomType = message.data['roomType'] as String?;
    if (!groupNotificationsEnabled && roomType == 'group') {
      AppLogger.debug('Notification suppressed - group notifications disabled');
      return;
    }

    // Show the grouped notification
    await _groupingService!.showMessageNotification(
      roomId: roomId,
      roomName: roomName,
      senderName: senderName,
      message: messageText,
      messageId: messageId,
    );
  }

  /// Handle notification tap - navigate to relevant screen
  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.info(
      'Notification tapped',
      data: {'messageId': message.messageId, 'data': message.data},
    );

    // Extract room ID from notification data
    final roomId = message.data['roomId'] as String?;
    final roomName = message.data['roomName'] as String?;

    if (roomId != null) {
      // Clear all grouped notifications for this room
      _groupingService?.clearRoomNotifications(roomId);
      _navigateToChat(roomId, roomName);
    }
  }

  /// Clear notifications for a specific room
  ///
  /// Should be called when the user opens a chat room to clear
  /// all related notifications (both from FCM and local grouped notifications).
  Future<void> clearRoomNotifications(String roomId) async {
    await _groupingService?.clearRoomNotifications(roomId);
  }

  /// Clear all notifications
  ///
  /// Should be called on logout or when the user wants to dismiss all notifications.
  Future<void> clearAllNotifications() async {
    await _groupingService?.clearAllNotifications();
  }

  /// Create a notification channel for a room (Android only)
  ///
  /// This allows users to customize notifications per chat.
  Future<void> createRoomChannel({
    required String roomId,
    required String roomName,
  }) async {
    await _groupingService?.createRoomChannel(
      roomId: roomId,
      roomName: roomName,
    );
  }

  /// Delete a notification channel for a room (Android only)
  ///
  /// Should be called when a user leaves a room.
  Future<void> deleteRoomChannel(String roomId) async {
    await _groupingService?.deleteRoomChannel(roomId);
  }

  /// Navigate to chat screen for a specific room
  void _navigateToChat(String roomId, String? roomName) {
    // Get the router from the provider
    // Note: This requires a navigation context, which we'll handle via a global key
    AppLogger.info(
      'Navigating to chat from notification',
      data: {'roomId': roomId, 'roomName': roomName},
    );

    // Deep link navigation will be handled by the app's navigation system
    // The route path is: /chat/:roomId?name=:roomName
  }

  /// Unregister FCM token from backend (call on logout)
  Future<void> unregisterToken() async {
    try {
      final keyManager = _ref.read(keyManagerProvider);
      final deviceId = await keyManager.getDeviceId();

      final deviceClient = await _ref.read(deviceServiceClientProvider.future);

      // Search for existing FCM key
      final searchRequest = pb.SearchKeyRequest(
        deviceId: deviceId,
        keyTypes: [pb.KeyType.FCM_TOKEN],
      );

      final searchResponse = await deviceClient.searchKey(searchRequest);

      // Deregister if found
      for (final key in searchResponse.data) {
        final deregisterRequest = pb.DeRegisterKeyRequest(id: key.id);
        await deviceClient.deRegisterKey(deregisterRequest);
      }

      _fcmToken = null;
      AppLogger.info('FCM token unregistered from backend');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to unregister FCM token',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if notifications are supported on the current platform
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;
}
