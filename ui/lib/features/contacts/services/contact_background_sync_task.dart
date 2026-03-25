import 'dart:io' as io;

import 'package:antinvestor_api_profile/antinvestor_api_profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectrpc/io.dart' as connect_io;
import 'package:connectrpc/protobuf.dart' as connect_protobuf;
import 'package:connectrpc/protocol/connect.dart' as connect_protocol;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/networking/api_config.dart';
import '../../../core/settings/settings_service.dart';
import '../data/roster_repository.dart';
import 'contact_sync_service.dart';

/// Unique task name for contact sync background task
const contactSyncTaskName = 'contact-sync';

/// Unique task identifier for contact sync background task
const contactSyncTaskIdentifier = 'contactSync';

/// Contact sync background task
///
/// This task runs periodically (every 24 hours by default) to sync contacts.
/// It uses workmanager for scheduling and runs even when the app is closed.
class ContactBackgroundSyncTask {
  /// Main entry point for background contact sync
  ///
  /// Returns true if sync completed successfully, false otherwise.
  /// This is called by the Workmanager callback dispatcher.
  static Future<bool> run() async {
    try {
      AppLogger.info('[ContactBackgroundSync] Starting background sync task');

      // Initialize services for background context
      final services = await _initializeServices();
      if (services == null) {
        // Not logged in, skip sync
        return true;
      }

      final (syncService, settingsService) = services;

      // Check if contacts have been initialized via lazy sync
      // Background sync should only run after user has granted permission
      final hasInitialized = settingsService.getBool(
        SettingsKeys.contactSyncInitialized,
      );
      if (!hasInitialized) {
        AppLogger.debug(
          '[ContactBackgroundSync] Contacts not initialized yet, skipping',
        );
        return true; // Not a failure, just waiting for user to initialize
      }

      // Check Wi-Fi only setting before delegating to service
      final syncOnlyOnWifi = settingsService.getBool(
        ContactSyncSettings.syncOnlyOnWifi,
      );

      if (syncOnlyOnWifi) {
        final connectivity = Connectivity();
        final results = await connectivity.checkConnectivity();
        final hasWifi = results.any((r) => r == ConnectivityResult.wifi);

        if (!hasWifi) {
          AppLogger.debug(
            '[ContactBackgroundSync] Wi-Fi only enabled but not connected to Wi-Fi',
          );
          return true; // Not a failure, just waiting for Wi-Fi
        }
      }

      // Delegate to service for sync logic
      final result = await syncService.performBackgroundSync();

      AppLogger.info(
        '[ContactBackgroundSync] Completed',
        data: {
          'success': result.success,
          'syncedCount': result.syncedCount,
          'foundOnPlatform': result.foundOnPlatform,
          'durationMs': result.duration?.inMilliseconds,
        },
      );

      return result.success;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactBackgroundSync] Failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false; // Signal failure so workmanager can retry
    }
  }

  /// Initialize services needed for background sync
  ///
  /// Returns null if the user is not logged in (no access token).
  static Future<(ContactSyncService, SettingsService)?>
  _initializeServices() async {
    // Initialize database and settings
    final database = AppDatabase.instance;
    final settingsService = SettingsService(database);
    await settingsService.initialize();

    // Get auth token
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'access_token');

    if (accessToken == null) {
      AppLogger.debug('[ContactBackgroundSync] No access token, skipping sync');
      return null;
    }

    // Create profile client
    final httpClient = io.HttpClient();
    httpClient.connectionTimeout = ApiConfig.connectionTimeout;
    httpClient.idleTimeout = ApiConfig.idleTimeout;
    httpClient.maxConnectionsPerHost = 2; // Limit for background tasks

    final transport = connect_protocol.Transport(
      baseUrl: ApiConfig.profileBaseUrl,
      codec: const connect_protobuf.ProtoCodec(),
      httpClient: connect_io.createHttpClient(httpClient),
    );
    final profileClient = ProfileServiceClient(transport);

    // Create roster repository and sync service
    final rosterRepository = RosterRepository(profileClient, database);
    final syncService = ContactSyncService(
      syncRepository: rosterRepository,
      settingsService: settingsService,
    );

    return (syncService, settingsService);
  }
}
