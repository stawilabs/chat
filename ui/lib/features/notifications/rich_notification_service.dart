import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/logging/app_logger.dart';
import '../../core/settings/settings_service.dart';
import '../messages/domain/room_event.dart';
import 'notification_content_formatter.dart';

/// Notification action identifiers
class NotificationActions {
  static const String reply = 'reply_action';
  static const String markAsRead = 'mark_as_read_action';
  static const String answerCall = 'answer_call';
  static const String declineCall = 'decline_call';
}

/// Notification channel configuration
class NotificationChannels {
  static const String messagesId = 'messages_channel';
  static const String messagesName = 'Messages';
  static const String messagesDescription = 'Notifications for new messages';

  static const String callsId = 'calls_channel';
  static const String callsName = 'Calls';
  static const String callsDescription = 'Notifications for incoming calls';

  static const String groupsId = 'groups_channel';
  static const String groupsName = 'Group Messages';
  static const String groupsDescription = 'Notifications for group messages';
}

/// Callback type for notification action handlers
typedef NotificationActionCallback =
    void Function(String actionId, String? roomId, String? payload);

/// Callback type for notification tap handlers
typedef NotificationTapCallback =
    void Function(String? roomId, String? roomName);

/// Provider for RichNotificationService
final richNotificationServiceProvider = Provider<RichNotificationService>(
  RichNotificationService.new,
);

/// Service for displaying rich local notifications
///
/// Features:
/// - Text message preview (truncated at 100 chars)
/// - Image thumbnails for image messages
/// - Voice message duration display
/// - Sender name and avatar
/// - Group name for group messages
/// - Reply action from notification
/// - Mark as read action
/// - Privacy setting to hide content
class RichNotificationService {
  RichNotificationService(this._ref);

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationContentFormatter _formatter =
      NotificationContentFormatter();

  bool _initialized = false;
  NotificationActionCallback? _onAction;
  NotificationTapCallback? _onTap;

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the rich notification service
  ///
  /// Must be called before showing any notifications.
  /// Sets up notification channels and action handlers.
  Future<void> initialize({
    NotificationActionCallback? onAction,
    NotificationTapCallback? onTap,
  }) async {
    if (_initialized) {
      AppLogger.debug('RichNotificationService already initialized');
      return;
    }

    _onAction = onAction;
    _onTap = onTap;

    try {
      // Initialize settings for Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // Initialize settings for iOS
      final darwinSettings = DarwinInitializationSettings(
        notificationCategories: _createDarwinNotificationCategories(),
      );

      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );

      // Create Android notification channels
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannels();
      }

      _initialized = true;
      AppLogger.info('RichNotificationService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize RichNotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Create Darwin (iOS/macOS) notification categories with actions
  List<DarwinNotificationCategory> _createDarwinNotificationCategories() {
    return [
      DarwinNotificationCategory(
        'message_category',
        actions: [
          DarwinNotificationAction.text(
            NotificationActions.reply,
            'Reply',
            buttonTitle: 'Send',
            placeholder: 'Type a message...',
          ),
          DarwinNotificationAction.plain(
            NotificationActions.markAsRead,
            'Mark as Read',
          ),
        ],
        options: {DarwinNotificationCategoryOption.hiddenPreviewShowTitle},
      ),
    ];
  }

  /// Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Messages channel - high importance for immediate attention
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.messagesId,
        NotificationChannels.messagesName,
        description: NotificationChannels.messagesDescription,
        importance: Importance.high,
      ),
    );

    // Calls channel - max importance for critical alerts
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.callsId,
        NotificationChannels.callsName,
        description: NotificationChannels.callsDescription,
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('ringtone'),
      ),
    );

    // Groups channel - default importance
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.groupsId,
        NotificationChannels.groupsName,
        description: NotificationChannels.groupsDescription,
        importance: Importance.high,
      ),
    );

    AppLogger.debug('Android notification channels created');
  }

  /// Handle notification response (tap or action)
  void _onNotificationResponse(NotificationResponse response) {
    AppLogger.info(
      'Notification response received',
      data: {
        'actionId': response.actionId,
        'payload': response.payload,
        'input': response.input,
      },
    );

    final payload = response.payload;
    final roomId = _extractRoomId(payload);
    final roomName = _extractRoomName(payload);

    if (response.actionId != null) {
      // Handle action button tap
      // For reply actions, pass the input text; for other actions, pass the payload
      _onAction?.call(
        response.actionId!,
        roomId,
        response.actionId == NotificationActions.reply
            ? response.input
            : payload,
      );
    } else {
      // Handle notification tap
      _onTap?.call(roomId, roomName);
    }
  }

  /// Extract room ID from payload
  String? _extractRoomId(String? payload) {
    if (payload == null) return null;
    // Payload format: "roomId:roomName" or just "roomId"
    final parts = payload.split(':');
    return parts.isNotEmpty ? parts[0] : null;
  }

  /// Extract room name from payload
  String? _extractRoomName(String? payload) {
    if (payload == null) return null;
    final parts = payload.split(':');
    return parts.length > 1 ? parts[1] : null;
  }

  /// Show a rich notification for a room event
  ///
  /// [event] - The room event to show notification for
  /// [senderName] - Display name of the sender
  /// [senderAvatarUrl] - URL to sender's avatar image
  /// [roomName] - Name of the room (for group messages, null for DMs)
  /// [roomId] - ID of the room for navigation
  Future<void> showMessageNotification({
    required RoomEvent event,
    required String senderName,
    required String roomId,
    String? senderAvatarUrl,
    String? roomName,
  }) async {
    if (!_initialized) {
      AppLogger.warning('RichNotificationService not initialized');
      return;
    }

    // Check if notifications are enabled and get privacy setting
    final settingsService = _ref.read(settingsServiceProvider);
    final hideContent = !settingsService.notificationPreviewEnabled;

    // Format notification content
    final content = _formatter.format(
      event: event,
      senderName: senderName,
      roomName: roomName,
      hideContent: hideContent,
    );

    // Generate unique notification ID from event ID
    final notificationId = event.id.hashCode;

    // Build platform-specific notification details
    final androidDetails = await _buildAndroidNotificationDetails(
      content: content,
      senderAvatarUrl: senderAvatarUrl,
      isGroupMessage: content.isGroupMessage,
    );

    final darwinDetails = _buildDarwinNotificationDetails(content: content);

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    // Payload for handling notification tap/action
    final payload = '$roomId:${roomName ?? ''}';

    await _localNotifications.show(
      id: notificationId,
      title: content.title,
      body: content.body,
      notificationDetails: notificationDetails,
      payload: payload,
    );

    AppLogger.debug(
      'Rich notification shown',
      data: {
        'eventId': event.id,
        'title': content.title,
        'hasImage': content.imageUrl != null,
      },
    );
  }

  /// Build Android-specific notification details
  Future<AndroidNotificationDetails> _buildAndroidNotificationDetails({
    required NotificationContent content,
    String? senderAvatarUrl,
    bool isGroupMessage = false,
  }) async {
    // Try to fetch sender avatar for large icon
    ByteArrayAndroidBitmap? largeIcon;
    if (senderAvatarUrl != null) {
      largeIcon = await _fetchImageAsBitmap(senderAvatarUrl);
    }

    // Try to fetch image for big picture style
    ByteArrayAndroidBitmap? bigPicture;
    if (content.imageUrl != null) {
      bigPicture = await _fetchImageAsBitmap(content.imageUrl!);
    }

    // Determine style based on content
    StyleInformation? styleInformation;
    if (bigPicture != null) {
      styleInformation = BigPictureStyleInformation(
        bigPicture,
        largeIcon: largeIcon,
        contentTitle: content.title,
        summaryText: content.body,
        hideExpandedLargeIcon: true,
      );
    } else {
      styleInformation = BigTextStyleInformation(
        content.body,
        contentTitle: content.title,
      );
    }

    // Select appropriate channel
    final channelId = isGroupMessage
        ? NotificationChannels.groupsId
        : NotificationChannels.messagesId;

    return AndroidNotificationDetails(
      channelId,
      isGroupMessage
          ? NotificationChannels.groupsName
          : NotificationChannels.messagesName,
      channelDescription: isGroupMessage
          ? NotificationChannels.groupsDescription
          : NotificationChannels.messagesDescription,
      importance: Importance.high,
      priority: Priority.high,
      largeIcon: largeIcon,
      styleInformation: styleInformation,
      category: AndroidNotificationCategory.message,
      actions: [
        const AndroidNotificationAction(
          NotificationActions.reply,
          'Reply',
          inputs: [AndroidNotificationActionInput(label: 'Type a message...')],
        ),
        const AndroidNotificationAction(
          NotificationActions.markAsRead,
          'Mark as Read',
        ),
      ],
    );
  }

  /// Build Darwin (iOS/macOS) notification details
  DarwinNotificationDetails _buildDarwinNotificationDetails({
    required NotificationContent content,
  }) {
    return DarwinNotificationDetails(
      categoryIdentifier: 'message_category',
      threadIdentifier: content.title, // Group by sender/room
      attachments: content.imageUrl != null
          ? [DarwinNotificationAttachment(content.imageUrl!)]
          : null,
    );
  }

  /// Fetch an image from URL and convert to Android bitmap
  Future<ByteArrayAndroidBitmap?> _fetchImageAsBitmap(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      AppLogger.debug('Failed to fetch image for notification: $url');
    }
    return null;
  }

  /// Show a call notification
  Future<void> showCallNotification({
    required String callerName,
    required String roomId,
    String? callerAvatarUrl,
    bool isVideoCall = false,
  }) async {
    if (!_initialized) {
      AppLogger.warning('RichNotificationService not initialized');
      return;
    }

    final notificationId = roomId.hashCode;

    ByteArrayAndroidBitmap? largeIcon;
    if (callerAvatarUrl != null) {
      largeIcon = await _fetchImageAsBitmap(callerAvatarUrl);
    }

    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.callsId,
      NotificationChannels.callsName,
      channelDescription: NotificationChannels.callsDescription,
      importance: Importance.max,
      priority: Priority.max,
      largeIcon: largeIcon,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      actions: [
        const AndroidNotificationAction(
          NotificationActions.answerCall,
          'Answer',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          NotificationActions.declineCall,
          'Decline',
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'call_category',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _localNotifications.show(
      id: notificationId,
      title: isVideoCall ? 'Incoming Video Call' : 'Incoming Call',
      body: callerName,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: roomId,
    );
  }

  /// Cancel a notification by room ID
  Future<void> cancelNotification(String roomId) async {
    await _localNotifications.cancel(id: roomId.hashCode);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Check if notifications are supported on the current platform
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
}

/// Background notification response handler - must be top-level function
@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  AppLogger.info(
    'Background notification response',
    data: {'actionId': response.actionId, 'payload': response.payload},
  );
  // Background handling is limited - will be processed when app opens
}
