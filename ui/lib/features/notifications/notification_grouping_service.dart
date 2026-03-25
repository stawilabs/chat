import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';

/// Provider for NotificationGroupingService
final notificationGroupingServiceProvider =
    Provider<NotificationGroupingService>(
      (ref) => NotificationGroupingService(),
    );

/// Provider for initializing the notification grouping service
final notificationGroupingInitializedProvider = FutureProvider<bool>((
  ref,
) async {
  final service = ref.watch(notificationGroupingServiceProvider);
  await service.initialize();
  return true;
});

/// Represents a grouped notification message
class GroupedMessage {
  const GroupedMessage({
    required this.id,
    required this.roomId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });

  final String id;
  final String roomId;
  final String senderName;
  final String message;
  final DateTime timestamp;
}

/// Configuration for a notification channel (Android)
class NotificationChannelConfig {
  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    this.importance = Importance.high,
    this.playSound = true,
    this.enableVibration = true,
  });

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final bool playSound;
  final bool enableVibration;
}

/// Service for managing grouped notifications across platforms
///
/// Features:
/// - Groups multiple messages from the same chat into a single notification
/// - Shows "X new messages" summary for groups
/// - Supports expand to see individual messages
/// - Android: Uses notification channels per chat for granular control
/// - iOS: Uses thread identifiers for native grouping
/// - Clears all notifications in a group on tap
///
/// Example:
/// ```dart
/// final groupingService = ref.read(notificationGroupingServiceProvider);
/// await groupingService.initialize();
///
/// // Show a message notification (will be grouped with other messages from same room)
/// await groupingService.showMessageNotification(
///   roomId: 'room-123',
///   roomName: 'Team Chat',
///   senderName: 'Alice',
///   message: 'Hello everyone!',
/// );
/// ```
class NotificationGroupingService {
  NotificationGroupingService();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Cache for room ID to notification ID mappings to ensure uniqueness
  final Map<String, int> _roomNotificationIds = {};

  /// Counter for generating unique notification IDs
  int _nextNotificationId = 1;

  bool _initialized = false;

  /// Default notification channel for general messages
  static const String _defaultChannelId = 'chat_messages';
  static const String _defaultChannelName = 'Chat Messages';
  static const String _defaultChannelDescription =
      'Notifications for chat messages';

  /// Group key prefix for Android notification groups
  static const String _groupKeyPrefix = 'com.antinvestor.chat.room.';

  /// Summary notification ID offset (to avoid collision with message IDs)
  static const int _summaryNotificationIdOffset = 1000000;

  /// Tracks pending messages per room for grouping
  final Map<String, List<GroupedMessage>> _pendingMessages = {};

  /// Maps room IDs to notification channel IDs (Android)
  final Map<String, String> _roomChannelMap = {};

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the notification grouping service
  ///
  /// Sets up the notification plugin with platform-specific configurations.
  /// Should be called after app startup and before showing notifications.
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.debug('NotificationGroupingService already initialized');
      return;
    }

    if (!isSupported) {
      AppLogger.debug(
        'NotificationGroupingService not supported on this platform',
      );
      _initialized = true;
      return;
    }

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings();

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      // Initialize the plugin
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      // Create default notification channel (Android)
      if (Platform.isAndroid) {
        await _createDefaultChannel();
      }

      _initialized = true;
      AppLogger.info('NotificationGroupingService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize NotificationGroupingService',
        error: e,
        stackTrace: stackTrace,
      );
      // Mark as initialized to prevent repeated attempts
      _initialized = true;
    }
  }

  /// Create the default notification channel for Android
  Future<void> _createDefaultChannel() async {
    const channel = AndroidNotificationChannel(
      _defaultChannelId,
      _defaultChannelName,
      description: _defaultChannelDescription,
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    AppLogger.debug('Created default notification channel');
  }

  /// Create a notification channel for a specific room (Android)
  ///
  /// This allows users to customize notifications per chat.
  Future<void> createRoomChannel({
    required String roomId,
    required String roomName,
  }) async {
    if (!Platform.isAndroid) return;

    final channelId = 'chat_room_$roomId';
    _roomChannelMap[roomId] = channelId;

    final channel = AndroidNotificationChannel(
      channelId,
      roomName,
      description: 'Notifications for $roomName',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    AppLogger.debug(
      'Created notification channel for room',
      data: {'roomId': roomId, 'channelId': channelId},
    );
  }

  /// Delete a notification channel for a room (Android)
  ///
  /// Should be called when a user leaves a room.
  Future<void> deleteRoomChannel(String roomId) async {
    if (!Platform.isAndroid) return;

    final channelId = _roomChannelMap[roomId];
    if (channelId == null) return;

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.deleteNotificationChannel(channelId: channelId);

    _roomChannelMap.remove(roomId);

    AppLogger.debug(
      'Deleted notification channel for room',
      data: {'roomId': roomId},
    );
  }

  /// Show a message notification
  ///
  /// Messages from the same room are automatically grouped together.
  /// Android uses notification groups with a summary.
  /// iOS uses thread identifiers for native grouping.
  Future<void> showMessageNotification({
    required String roomId,
    required String roomName,
    required String senderName,
    required String message,
    String? messageId,
  }) async {
    if (!isSupported || !_initialized) return;

    try {
      final now = DateTime.now();
      final groupedMessage = GroupedMessage(
        id: messageId ?? '${roomId}_${now.millisecondsSinceEpoch}',
        roomId: roomId,
        senderName: senderName,
        message: message,
        timestamp: now,
      );

      // Add to pending messages for this room
      _pendingMessages.putIfAbsent(roomId, () => []);
      _pendingMessages[roomId]!.add(groupedMessage);

      // Get channel ID for this room (Android)
      final channelId = _roomChannelMap[roomId] ?? _defaultChannelId;

      // Generate unique notification ID for this room
      final notificationId = _getOrCreateNotificationId(roomId);

      // Build notification details
      final androidDetails = await _buildAndroidNotificationDetails(
        channelId: channelId,
        roomId: roomId,
        roomName: roomName,
        messages: _pendingMessages[roomId]!,
      );

      final iosDetails = _buildIOSNotificationDetails(
        roomId: roomId,
        roomName: roomName,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
        macOS: iosDetails,
      );

      // Build notification content
      final messageCount = _pendingMessages[roomId]!.length;
      final String title;
      final String body;

      if (messageCount == 1) {
        // Single message - show sender and message
        title = '$senderName ($roomName)';
        body = message;
      } else {
        // Multiple messages - show summary
        title = roomName;
        body = '$messageCount new messages';
      }

      // Show the notification
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: roomId,
      );

      // On Android, also show/update summary notification
      if (Platform.isAndroid && messageCount > 1) {
        await _showSummaryNotification(
          roomId: roomId,
          roomName: roomName,
          channelId: channelId,
          messageCount: messageCount,
        );
      }

      AppLogger.debug(
        'Showed message notification',
        data: {
          'roomId': roomId,
          'messageCount': messageCount,
          'notificationId': notificationId,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to show message notification',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Build Android notification details with grouping support
  Future<AndroidNotificationDetails> _buildAndroidNotificationDetails({
    required String channelId,
    required String roomId,
    required String roomName,
    required List<GroupedMessage> messages,
  }) async {
    final groupKey = '$_groupKeyPrefix$roomId';

    // Build inbox style for multiple messages
    InboxStyleInformation? inboxStyle;
    if (messages.length > 1) {
      final lines = messages
          .take(5) // Show up to 5 most recent messages
          .map((m) => '${m.senderName}: ${m.message}')
          .toList();

      final summaryText = '${messages.length} new messages';

      inboxStyle = InboxStyleInformation(
        lines,
        contentTitle: roomName,
        summaryText: summaryText,
      );
    }

    return AndroidNotificationDetails(
      channelId,
      _roomChannelMap.containsKey(roomId) ? roomName : _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
      styleInformation: inboxStyle,
      category: AndroidNotificationCategory.message,
    );
  }

  /// Build iOS notification details with thread identifier for grouping
  DarwinNotificationDetails _buildIOSNotificationDetails({
    required String roomId,
    required String roomName,
  }) {
    return DarwinNotificationDetails(
      threadIdentifier: roomId,
      categoryIdentifier: 'chat_message',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  /// Show summary notification for Android group
  Future<void> _showSummaryNotification({
    required String roomId,
    required String roomName,
    required String channelId,
    required int messageCount,
  }) async {
    final groupKey = '$_groupKeyPrefix$roomId';
    final summaryId = _getSummaryNotificationId(roomId);

    final messages = _pendingMessages[roomId] ?? [];
    final lines = messages
        .take(5)
        .map((m) => '${m.senderName}: ${m.message}')
        .toList();

    final inboxStyle = InboxStyleInformation(
      lines,
      contentTitle: roomName,
      summaryText: '$messageCount new messages',
    );

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _roomChannelMap.containsKey(roomId) ? roomName : _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
      setAsGroupSummary: true,
      styleInformation: inboxStyle,
      category: AndroidNotificationCategory.message,
    );

    await _notificationsPlugin.show(
      id: summaryId,
      title: roomName,
      body: '$messageCount new messages',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: roomId,
    );
  }

  /// Get or create a unique notification ID for a room
  ///
  /// This ensures each room gets a consistent, unique notification ID
  /// without relying on hashCode which can cause collisions.
  int _getOrCreateNotificationId(String roomId) {
    if (_roomNotificationIds.containsKey(roomId)) {
      return _roomNotificationIds[roomId]!;
    }

    // Generate a new unique ID for this room
    final id = _nextNotificationId;
    _nextNotificationId++;

    // Ensure we don't exceed the summary offset range
    if (_nextNotificationId >= _summaryNotificationIdOffset) {
      _nextNotificationId = 1;
    }

    _roomNotificationIds[roomId] = id;
    return id;
  }

  /// Get the summary notification ID for a room
  int _getSummaryNotificationId(String roomId) {
    return _getOrCreateNotificationId(roomId) + _summaryNotificationIdOffset;
  }

  /// Clear all notifications for a specific room
  ///
  /// This should be called when the user opens the chat room
  /// to clear all related notifications.
  Future<void> clearRoomNotifications(String roomId) async {
    if (!isSupported || !_initialized) return;

    try {
      // Clear pending messages for this room
      _pendingMessages.remove(roomId);

      // Cancel the main notification using our tracked ID
      final notificationId = _roomNotificationIds[roomId];
      if (notificationId != null) {
        await _notificationsPlugin.cancel(id: notificationId);

        // Cancel the summary notification (Android)
        if (Platform.isAndroid) {
          final summaryId = notificationId + _summaryNotificationIdOffset;
          await _notificationsPlugin.cancel(id: summaryId);
        }
      }

      AppLogger.debug(
        'Cleared notifications for room',
        data: {'roomId': roomId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear room notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    if (!isSupported || !_initialized) return;

    try {
      _pendingMessages.clear();
      await _notificationsPlugin.cancelAll();
      AppLogger.debug('Cleared all notifications');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear all notifications',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get the number of pending messages for a room
  int getPendingMessageCount(String roomId) {
    return _pendingMessages[roomId]?.length ?? 0;
  }

  /// Get total pending message count across all rooms
  int get totalPendingMessageCount {
    return _pendingMessages.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final roomId = response.payload;
    if (roomId != null) {
      AppLogger.info(
        'Notification tapped',
        data: {'roomId': roomId, 'actionId': response.actionId},
      );

      // Clear notifications for this room
      clearRoomNotifications(roomId);

      // Navigation will be handled by the notification service
      // which listens to this tap event
    }
  }

  /// Handle notification tapped when app is in background or terminated
  /// Note: This must be a static/top-level function
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Background handling - will be picked up when app starts
    // The roomId is in the payload for navigation
  }

  /// Check if notification grouping is supported on the current platform
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Dispose resources
  void dispose() {
    _pendingMessages.clear();
    _roomChannelMap.clear();
    _roomNotificationIds.clear();
    _nextNotificationId = 1;
    _initialized = false;
    AppLogger.debug('NotificationGroupingService disposed');
  }
}
