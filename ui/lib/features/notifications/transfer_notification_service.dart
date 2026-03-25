import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';

/// Notification channel configuration for transfers
class TransferNotificationChannels {
  static const String uploadsId = 'uploads_channel';
  static const String uploadsName = 'Uploads';
  static const String uploadsDescription =
      'Notifications for file upload progress';

  static const String downloadsId = 'downloads_channel';
  static const String downloadsName = 'Downloads';
  static const String downloadsDescription =
      'Notifications for file download progress';
}

/// Notification action identifiers for transfers
class TransferNotificationActions {
  static const String cancelUpload = 'cancel_upload';
  static const String cancelDownload = 'cancel_download';
  static const String pauseTransfer = 'pause_transfer';
  static const String resumeTransfer = 'resume_transfer';
  static const String retryTransfer = 'retry_transfer';
  static const String openFile = 'open_file';
}

/// Callback type for transfer notification action handlers
typedef TransferActionCallback =
    void Function(String actionId, String transferId);

/// Provider for TransferNotificationService
final transferNotificationServiceProvider =
    Provider<TransferNotificationService>((_) => TransferNotificationService());

/// Service for displaying transfer progress notifications
///
/// Shows progress notifications for file uploads and downloads with:
/// - Progress bar showing transfer progress
/// - Cancel action for active transfers
/// - Pause/resume actions for resumable transfers
/// - Retry action for failed transfers
/// - Open file action for completed downloads
///
/// Example:
/// ```dart
/// final service = ref.read(transferNotificationServiceProvider);
///
/// await service.initialize();
///
/// // Show upload progress
/// await service.showUploadProgress(
///   uploadId: 'upload-123',
///   fileName: 'photo.jpg',
///   progress: 0.45,
///   uploadedBytes: 460800,
///   totalBytes: 1024000,
/// );
///
/// // Show download complete
/// await service.showDownloadComplete(
///   downloadId: 'download-456',
///   fileName: 'document.pdf',
///   localPath: '/path/to/document.pdf',
/// );
/// ```
class TransferNotificationService {
  // ignore: unused_element_parameter
  TransferNotificationService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  TransferActionCallback? _onAction;

  /// Base notification IDs to avoid conflicts
  static const int _uploadNotificationIdBase = 100000;
  static const int _downloadNotificationIdBase = 200000;

  /// Whether the service has been initialized
  bool get isInitialized => _initialized;

  /// Initialize the transfer notification service
  ///
  /// Must be called before showing any notifications.
  /// Sets up notification channels for uploads and downloads.
  Future<void> initialize({TransferActionCallback? onAction}) async {
    if (_initialized) {
      AppLogger.debug('TransferNotificationService already initialized');
      return;
    }

    _onAction = onAction;

    try {
      // Initialize settings for Android
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // Initialize settings for iOS/macOS
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
      );

      // Create Android notification channels
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannels();
      }

      _initialized = true;
      AppLogger.info('TransferNotificationService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize TransferNotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Create Darwin (iOS/macOS) notification categories with actions
  List<DarwinNotificationCategory> _createDarwinNotificationCategories() {
    return [
      DarwinNotificationCategory(
        'transfer_category',
        actions: [
          DarwinNotificationAction.plain(
            TransferNotificationActions.cancelUpload,
            'Cancel',
            options: {DarwinNotificationActionOption.destructive},
          ),
        ],
      ),
      DarwinNotificationCategory(
        'download_complete_category',
        actions: [
          DarwinNotificationAction.plain(
            TransferNotificationActions.openFile,
            'Open',
          ),
        ],
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

    // Uploads channel - low importance (silent, progress only)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        TransferNotificationChannels.uploadsId,
        TransferNotificationChannels.uploadsName,
        description: TransferNotificationChannels.uploadsDescription,
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
        showBadge: false,
      ),
    );

    // Downloads channel - low importance (silent, progress only)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        TransferNotificationChannels.downloadsId,
        TransferNotificationChannels.downloadsName,
        description: TransferNotificationChannels.downloadsDescription,
        importance: Importance.low,
        enableVibration: false,
        playSound: false,
        showBadge: false,
      ),
    );

    AppLogger.debug('Transfer notification channels created');
  }

  /// Handle notification response (tap or action)
  void _onNotificationResponse(NotificationResponse response) {
    AppLogger.info(
      'Transfer notification response received',
      data: {'actionId': response.actionId, 'payload': response.payload},
    );

    final payload = response.payload;
    final actionId = response.actionId;

    if (payload != null && actionId != null) {
      _onAction?.call(actionId, payload);
    } else if (payload != null) {
      // Notification tapped (not an action button)
      // Could navigate to transfer details or open file
      _onAction?.call(TransferNotificationActions.openFile, payload);
    }
  }

  // ============================================================================
  // Upload Notifications
  // ============================================================================

  /// Show upload progress notification
  ///
  /// Updates an existing notification if one exists for the same uploadId.
  Future<void> showUploadProgress({
    required String uploadId,
    required String fileName,
    required double progress,
    required int uploadedBytes,
    required int totalBytes,
    bool showCancelAction = true,
  }) async {
    if (!_initialized) {
      AppLogger.warning('TransferNotificationService not initialized');
      return;
    }

    final notificationId = _getUploadNotificationId(uploadId);
    final progressPercent = (progress * 100).round();
    final formattedProgress = _formatBytes(uploadedBytes);
    final formattedTotal = _formatBytes(totalBytes);

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.uploadsId,
      TransferNotificationChannels.uploadsName,
      channelDescription: TransferNotificationChannels.uploadsDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      actions: showCancelAction
          ? [
              const AndroidNotificationAction(
                TransferNotificationActions.cancelUpload,
                'Cancel',
              ),
            ]
          : null,
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'transfer_category',
    );

    await _localNotifications.show(
      id: notificationId,
      title: 'Uploading $fileName',
      body: '$formattedProgress / $formattedTotal ($progressPercent%)',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: uploadId,
    );
  }

  /// Show upload complete notification
  Future<void> showUploadComplete({
    required String uploadId,
    required String fileName,
    int? totalBytes,
  }) async {
    if (!_initialized) return;

    final notificationId = _getUploadNotificationId(uploadId);
    final sizeText = totalBytes != null ? ' (${_formatBytes(totalBytes)})' : '';

    const androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.uploadsId,
      TransferNotificationChannels.uploadsName,
      channelDescription: TransferNotificationChannels.uploadsDescription,
    );

    const darwinDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: notificationId,
      title: 'Upload complete',
      body: '$fileName$sizeText',
      notificationDetails: const NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: uploadId,
    );
  }

  /// Show upload failed notification
  Future<void> showUploadFailed({
    required String uploadId,
    required String fileName,
    String? error,
    bool showRetryAction = true,
  }) async {
    if (!_initialized) return;

    final notificationId = _getUploadNotificationId(uploadId);
    final errorText = error != null ? ': $error' : '';

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.uploadsId,
      TransferNotificationChannels.uploadsName,
      channelDescription: TransferNotificationChannels.uploadsDescription,
      actions: showRetryAction
          ? [
              const AndroidNotificationAction(
                TransferNotificationActions.retryTransfer,
                'Retry',
              ),
            ]
          : null,
    );

    const darwinDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: notificationId,
      title: 'Upload failed',
      body: '$fileName$errorText',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: uploadId,
    );
  }

  /// Cancel upload notification
  Future<void> cancelUploadNotification(String uploadId) async {
    final notificationId = _getUploadNotificationId(uploadId);
    await _localNotifications.cancel(id: notificationId);
  }

  // ============================================================================
  // Download Notifications
  // ============================================================================

  /// Show download progress notification
  ///
  /// Updates an existing notification if one exists for the same downloadId.
  Future<void> showDownloadProgress({
    required String downloadId,
    required String fileName,
    required double progress,
    required int downloadedBytes,
    required int totalBytes,
    bool showCancelAction = true,
  }) async {
    if (!_initialized) {
      AppLogger.warning('TransferNotificationService not initialized');
      return;
    }

    final notificationId = _getDownloadNotificationId(downloadId);
    final progressPercent = (progress * 100).round();
    final formattedProgress = _formatBytes(downloadedBytes);
    final formattedTotal = _formatBytes(totalBytes);

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.downloadsId,
      TransferNotificationChannels.downloadsName,
      channelDescription: TransferNotificationChannels.downloadsDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      category: AndroidNotificationCategory.progress,
      actions: showCancelAction
          ? [
              const AndroidNotificationAction(
                TransferNotificationActions.cancelDownload,
                'Cancel',
              ),
            ]
          : null,
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'transfer_category',
    );

    await _localNotifications.show(
      id: notificationId,
      title: 'Downloading $fileName',
      body: '$formattedProgress / $formattedTotal ($progressPercent%)',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: downloadId,
    );
  }

  /// Show download complete notification
  Future<void> showDownloadComplete({
    required String downloadId,
    required String fileName,
    String? localPath,
    int? totalBytes,
  }) async {
    if (!_initialized) return;

    final notificationId = _getDownloadNotificationId(downloadId);
    final sizeText = totalBytes != null ? ' (${_formatBytes(totalBytes)})' : '';

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.downloadsId,
      TransferNotificationChannels.downloadsName,
      channelDescription: TransferNotificationChannels.downloadsDescription,
      actions: localPath != null
          ? [
              const AndroidNotificationAction(
                TransferNotificationActions.openFile,
                'Open',
              ),
            ]
          : null,
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'download_complete_category',
    );

    await _localNotifications.show(
      id: notificationId,
      title: 'Download complete',
      body: '$fileName$sizeText',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: localPath ?? downloadId,
    );
  }

  /// Show download failed notification
  Future<void> showDownloadFailed({
    required String downloadId,
    required String fileName,
    String? error,
    bool showRetryAction = true,
  }) async {
    if (!_initialized) return;

    final notificationId = _getDownloadNotificationId(downloadId);
    final errorText = error != null ? ': $error' : '';

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.downloadsId,
      TransferNotificationChannels.downloadsName,
      channelDescription: TransferNotificationChannels.downloadsDescription,
      actions: showRetryAction
          ? [
              const AndroidNotificationAction(
                TransferNotificationActions.retryTransfer,
                'Retry',
              ),
            ]
          : null,
    );

    const darwinDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: notificationId,
      title: 'Download failed',
      body: '$fileName$errorText',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      payload: downloadId,
    );
  }

  /// Cancel download notification
  Future<void> cancelDownloadNotification(String downloadId) async {
    final notificationId = _getDownloadNotificationId(downloadId);
    await _localNotifications.cancel(id: notificationId);
  }

  // ============================================================================
  // Summary Notifications
  // ============================================================================

  /// Show summary notification for multiple active transfers
  Future<void> showTransferSummary({
    required int uploadCount,
    required int downloadCount,
    required double overallProgress,
  }) async {
    if (!_initialized) return;

    final totalCount = uploadCount + downloadCount;
    if (totalCount == 0) {
      await cancelTransferSummary();
      return;
    }

    final progressPercent = (overallProgress * 100).round();
    final title = _buildSummaryTitle(uploadCount, downloadCount);

    final androidDetails = AndroidNotificationDetails(
      TransferNotificationChannels.uploadsId,
      TransferNotificationChannels.uploadsName,
      channelDescription: TransferNotificationChannels.uploadsDescription,
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      groupKey: 'transfers',
      setAsGroupSummary: true,
    );

    const darwinDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      id: 0,
      title: title,
      body: 'Overall progress: $progressPercent%',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
    );
  }

  /// Cancel transfer summary notification
  Future<void> cancelTransferSummary() async {
    await _localNotifications.cancel(id: 0);
  }

  /// Cancel all transfer notifications
  Future<void> cancelAllTransferNotifications() async {
    await _localNotifications.cancelAll();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Generate notification ID for an upload
  int _getUploadNotificationId(String uploadId) {
    return _uploadNotificationIdBase + uploadId.hashCode.abs() % 100000;
  }

  /// Generate notification ID for a download
  int _getDownloadNotificationId(String downloadId) {
    return _downloadNotificationIdBase + downloadId.hashCode.abs() % 100000;
  }

  /// Build summary notification title
  String _buildSummaryTitle(int uploadCount, int downloadCount) {
    final parts = <String>[];
    if (uploadCount > 0) {
      parts.add('$uploadCount upload${uploadCount > 1 ? "s" : ""}');
    }
    if (downloadCount > 0) {
      parts.add('$downloadCount download${downloadCount > 1 ? "s" : ""}');
    }
    return parts.join(', ');
  }

  /// Format bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Check if notifications are supported on the current platform
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
}
