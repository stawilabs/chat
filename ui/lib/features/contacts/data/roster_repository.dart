import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:antinvestor_api_profile/antinvestor_api_profile.dart' as pb;
import 'package:antinvestor_api_profile/antinvestor_api_profile.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sim_card_code/sim_card_code.dart';
import 'package:sqlite3/common.dart' show SqliteException;
import 'package:xid/xid.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/networking/client.dart';
import '../services/contact_sync_service.dart';

// ============================================================================
// Contact Validation Utilities
// ============================================================================

/// Email validation regex pattern (more comprehensive)
final _emailRegex = RegExp(
  r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
);

/// Validate email format with thorough checking
bool isValidEmail(String email) {
  if (email.isEmpty) return false;

  final normalized = email.toLowerCase().trim();

  // Basic length checks
  if (normalized.length < 5) return false; // a@b.c minimum
  if (normalized.length > 254) return false; // RFC 5321 limit

  // Must contain exactly one @
  final atIndex = normalized.indexOf('@');
  if (atIndex <= 0 || atIndex != normalized.lastIndexOf('@')) return false;

  // Local part validation
  final localPart = normalized.substring(0, atIndex);
  if (localPart.isEmpty || localPart.length > 64) {
    return false; // RFC 5321 limit
  }

  // Domain part validation
  final domainPart = normalized.substring(atIndex + 1);
  if (domainPart.isEmpty || domainPart.length > 253) return false;

  // No consecutive dots
  if (normalized.contains('..')) return false;

  // No leading or trailing dots
  if (normalized.startsWith('.') || normalized.endsWith('.')) return false;

  // No leading or trailing dots in local part
  if (localPart.startsWith('.') || localPart.endsWith('.')) return false;

  // No leading or trailing hyphens in domain parts
  final domainParts = domainPart.split('.');
  for (final part in domainParts) {
    if (part.startsWith('-') || part.endsWith('-')) return false;
    if (part.isEmpty) return false;
  }

  // Apply regex for final validation
  return _emailRegex.hasMatch(normalized);
}

/// Validate phone number using phone_numbers_parser with thorough processing
/// Returns the formatted E.164 number if valid, null otherwise
Future<String?> validateAndFormatPhoneNumber(
  String phone, {
  String? regionCode,
}) async {
  if (phone.isEmpty) {
    return null;
  }

  try {
    // Use provided region, or get from SIM card / device locale
    final region = regionCode ?? await _getDeviceRegionCodeAsync();

    // Thorough phone number normalization
    final normalizedPhone = _normalizePhoneNumber(phone, region);
    if (normalizedPhone == null) {
      AppLogger.debug(
        'Phone normalization failed',
        data: {'phone': phone, 'region': region},
      );
      return null;
    }

    // Parse the phone number with the region as caller country
    final isoCode = _regionToIsoCode(region);
    final parsedPhone = PhoneNumber.parse(
      normalizedPhone,
      callerCountry: isoCode,
    );

    // Check if the number is valid
    if (!parsedPhone.isValid()) {
      AppLogger.debug(
        'Invalid phone number',
        data: {'phone': phone, 'normalized': normalizedPhone, 'region': region},
      );
      return null;
    }

    // Get E.164 format (international format with +)
    final formatted = parsedPhone.international;

    return formatted;
  } catch (e) {
    AppLogger.debug(
      'Phone validation failed',
      data: {'phone': phone, 'error': e.toString()},
    );
    return null;
  }
}

/// Convert region code string to IsoCode enum
IsoCode _regionToIsoCode(String regionCode) {
  try {
    final upperRegion = regionCode.toUpperCase();
    final matchingCode = IsoCode.values.cast<IsoCode?>().firstWhere(
      (code) => code!.name.toUpperCase() == upperRegion,
      orElse: () => null,
    );

    if (matchingCode != null) {
      return matchingCode;
    }

    AppLogger.warning(
      'Unknown region code, falling back to US',
      data: {'regionCode': regionCode},
    );
    return IsoCode.US;
  } catch (e) {
    AppLogger.debug(
      'Error converting region to IsoCode',
      data: {'regionCode': regionCode, 'error': e.toString()},
    );
    return IsoCode.US;
  }
}

/// Thorough phone number normalization with country code handling
String? _normalizePhoneNumber(String phone, String regionCode) {
  if (phone.isEmpty) return null;

  // Remove all non-digit characters first
  var digits = phone.replaceAll(RegExp(r'[^\d]'), '');

  // Handle special cases
  if (digits.isEmpty) return null;

  // Remove leading zeros if present (except for single 0)
  if (digits.length > 1 && digits.startsWith('0')) {
    digits = digits.replaceFirst(RegExp('^0+'), '');
  }

  // If still empty after removing zeros, return null
  if (digits.isEmpty) return null;

  // Check if it already has a country code
  final hasPlus = phone.startsWith('+');

  if (hasPlus) {
    // Already has country code, validate length
    if (digits.length < 8 || digits.length > 15) {
      return null; // Invalid international number length
    }
    return '+$digits';
  } else {
    // No country code, add default region's country code
    final countryCode = _getCountryCodeForRegion(regionCode);
    if (countryCode == null) {
      AppLogger.debug('Unknown region code', data: {'region': regionCode});
      return null;
    }

    final withCountryCode = '$countryCode$digits';

    // Validate final number length
    if (withCountryCode.length < 8 || withCountryCode.length > 15) {
      return null;
    }

    return '+$withCountryCode';
  }
}

/// Get country calling code for a given ISO 3166-1 alpha-2 region code
String? _getCountryCodeForRegion(String regionCode) {
  const countryCodes = {
    // North America
    'US': '1',
    'CA': '1',
    'MX': '52',

    // Europe
    'GB': '44',
    'UK': '44',
    'IE': '353',
    'DE': '49',
    'FR': '33',
    'IT': '39',
    'ES': '34',
    'PT': '351',
    'NL': '31',
    'BE': '32',
    'LU': '352',
    'CH': '41',
    'AT': '43',
    'SE': '46',
    'NO': '47',
    'DK': '45',
    'FI': '358',
    'IS': '354',
    'PL': '48',
    'CZ': '420',
    'SK': '421',
    'HU': '36',
    'RO': '40',
    'BG': '359',
    'GR': '30',
    'HR': '385',
    'SI': '386',
    'RS': '381',
    'UA': '380',
    'RU': '7',
    'EE': '372',
    'LV': '371',
    'LT': '370',

    // Africa
    'ZA': '27',
    'NG': '234',
    'KE': '254',
    'UG': '256',
    'TZ': '255',
    'RW': '250',
    'BI': '257',
    'ET': '251',
    'EG': '20',
    'GH': '233',
    'CI': '225',
    'SN': '221',
    'CM': '237',
    'DZ': '213',
    'MA': '212',
    'TN': '216',
    'LY': '218',
    'SD': '249',

    // Middle East
    'IL': '972',
    'SA': '966',
    'AE': '971',
    'QA': '974',
    'KW': '965',
    'BH': '973',
    'OM': '968',
    'JO': '962',
    'LB': '961',
    'TR': '90',
    'IR': '98',
    'IQ': '964',

    // Asia
    'CN': '86',
    'JP': '81',
    'KR': '82',
    'IN': '91',
    'PK': '92',
    'BD': '880',
    'LK': '94',
    'NP': '977',
    'TH': '66',
    'VN': '84',
    'MY': '60',
    'SG': '65',
    'PH': '63',
    'ID': '62',
    'MM': '95',
    'KH': '855',
    'LA': '856',
    'HK': '852',
    'TW': '886',

    // Oceania
    'AU': '61',
    'NZ': '64',
    'PG': '675',

    // South America
    'BR': '55',
    'AR': '54',
    'CL': '56',
    'CO': '57',
    'PE': '51',
    'VE': '58',
    'UY': '598',
    'PY': '595',
    'BO': '591',
    'EC': '593',

    // Caribbean
    'JM': '1',
    'TT': '1',
    'BB': '1',
    'BS': '1',
    'DO': '1',
  };

  return countryCodes[regionCode.toUpperCase()];
}

/// Get the device's region code, preferring SIM card country code
/// Falls back to device locale if SIM card info is unavailable
/// Works on all platforms including web (web uses locale only)
Future<String> _getDeviceRegionCodeAsync() async {
  // First, try to get country code from SIM card (most accurate for mobile)
  try {
    final simCountryCode = await SimCardManager.simCountryCode;
    if (simCountryCode != null && simCountryCode.isNotEmpty) {
      final upperCode = simCountryCode.toUpperCase();
      return upperCode;
    }

    // Try network country code as fallback
    final networkCountryCode = await SimCardManager.networkCountryCode;
    if (networkCountryCode != null && networkCountryCode.isNotEmpty) {
      final upperCode = networkCountryCode.toUpperCase();
      AppLogger.debug('Got region from network', data: {'region': upperCode});
      return upperCode;
    }
  } catch (e) {
    AppLogger.debug(
      'SIM card country code unavailable',
      data: {'error': e.toString()},
    );
  }

  // Fall back to device locale
  return _getDeviceRegionCodeFromLocale();
}

/// Get the device's region code from platform locale (synchronous fallback)
/// Works on all platforms including web
String _getDeviceRegionCodeFromLocale() {
  try {
    // Use PlatformDispatcher.instance directly for web compatibility
    // This works even if WidgetsBinding hasn't been initialized
    final platformDispatcher = ui.PlatformDispatcher.instance;

    // First, try the primary locale
    final primaryLocale = platformDispatcher.locale;
    if (primaryLocale.countryCode != null &&
        primaryLocale.countryCode!.isNotEmpty) {
      AppLogger.debug(
        'Got region from primary locale',
        data: {'region': primaryLocale.countryCode},
      );
      return primaryLocale.countryCode!;
    }

    // If primary locale doesn't have a country code, check all locales
    // This list includes all user-preferred locales in order of preference
    final locales = platformDispatcher.locales;
    for (final locale in locales) {
      if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
        AppLogger.debug(
          'Got region from locale list',
          data: {'region': locale.countryCode, 'locale': locale.toString()},
        );
        return locale.countryCode!;
      }
    }

    // Log when no country code found in any locale
    AppLogger.warning(
      'No country code found in device locales',
      data: {
        'primaryLocale': primaryLocale.toString(),
        'localeCount': locales.length,
        'locales': locales.map((l) => l.toString()).toList(),
      },
    );
  } catch (e) {
    AppLogger.debug(
      'Failed to get locale region',
      data: {'error': e.toString()},
    );
  }

  // Fallback - this should be rare with the improved detection above
  AppLogger.warning(
    'Using fallback region code US - device locale detection failed',
  );
  return 'US';
}

// Sync metadata keys
const _kContactsHashKey = 'roster_contacts_hash';
const _kLastSyncTimeKey = 'roster_last_sync';

/// Contact type enum matching the server's ContactType
enum RosterContactType {
  email(0),
  msisdn(1);

  const RosterContactType(this.value);

  final int value;

  static RosterContactType fromValue(int value) =>
      RosterContactType.values.firstWhere(
        (e) => e.value == value,
        orElse: () => RosterContactType.email,
      );

  static RosterContactType fromProto(pb.ContactType type) =>
      type == pb.ContactType.MSISDN ? msisdn : email;
}

/// Profile data model for local storage
class ProfileData {
  ProfileData({
    required this.id,
    this.name,
    this.avatarUrl,
    this.updatedAt,
    this.metadata,
  });

  factory ProfileData.fromDbRow(Profile row) {
    Map<String, dynamic>? meta;
    if (row.metadata != null) {
      try {
        meta = json.decode(row.metadata!) as Map<String, dynamic>;
      } catch (_) {}
    }
    return ProfileData(
      id: row.id,
      name: row.name,
      avatarUrl: row.avatarUrl,
      updatedAt: row.updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.updatedAt!)
          : null,
      metadata: meta,
    );
  }
  final String id;
  final String? name;
  final String? avatarUrl;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  ProfilesCompanion toCompanion() => ProfilesCompanion(
    id: Value(id),
    name: Value(name),
    avatarUrl: Value(avatarUrl),
    updatedAt: Value(updatedAt?.millisecondsSinceEpoch),
    metadata: Value(metadata != null ? json.encode(metadata) : null),
  );
}

/// Local roster entry model representing a contact link
/// - id: Stable local UUID identifier (never changes)
/// - rosterId: Server roster entry ID (synced from server, nullable)
/// - profileId: Profile ID (null if contact hasn't logged in yet)
/// - contactId: Contact's unique ID from server (available after successful sync)
/// - contactDetail: Email/phone number for display and local reference
class RosterEntry {
  RosterEntry({
    required this.id,
    required this.contactType,
    required this.contactDetail,
    this.rosterId,
    this.profileId,
    this.contactId,
    this.isVerified = false,
    this.displayName,
    this.isBlocked = false,
    this.syncedAt,
    this.createdAt,
  });

  factory RosterEntry.fromDbRow(RosterData row) => RosterEntry(
    id: row.id,
    rosterId: row.rosterId, // Server roster ID
    profileId: row.profileId, // Now nullable
    contactId: row.contactId,
    contactType: RosterContactType.fromValue(row.contactType),
    contactDetail: row.contactDetail,
    isVerified: row.isVerified,
    displayName: row.displayName,
    isBlocked: row.isBlocked,
    syncedAt: row.syncedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.syncedAt!)
        : null,
    createdAt: row.createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.createdAt!)
        : null,
  );

  factory RosterEntry.fromProto(
    pb.RosterObject roster, {
    String? localDisplayName,
    String? localId, // Stable local UUID
  }) {
    final contact = roster.hasContact() ? roster.contact : null;
    return RosterEntry(
      id:
          localId ??
          _generateLocalUuid(), // Use provided local ID or generate new one
      rosterId: roster.id, // Server roster entry ID
      profileId: roster.hasProfileId()
          ? roster.profileId
          : null, // Null if user hasn't logged in
      contactId: contact?.id, // This is the contact's unique ID from server
      contactType: contact != null
          ? RosterContactType.fromProto(contact.type)
          : RosterContactType.email,
      contactDetail: contact?.detail ?? '',
      isVerified: contact?.verified ?? false,
      displayName: localDisplayName ?? contact?.detail ?? roster.profileId,
      syncedAt: DateTime.now(),
    );
  }
  final String id; // Stable local UUID
  final String? rosterId; // Server roster entry ID (synced)
  final String? profileId; // Profile ID (null if user hasn't logged in)
  final String? contactId; // Contact's unique ID from server
  final RosterContactType contactType;
  final String contactDetail; // Email/phone for local display
  final bool isVerified;
  final String? displayName;
  final bool isBlocked;
  final DateTime? syncedAt;
  final DateTime? createdAt;

  RosterCompanion toCompanion() => RosterCompanion(
    id: Value(id),
    rosterId: Value(rosterId), // Server roster ID
    profileId: Value(profileId), // Now nullable
    contactId: Value(contactId),
    contactType: Value(contactType.value),
    contactDetail: Value(contactDetail),
    isVerified: Value(isVerified),
    displayName: Value(displayName),
    isBlocked: Value(isBlocked),
    syncedAt: Value(syncedAt?.millisecondsSinceEpoch),
    createdAt: Value(
      createdAt?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch,
    ),
  );

  /// Generate a stable local UUID for new roster entries
  static String _generateLocalUuid() => Xid().toString();
}

/// Profile with associated contacts (roster entries)
/// This is the primary display model - profile is the person,
/// contacts are the ways to reach them
class ProfileWithContacts {
  ProfileWithContacts({required this.profile, required this.contacts});
  final ProfileData profile;
  final List<RosterEntry> contacts;

  /// Get display name - prefer local contact name, fallback to profile name
  /// Priority: 1. Local contact name (from device), 2. Profile name (from server), 3. Profile ID
  String get displayName {
    // First priority: local contact display name (from user's device contacts)
    if (contacts.isNotEmpty && contacts.first.displayName != null) {
      return contacts.first.displayName!;
    }
    // Second priority: profile name from server
    if (profile.name != null && profile.name!.isNotEmpty) {
      return profile.name!;
    }
    // Last resort: profile ID
    return profile.id;
  }

  /// Get avatar URL from profile
  String? get avatarUrl => profile.avatarUrl;

  /// Check if any contact is verified
  bool get hasVerifiedContact => contacts.any((c) => c.isVerified);

  /// Get primary contact (first verified, or first available)
  RosterEntry? get primaryContact {
    if (contacts.isEmpty) return null;
    return contacts.firstWhere(
      (c) => c.isVerified,
      orElse: () => contacts.first,
    );
  }

  /// Get contact summary for display (e.g., "2 contacts")
  String get contactSummary {
    if (contacts.isEmpty) return 'No contacts';
    if (contacts.length == 1) {
      final c = contacts.first;
      return c.contactType == RosterContactType.msisdn ? 'Phone' : 'Email';
    }
    return '${contacts.length} contacts';
  }
}

/// Callback for sync progress updates
typedef SyncProgressCallback = void Function(SyncProgress progress);

/// Sync progress information
class SyncProgress {
  const SyncProgress({
    required this.state,
    this.totalContacts = 0,
    this.processedContacts = 0,
    this.foundOnPlatform = 0,
    this.currentBatch = 0,
    this.totalBatches = 0,
    this.message,
  });
  final SyncState state;
  final int totalContacts;
  final int processedContacts;
  final int foundOnPlatform;
  final int currentBatch;
  final int totalBatches;
  final String? message;

  double get progress =>
      totalContacts > 0 ? processedContacts / totalContacts : 0;

  /// Whether new contacts were just stored and are ready for display
  bool get hasNewContacts => foundOnPlatform > 0;
}

enum SyncState {
  idle,
  requestingPermission,
  readingContacts,
  uploading,
  completed,
  permissionDenied,
  error,
}

/// Production-quality repository for syncing device contacts with server roster
///
/// Features:
/// - Hash-based change detection to minimize unnecessary syncs
/// - Batch processing for efficiency
/// - Mutex to prevent concurrent sync operations
/// - Reconciliation with server roster
/// - Proper error handling and logging
///
/// Implements [ContactSyncRepository] interface for use with [ContactSyncService].
class RosterRepository implements ContactSyncRepository {
  RosterRepository(this._profileClient, this._database);
  final ProfileServiceClient _profileClient;
  final AppDatabase _database;

  // Mutex for sync operations
  Completer<void>? _syncCompleter;
  bool _isSyncing = false;

  // Configuration
  static const _batchSize = 20;

  // ============================================================================
  // Sync Metadata Management
  // ============================================================================

  Future<String?> _getSyncMetadata(String key) async {
    final query = _database.select(_database.syncMetadata)
      ..where((t) => t.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  Future<void> _setSyncMetadata(String key, String value) async {
    await _database
        .into(_database.syncMetadata)
        .insertOnConflictUpdate(
          SyncMetadataCompanion.insert(
            key: key,
            value: Value(value),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  /// Get the last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final value = await _getSyncMetadata(_kLastSyncTimeKey);
    if (value == null) return null;
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    } catch (_) {
      return null;
    }
  }

  // ============================================================================
  // Hash-based Change Detection
  // ============================================================================

  /// Compute a stable hash of all device contacts for change detection
  String _computeContactsHash(List<flutter_contacts.Contact> contacts) {
    // Sort contacts by ID for stable ordering
    final sortedContacts = List<flutter_contacts.Contact>.from(contacts)
      ..sort((a, b) => a.id.compareTo(b.id));

    // Build a string representation of all contact data we care about
    final buffer = StringBuffer();
    for (final contact in sortedContacts) {
      buffer.write(contact.id);
      for (final phone in contact.phones) {
        buffer.write(_normalizePhone(phone.number));
      }
      for (final email in contact.emails) {
        buffer.write(email.address.toLowerCase().trim());
      }
    }

    // Compute SHA256 hash
    final bytes = utf8.encode(buffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if device contacts have changed since last sync
  @override
  Future<bool> needsSync() async {
    try {
      final hasPermission = await flutter_contacts
          .FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        return false;
      }

      final deviceContacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
      );

      final currentHash = _computeContactsHash(deviceContacts);
      final storedHash = await _getSyncMetadata(_kContactsHashKey);

      if (storedHash == null) {
        AppLogger.debug('No previous contacts hash found, sync needed');
        return true;
      }

      final hashChanged = currentHash != storedHash;
      if (hashChanged) {
        AppLogger.debug('Contacts hash changed, sync needed');
      }

      return hashChanged;
    } catch (e) {
      AppLogger.warning(
        'Failed to check if sync needed',
        data: {'error': e.toString()},
      );
      return true; // Err on the side of syncing
    }
  }

  // ============================================================================
  // Core Sync Operations
  // ============================================================================

  /// Sync device contacts with server only if changes detected
  /// Returns list of roster entries
  /// Set [force] to true to bypass hash check
  Future<List<RosterEntry>> syncIfNeeded({bool force = false}) async {
    // If sync is already in progress, wait for it
    if (_isSyncing && _syncCompleter != null) {
      AppLogger.debug('Sync already in progress, waiting...');
      await _syncCompleter!.future;
      return getLocalRoster();
    }

    if (!force) {
      final syncNeeded = await needsSync();
      if (!syncNeeded) {
        AppLogger.debug('Contacts unchanged, skipping sync');
        return getLocalRoster();
      }
    }

    return syncContacts();
  }

  /// Full sync of device contacts with server
  /// Returns list of roster entries that are registered on the platform
  /// Optionally accepts a [progressCallback] to report sync progress
  @override
  Future<List<RosterEntry>> syncContacts({
    SyncProgressCallback? progressCallback,
  }) async {
    // Mutex check
    if (_isSyncing) {
      AppLogger.debug(
        '[ContactSync] Sync already in progress, waiting for existing sync',
      );
      if (_syncCompleter != null) {
        await _syncCompleter!.future;
      }
      return getLocalRoster();
    }

    _isSyncing = true;
    _syncCompleter = Completer<void>();

    void reportProgress(SyncProgress progress) {
      AppLogger.debug(
        '[ContactSync] Progress: ${progress.state.name}',
        data: {
          'message': progress.message,
          'total': progress.totalContacts,
          'processed': progress.processedContacts,
          'found': progress.foundOnPlatform,
        },
      );
      progressCallback?.call(progress);
    }

    try {
      AppLogger.info(
        '[ContactSync] ========== STARTING CONTACT SYNC ==========',
      );
      final stopwatch = Stopwatch()..start();

      reportProgress(
        const SyncProgress(
          state: SyncState.requestingPermission,
          message: 'Requesting permission...',
        ),
      );

      // Check and request contact permission using permission_handler
      // (flutter_contacts.requestPermission can get out of sync with system state)
      AppLogger.debug('[ContactSync] Checking contact permission status...');
      var permissionStatus = await Permission.contacts.status;
      AppLogger.debug(
        '[ContactSync] Current permission status',
        data: {
          'isGranted': permissionStatus.isGranted,
          'isDenied': permissionStatus.isDenied,
          'isPermanentlyDenied': permissionStatus.isPermanentlyDenied,
          'isRestricted': permissionStatus.isRestricted,
        },
      );

      if (!permissionStatus.isGranted) {
        AppLogger.debug('[ContactSync] Permission not granted, requesting...');
        permissionStatus = await Permission.contacts.request();
        AppLogger.debug(
          '[ContactSync] Permission request result',
          data: {
            'isGranted': permissionStatus.isGranted,
            'isDenied': permissionStatus.isDenied,
            'isPermanentlyDenied': permissionStatus.isPermanentlyDenied,
          },
        );
      }

      if (!permissionStatus.isGranted) {
        final message = permissionStatus.isPermanentlyDenied
            ? 'Permission denied. Please enable in Settings.'
            : 'Contact permission denied';
        AppLogger.warning(
          '[ContactSync] Contact permission DENIED',
          data: {'isPermanentlyDenied': permissionStatus.isPermanentlyDenied},
        );
        reportProgress(
          SyncProgress(state: SyncState.permissionDenied, message: message),
        );
        return [];
      }

      AppLogger.info('[ContactSync] Permission GRANTED, reading contacts...');

      reportProgress(
        const SyncProgress(
          state: SyncState.readingContacts,
          message: 'Reading contacts...',
        ),
      );

      final deviceContacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
      );

      AppLogger.info(
        '[ContactSync] Read ${deviceContacts.length} contacts from device',
      );

      if (deviceContacts.isEmpty) {
        AppLogger.debug(
          '[ContactSync] No device contacts found, nothing to sync',
        );
        reportProgress(
          const SyncProgress(
            state: SyncState.completed,
            message: 'No contacts to sync',
          ),
        );
        return [];
      }

      // Compute hash for change detection
      final contactsHash = _computeContactsHash(deviceContacts);

      // Thorough contact processing with validation
      final deviceRegion = await _getDeviceRegionCodeAsync();
      final contactRequests = <pb.RawContact>[];
      final contactLookup = <String, flutter_contacts.Contact>{};
      final processedContacts = <String>{};
      final duplicateCount = <String, int>{};
      var invalidPhones = 0;
      var invalidEmails = 0;
      var validPhones = 0;
      var validEmails = 0;

      AppLogger.info(
        '[ContactSync] Starting thorough contact processing',
        data: {
          'totalContacts': deviceContacts.length,
          'deviceRegion': deviceRegion,
        },
      );

      reportProgress(
        const SyncProgress(
          state: SyncState.readingContacts,
          message: 'Thoroughly validating contacts...',
        ),
      );

      for (final contact in deviceContacts) {
        // Skip contacts with no name and no contact details
        if (contact.displayName.trim().isEmpty &&
            contact.phones.isEmpty &&
            contact.emails.isEmpty) {
          AppLogger.debug(
            '[ContactSync] Skipping empty contact',
            data: {'contactId': contact.id},
          );
          continue;
        }

        // Process and validate phone numbers with thorough checking
        for (final phone in contact.phones) {
          if (phone.number.trim().isEmpty) {
            AppLogger.debug(
              '[ContactSync] Skipping empty phone number',
              data: {
                'contactId': contact.id,
                'contactName': contact.displayName,
              },
            );
            continue;
          }

          final validatedPhone = await validateAndFormatPhoneNumber(
            phone.number,
            regionCode: deviceRegion,
          );

          if (validatedPhone != null) {
            // Check for duplicates
            if (contactLookup.containsKey(validatedPhone)) {
              duplicateCount[validatedPhone] =
                  (duplicateCount[validatedPhone] ?? 0) + 1;
              AppLogger.debug(
                '[ContactSync] Found duplicate phone',
                data: {
                  'phone': validatedPhone,
                  'existingContact': contactLookup[validatedPhone]?.displayName,
                  'newContact': contact.displayName,
                  'duplicateCount': duplicateCount[validatedPhone],
                },
              );
              continue; // Skip duplicates
            }

            contactLookup[validatedPhone] = contact;
            contactRequests.add(pb.RawContact(contact: validatedPhone));
            processedContacts.add(validatedPhone);
            validPhones++;

            AppLogger.debug(
              '[ContactSync] Validated phone',
              data: {
                'original': phone.number,
                'validated': validatedPhone,
                'contactName': contact.displayName,
              },
            );
          } else {
            invalidPhones++;
            AppLogger.debug(
              '[ContactSync] Invalid phone number',
              data: {
                'phone': phone.number,
                'contactName': contact.displayName,
                'contactId': contact.id,
              },
            );
          }
        }

        // Process and validate emails with thorough checking
        for (final email in contact.emails) {
          if (email.address.trim().isEmpty) {
            AppLogger.debug(
              '[ContactSync] Skipping empty email',
              data: {
                'contactId': contact.id,
                'contactName': contact.displayName,
              },
            );
            continue;
          }

          final normalized = email.address.toLowerCase().trim();

          if (isValidEmail(normalized)) {
            // Check for duplicates
            if (contactLookup.containsKey(normalized)) {
              duplicateCount[normalized] =
                  (duplicateCount[normalized] ?? 0) + 1;
              AppLogger.debug(
                '[ContactSync] Found duplicate email',
                data: {
                  'email': normalized,
                  'existingContact': contactLookup[normalized]?.displayName,
                  'newContact': contact.displayName,
                  'duplicateCount': duplicateCount[normalized],
                },
              );
              continue; // Skip duplicates
            }

            contactLookup[normalized] = contact;
            contactRequests.add(pb.RawContact(contact: normalized));
            processedContacts.add(normalized);
            validEmails++;

            AppLogger.debug(
              '[ContactSync] Validated email',
              data: {'email': normalized, 'contactName': contact.displayName},
            );
          } else {
            invalidEmails++;
            AppLogger.debug(
              '[ContactSync] Invalid email',
              data: {
                'email': email.address,
                'contactName': contact.displayName,
                'contactId': contact.id,
              },
            );
          }
        }
      }

      // Log comprehensive processing results
      AppLogger.info(
        '[ContactSync] Thorough contact validation completed',
        data: {
          'totalContacts': deviceContacts.length,
          'uniqueValidContacts': processedContacts.length,
          'validPhones': validPhones,
          'invalidPhones': invalidPhones,
          'validEmails': validEmails,
          'invalidEmails': invalidEmails,
          'duplicatesFound': duplicateCount.length,
          'duplicateDetails': duplicateCount,
          'deviceRegion': deviceRegion,
        },
      );

      if (contactRequests.isEmpty) {
        AppLogger.warning(
          '[ContactSync] No valid phone numbers or emails found in contacts',
        );
        reportProgress(
          const SyncProgress(
            state: SyncState.completed,
            message: 'No valid contact details found',
          ),
        );
        return [];
      }

      // Remove duplicates
      final uniqueRequests = <String, pb.RawContact>{};
      for (final req in contactRequests) {
        uniqueRequests[req.contact] = req;
      }
      final deduplicatedRequests = uniqueRequests.values.toList();

      AppLogger.info(
        '[ContactSync] Prepared contacts for server sync',
        data: {
          'deviceContacts': deviceContacts.length,
          'rawContactDetails': contactRequests.length,
          'uniqueDetails': deduplicatedRequests.length,
          'duplicatesRemoved':
              contactRequests.length - deduplicatedRequests.length,
        },
      );

      reportProgress(
        SyncProgress(
          state: SyncState.uploading,
          totalContacts: deduplicatedRequests.length,
          message: 'Syncing with server...',
        ),
      );

      // Sync in batches - serial processing with immediate storage
      final syncedEntries = <RosterEntry>[];
      var processedCount = 0;
      final totalBatches = (deduplicatedRequests.length / _batchSize).ceil();
      var batchNum = 0;

      AppLogger.info(
        '[ContactSync] Starting server upload in $totalBatches batches (batch size: $_batchSize)',
      );

      for (var i = 0; i < deduplicatedRequests.length; i += _batchSize) {
        batchNum++;
        final batch = deduplicatedRequests.skip(i).take(_batchSize).toList();

        AppLogger.debug(
          '[ContactSync] Processing batch $batchNum/$totalBatches (${batch.length} contacts)',
        );

        // Report batch starting
        reportProgress(
          SyncProgress(
            state: SyncState.uploading,
            totalContacts: deduplicatedRequests.length,
            processedContacts: processedCount,
            foundOnPlatform: syncedEntries.length,
            currentBatch: batchNum,
            totalBatches: totalBatches,
            message: 'Processing batch $batchNum of $totalBatches...',
          ),
        );

        // Send batch to server and wait for response (serial processing)
        final results = await _syncBatch(batch, contactLookup);

        if (results.isNotEmpty) {
          // Store batch results immediately so contacts are available for use
          AppLogger.debug(
            '[ContactSync] Storing ${results.length} entries from batch $batchNum',
          );
          await _storeRosterEntries(results);

          // Fetch and store profile data for this batch immediately
          final batchProfileIds = results
              .map((e) => e.profileId)
              .toSet()
              .toList();
          await fetchAndStoreProfiles(batchProfileIds);

          syncedEntries.addAll(results);
        }

        processedCount += batch.length;

        AppLogger.debug(
          '[ContactSync] Batch $batchNum completed: ${results.length} contacts found, total: ${syncedEntries.length}',
        );

        // Report batch completion with updated counts
        reportProgress(
          SyncProgress(
            state: SyncState.uploading,
            totalContacts: deduplicatedRequests.length,
            processedContacts: processedCount,
            foundOnPlatform: syncedEntries.length,
            currentBatch: batchNum,
            totalBatches: totalBatches,
            message:
                'Found ${syncedEntries.length} contacts (batch $batchNum/$totalBatches done)',
          ),
        );
      }

      // Update sync metadata
      await _setSyncMetadata(_kContactsHashKey, contactsHash);
      await _setSyncMetadata(
        _kLastSyncTimeKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );

      stopwatch.stop();
      AppLogger.info(
        '[ContactSync] ========== SYNC COMPLETED ==========',
        data: {
          'deviceContacts': deviceContacts.length,
          'contactDetailsChecked': deduplicatedRequests.length,
          'foundOnPlatform': syncedEntries.length,
          'durationMs': stopwatch.elapsedMilliseconds,
          'hashPrefix': contactsHash.substring(0, 8),
        },
      );

      reportProgress(
        SyncProgress(
          state: SyncState.completed,
          totalContacts: deduplicatedRequests.length,
          processedContacts: deduplicatedRequests.length,
          foundOnPlatform: syncedEntries.length,
          message: syncedEntries.isEmpty
              ? 'No contacts found on platform'
              : 'Found ${syncedEntries.length} contacts!',
        ),
      );

      return syncedEntries;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactSync] ========== SYNC FAILED ==========',
        error: e,
        stackTrace: stackTrace,
      );
      reportProgress(
        SyncProgress(
          state: SyncState.error,
          message: 'Sync failed: ${e.toString()}',
        ),
      );
      return [];
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
      AppLogger.debug('[ContactSync] Sync mutex released');
    }
  }

  /// Sync a batch of contacts with the server
  Future<List<RosterEntry>> _syncBatch(
    List<pb.RawContact> batch,
    Map<String, flutter_contacts.Contact> contactLookup,
  ) async {
    try {
      AppLogger.debug(
        '[ContactSync] Sending batch to server',
        data: {'batchSize': batch.length},
      );

      final request = pb.AddRosterRequest(data: batch);
      // Don't pass manual headers - let the interceptor handle authorization
      // This ensures token refresh works correctly on 401
      final response = await _profileClient.addRoster(request);

      AppLogger.debug(
        '[ContactSync] Server response received',
        data: {'responseCount': response.data.length},
      );

      return response.data.map((roster) {
        // Get local display name from device contacts
        String? localDisplayName;
        if (roster.hasContact()) {
          final detail = roster.contact.detail;
          final localContact = contactLookup[detail];
          if (localContact != null && localContact.displayName.isNotEmpty) {
            localDisplayName = localContact.displayName;
          }
        }

        return RosterEntry.fromProto(
          roster,
          localDisplayName: localDisplayName,
          localId: contactLookup.containsKey(roster.contact.detail)
              ? _generateLocalId(roster.contact.detail)
              : null,
        );
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactSync] Batch upload FAILED',
        error: e,
        stackTrace: stackTrace,
        data: {'batchSize': batch.length},
      );
      return [];
    }
  }

  // ============================================================================
  // Two-Phase Contact Sync
  // ============================================================================

  /// Phase 1: Sync contacts to local database immediately (no server call)
  /// Reads device contacts and stores them locally with display names.
  /// Returns the list of locally stored contacts.
  Future<List<RosterEntry>> syncContactsLocal({
    SyncProgressCallback? progressCallback,
  }) async {
    void reportProgress(SyncProgress progress) {
      AppLogger.debug(
        '[ContactSync] Local sync progress: ${progress.state.name}',
        data: {
          'message': progress.message,
          'total': progress.totalContacts,
          'processed': progress.processedContacts,
        },
      );
      progressCallback?.call(progress);
    }

    try {
      AppLogger.info('[ContactSync] ========== PHASE 1: LOCAL SYNC ==========');
      final stopwatch = Stopwatch()..start();

      reportProgress(
        const SyncProgress(
          state: SyncState.requestingPermission,
          message: 'Requesting permission...',
        ),
      );

      // Check and request contact permission
      var permissionStatus = await Permission.contacts.status;
      if (!permissionStatus.isGranted) {
        permissionStatus = await Permission.contacts.request();
      }

      if (!permissionStatus.isGranted) {
        AppLogger.warning('[ContactSync] Contact permission denied');
        reportProgress(
          const SyncProgress(
            state: SyncState.permissionDenied,
            message: 'Permission denied',
          ),
        );
        return [];
      }

      reportProgress(
        const SyncProgress(
          state: SyncState.readingContacts,
          message: 'Reading contacts...',
        ),
      );

      final deviceContacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
      );

      AppLogger.info(
        '[ContactSync] Read ${deviceContacts.length} contacts from device',
      );

      if (deviceContacts.isEmpty) {
        reportProgress(
          const SyncProgress(
            state: SyncState.completed,
            message: 'No contacts found',
          ),
        );
        return [];
      }

      reportProgress(
        const SyncProgress(
          state: SyncState.readingContacts,
          message: 'Processing contacts...',
        ),
      );

      // Build local roster entries (no server call)
      final localEntries = <RosterEntry>[];
      final now = DateTime.now();

      for (final contact in deviceContacts) {
        // Process phone numbers
        for (final phone in contact.phones) {
          final validatedPhone = await validateAndFormatPhoneNumber(
            phone.number,
          );
          if (validatedPhone != null) {
            final id = _generateLocalId(validatedPhone);
            localEntries.add(
              RosterEntry(
                id: id,
                contactType: RosterContactType.msisdn,
                contactDetail: validatedPhone,
                displayName: contact.displayName.isNotEmpty
                    ? contact.displayName
                    : null,
                createdAt: now,
              ),
            );
          }
        }

        // Process emails
        for (final email in contact.emails) {
          final normalized = email.address.toLowerCase().trim();
          if (isValidEmail(normalized)) {
            final id = _generateLocalId(normalized);
            localEntries.add(
              RosterEntry(
                id: id,
                contactType: RosterContactType.email,
                contactDetail: normalized,
                displayName: contact.displayName.isNotEmpty
                    ? contact.displayName
                    : null,
                createdAt: now,
              ),
            );
          }
        }
      }

      AppLogger.info(
        '[ContactSync] Processed ${localEntries.length} valid contact details',
      );

      // Store locally
      await _database.batch((batch) {
        for (final entry in localEntries) {
          batch.insert(
            _database.roster,
            entry.toCompanion(),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      stopwatch.stop();
      AppLogger.info(
        '[ContactSync] Local sync completed',
        data: {
          'entriesStored': localEntries.length,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );

      reportProgress(
        SyncProgress(
          state: SyncState.completed,
          message: 'Contacts loaded locally',
          totalContacts: localEntries.length,
          processedContacts: localEntries.length,
        ),
      );

      return localEntries;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactSync] Local sync failed',
        error: e,
        stackTrace: stackTrace,
      );
      reportProgress(
        SyncProgress(
          state: SyncState.error,
          message: 'Local sync failed: ${e.toString()}',
        ),
      );
      return [];
    }
  }

  /// Phase 2: Sync unsynced contacts to server (background, best effort)
  /// Only syncs contacts that:
  /// - Have empty profileId (not linked yet)
  /// - Haven't been synced in last 2 weeks (or never synced)
  /// Updates roster with server response (contactId, profileId, syncedAt)
  Future<List<RosterEntry>> syncContactsToServer({
    SyncProgressCallback? progressCallback,
  }) async {
    if (_isSyncing) {
      AppLogger.debug(
        '[ContactSync] Server sync already in progress, skipping',
      );
      return [];
    }

    _isSyncing = true;
    _syncCompleter = Completer<void>();

    void reportProgress(SyncProgress progress) {
      AppLogger.debug(
        '[ContactSync] Server sync progress: ${progress.state.name}',
        data: {
          'message': progress.message,
          'total': progress.totalContacts,
          'processed': progress.processedContacts,
        },
      );
      progressCallback?.call(progress);
    }

    try {
      AppLogger.info(
        '[ContactSync] ========== PHASE 2: SERVER SYNC ==========',
      );
      final stopwatch = Stopwatch()..start();

      // Get contacts that need server sync
      final twoWeeksAgo = DateTime.now()
          .subtract(const Duration(days: 14))
          .millisecondsSinceEpoch;

      final query = _database.select(_database.roster)
        ..where(
          (t) =>
              // Null profileId (not linked to a profile yet)
              t.profileId.isNull() &
              // Never synced OR synced more than 2 weeks ago
              (t.syncedAt.isNull() |
                  t.syncedAt.isSmallerThanValue(twoWeeksAgo)),
        );

      final unsyncedRows = await query.get();

      if (unsyncedRows.isEmpty) {
        AppLogger.info('[ContactSync] No contacts need server sync');
        reportProgress(
          const SyncProgress(
            state: SyncState.completed,
            message: 'All contacts up to date',
          ),
        );
        return [];
      }

      AppLogger.info(
        '[ContactSync] Found ${unsyncedRows.length} contacts needing server sync',
      );

      // Build contact requests for server
      final contactRequests = unsyncedRows
          .map((row) => pb.RawContact(contact: row.contactDetail))
          .toList();

      reportProgress(
        SyncProgress(
          state: SyncState.uploading,
          totalContacts: contactRequests.length,
          message: 'Syncing to server...',
        ),
      );

      // Sync in batches
      final syncedEntries = <RosterEntry>[];
      var processedCount = 0;
      final totalBatches = (contactRequests.length / _batchSize).ceil();
      var batchNum = 0;

      for (var i = 0; i < contactRequests.length; i += _batchSize) {
        batchNum++;
        final batch = contactRequests.skip(i).take(_batchSize).toList();

        AppLogger.debug(
          '[ContactSync] Processing batch $batchNum/$totalBatches (${batch.length} contacts)',
        );

        // Build lookup map for this batch
        final batchLookup = <String, RosterData>{};
        for (var j = i; j < i + batch.length && j < unsyncedRows.length; j++) {
          batchLookup[unsyncedRows[j].contactDetail] = unsyncedRows[j];
        }

        reportProgress(
          SyncProgress(
            state: SyncState.uploading,
            totalContacts: contactRequests.length,
            processedContacts: processedCount,
            currentBatch: batchNum,
            totalBatches: totalBatches,
            message: 'Processing batch $batchNum of $totalBatches...',
          ),
        );

        // Send batch to server
        final request = pb.AddRosterRequest(data: batch);
        final response = await _profileClient.addRoster(request);

        // Process server response and update local roster
        final now = DateTime.now().millisecondsSinceEpoch;

        await _database.batch((dbBatch) {
          for (final roster in response.data) {
            if (!roster.hasContact()) continue;

            final contactDetail = roster.contact.detail;
            final localRow = batchLookup[contactDetail];
            if (localRow == null) continue;

            // Update roster entry with server data
            dbBatch.update(
              _database.roster,
              RosterCompanion(
                rosterId: Value(roster.id), // Server roster entry ID
                contactId: Value(
                  roster.hasContact() ? roster.contact.id : null,
                ), // Contact's unique ID
                profileId: Value(
                  roster.hasProfileId() ? roster.profileId : null,
                ), // Null if user hasn't logged in
                isVerified: Value(
                  roster.hasContact() && (roster.contact.verified),
                ),
                syncedAt: Value(now), // Mark as synced
              ),
              where: (t) => t.id.equals(localRow.id),
            );

            syncedEntries.add(
              RosterEntry.fromProto(
                roster,
                localDisplayName: localRow.displayName,
                localId: localRow.id, // Use existing local ID
              ),
            );
          }
        });

        processedCount += batch.length;
        reportProgress(
          SyncProgress(
            state: SyncState.uploading,
            totalContacts: contactRequests.length,
            processedContacts: processedCount,
            foundOnPlatform: syncedEntries.length,
            message:
                'Processed $processedCount/${contactRequests.length} contacts',
          ),
        );
      }

      stopwatch.stop();
      AppLogger.info(
        '[ContactSync] Server sync completed',
        data: {
          'totalSynced': processedCount,
          'foundOnPlatform': syncedEntries.length,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );

      reportProgress(
        SyncProgress(
          state: SyncState.completed,
          message: 'Server sync completed',
          totalContacts: contactRequests.length,
          processedContacts: processedCount,
          foundOnPlatform: syncedEntries.length,
        ),
      );

      return syncedEntries;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactSync] Server sync failed',
        error: e,
        stackTrace: stackTrace,
      );
      reportProgress(
        SyncProgress(
          state: SyncState.error,
          message: 'Server sync failed: ${e.toString()}',
        ),
      );
      return [];
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  /// Generate a stable, contact-book-friendly local ID for a contact detail
  /// Creates predictable IDs that are easy to identify and search locally
  String _generateLocalId(String contactDetail) {
    // Create a predictable prefix based on contact type
    final prefix = contactDetail.contains('@') ? 'email_' : 'phone_';

    // Create a short, readable hash of the contact detail
    final bytes = utf8.encode(contactDetail);
    final hash = sha256.convert(bytes);
    final shortHash = hash.toString().substring(
      0,
      8,
    ); // First 8 chars of SHA256

    // Combine prefix with short hash for a stable, searchable ID
    return '$prefix$shortHash';
  }

  /// Store roster entries in local database efficiently
  /// Handles FK constraint errors gracefully by skipping problematic entries
  Future<void> _storeRosterEntries(List<RosterEntry> entries) async {
    if (entries.isEmpty) return;

    // Try batch insert first for efficiency
    try {
      await _database.batch((batch) {
        for (final entry in entries) {
          batch.insert(
            _database.roster,
            entry.toCompanion(),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    } on SqliteException catch (e) {
      // FK constraint error - fall back to individual inserts with error handling
      if (e.message.contains('FOREIGN KEY constraint failed') ||
          e.extendedResultCode == 787) {
        AppLogger.debug(
          '[Roster] Batch insert failed with FK constraint, trying individual inserts',
          data: {'entriesCount': entries.length},
        );
        await _storeRosterEntriesIndividually(entries);
      } else {
        rethrow;
      }
    }
  }

  /// Store roster entries one at a time, skipping those with FK constraint errors
  Future<void> _storeRosterEntriesIndividually(
    List<RosterEntry> entries,
  ) async {
    var successCount = 0;
    var skippedCount = 0;

    for (final entry in entries) {
      try {
        await _database
            .into(_database.roster)
            .insertOnConflictUpdate(entry.toCompanion());
        successCount++;
      } on SqliteException catch (e) {
        // Skip entries with FK constraint errors (profile doesn't exist)
        if (e.message.contains('FOREIGN KEY constraint failed') ||
            e.extendedResultCode == 787) {
          AppLogger.debug(
            '[Roster] Skipping entry with missing profile',
            data: {
              'entryId': entry.id,
              'profileId': entry.profileId,
              'contactDetail': entry.contactDetail,
            },
          );
          skippedCount++;
        } else {
          // Log other errors but continue
          AppLogger.warning(
            '[Roster] Failed to store entry',
            data: {'entryId': entry.id, 'error': e.message},
          );
          skippedCount++;
        }
      }
    }

    AppLogger.debug(
      '[Roster] Individual insert completed',
      data: {
        'total': entries.length,
        'success': successCount,
        'skipped': skippedCount,
      },
    );
  }

  // ============================================================================
  // Offline-First Operations
  // ============================================================================

  /// Create or update a roster entry locally (works offline)
  /// Returns the created/updated entry
  Future<RosterEntry> createOrUpdateRosterEntry({
    required String contactDetail,
    required RosterContactType contactType,
    String? displayName,
    String? profileId,
    String? contactId,
    bool isVerified = false,
    bool isBlocked = false,
  }) async {
    // Generate stable local ID
    final localId = _generateLocalId(contactDetail);

    final entry = RosterEntry(
      id: localId, // Stable local UUID
      profileId: profileId,
      contactId: contactId,
      contactType: contactType,
      contactDetail: contactDetail,
      isVerified: isVerified,
      displayName: displayName,
      isBlocked: isBlocked,
      createdAt: DateTime.now(),
    );

    // Save locally (works offline)
    await _storeRosterEntries([entry]);

    AppLogger.debug(
      '[Roster] Created/updated entry locally',
      data: {
        'localId': localId,
        'contactDetail': contactDetail,
        'contactType': contactType.toString(),
      },
    );

    return entry;
  }

  /// Get all local roster entries (works offline)
  Future<List<RosterEntry>> getAllLocalRoster() async {
    final db = AppDatabase.instance;
    final query = db.select(db.roster)
      ..orderBy([(t) => OrderingTerm.asc(t.contactDetail)]);

    final results = await query.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }

  /// Search local roster by contact detail (works offline)
  Future<List<RosterEntry>> searchLocalRoster(String query) async {
    final db = AppDatabase.instance;
    final searchQuery = query.toLowerCase();

    final dbQuery = db.select(db.roster)
      ..where(
        (t) =>
            t.contactDetail.lower().contains(searchQuery) |
            t.displayName.lower().contains(searchQuery),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.contactDetail)]);

    final results = await dbQuery.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }

  /// Mark roster entry as needing sync (for when coming back online)
  Future<void> markRosterEntryForSync(String localId) async {
    final db = AppDatabase.instance;
    await (db.update(db.roster)..where((t) => t.id.equals(localId))).write(
      const RosterCompanion(
        syncedAt: Value(null), // Mark as needing sync
      ),
    );

    AppLogger.debug(
      '[Roster] Marked entry for sync',
      data: {'localId': localId},
    );
  }

  /// Simple background sync without progress callbacks
  /// Runs silently in background without disturbing user
  /// Only syncs unsynced local DB contacts to server - does NOT read device contacts
  Future<void> syncContactsInBackground() async {
    try {
      AppLogger.info('[BackgroundSync] Starting silent contact sync');

      // Check connectivity first
      final connectivity = await _checkConnectivity();
      if (!connectivity) {
        AppLogger.debug('[BackgroundSync] Offline - skipping server sync');
        return;
      }

      // Only sync existing local DB contacts to server
      // Does NOT read device contacts
      await syncContactsToServer();

      AppLogger.info('[BackgroundSync] Background sync completed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[BackgroundSync] Background sync failed',
        error: e,
        stackTrace: stackTrace,
      );
      // Silently fail - don't disturb user
    }
  }

  /// Check current connectivity status
  Future<bool> _checkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();
      return results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      );
    } catch (e) {
      AppLogger.warning(
        '[Connectivity] Failed to check connectivity',
        error: e,
      );
      return true; // Assume online if check fails
    }
  }

  /// Initialize contacts on app startup
  /// Only syncs existing local DB contacts to server - does NOT read device contacts
  Future<void> initializeContacts() async {
    try {
      AppLogger.info('[ContactInit] Initializing contacts');

      // Only sync existing local DB contacts to server in background
      // Does NOT read device contacts
      syncContactsInBackground();

      AppLogger.info('[ContactInit] Contacts initialization triggered');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactInit] Failed to initialize contacts',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================================
  // Server Roster Operations
  // ============================================================================

  /// Fetch complete roster from server
  Future<List<RosterEntry>> fetchServerRoster() async {
    try {
      final request = pb.SearchRosterRequest();
      final entries = <RosterEntry>[];

      // Don't pass manual headers - let the interceptor handle authorization
      await for (final response in _profileClient.searchRoster(request)) {
        for (final roster in response.data) {
          entries.add(RosterEntry.fromProto(roster));
        }
      }

      return entries;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to fetch server roster',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Reconcile local roster with server
  /// Ensures local database matches server state
  Future<void> reconcileWithServer() async {
    try {
      AppLogger.info('Reconciling roster with server');
      final stopwatch = Stopwatch()..start();

      // Fetch server roster
      final serverEntries = await fetchServerRoster();
      final serverIds = serverEntries.map((e) => e.id).toSet();

      // Get local roster
      final localEntries = await getAllLocalRoster();
      final localIds = localEntries.map((e) => e.id).toSet();

      // Entries to add locally (on server but not local)
      final toAdd = serverEntries
          .where((e) => !localIds.contains(e.id))
          .toList();

      // Entries to remove locally (local but not on server)
      final toRemove = localIds.difference(serverIds);

      // Batch operations
      await _database.batch((batch) {
        // Add missing entries
        for (final entry in toAdd) {
          batch.insert(
            _database.roster,
            entry.toCompanion(),
            mode: InsertMode.insertOrReplace,
          );
        }

        // Remove stale entries
        for (final id in toRemove) {
          batch.deleteWhere(_database.roster, (t) => t.id.equals(id));
        }
      });

      stopwatch.stop();
      AppLogger.info(
        'Roster reconciliation completed',
        data: {
          'added': toAdd.length,
          'removed': toRemove.length,
          'durationMs': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Roster reconciliation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================================
  // Local Roster Operations
  // ============================================================================

  /// Get all roster entries from local database
  Future<List<RosterEntry>> getLocalRoster({
    bool includeBlocked = false,
  }) async {
    var query = _database.select(_database.roster);
    if (!includeBlocked) {
      query = query..where((t) => t.isBlocked.equals(false));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.displayName)]);

    final results = await query.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }

  /// Get a single roster entry by ID
  Future<RosterEntry?> getRosterEntry(String id) async {
    final query = _database.select(_database.roster)
      ..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? RosterEntry.fromDbRow(result) : null;
  }

  /// Get roster entry by profile ID
  Future<RosterEntry?> getRosterByProfileId(String? profileId) async {
    if (profileId == null) return null;

    final query = _database.select(_database.roster)
      ..where((t) => t.profileId.equals(profileId));
    final result = await query.getSingleOrNull();
    return result != null ? RosterEntry.fromDbRow(result) : null;
  }

  /// Thorough search roster entries by display name or contact detail
  /// Supports partial matching and multiple search terms
  Future<List<RosterEntry>> searchRoster(String query) async {
    if (query.trim().isEmpty) return [];

    // Normalize search query
    final normalizedQuery = query.toLowerCase().trim();
    final searchTerms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    if (searchTerms.isEmpty) return [];

    AppLogger.debug(
      '[RosterSearch] Starting thorough search',
      data: {
        'originalQuery': query,
        'normalizedQuery': normalizedQuery,
        'searchTerms': searchTerms,
      },
    );

    // Build comprehensive search conditions
    final dbQuery = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(false));

    // Add search conditions for each term
    for (final term in searchTerms) {
      final pattern = '%$term%';
      dbQuery.where(
        (t) => t.displayName.like(pattern) | t.contactDetail.like(pattern),
      );
    }

    // Order by display name for consistent results
    dbQuery.orderBy([(t) => OrderingTerm.asc(t.displayName)]);

    final results = await dbQuery.get();
    final rosterEntries = results.map(RosterEntry.fromDbRow).toList();

    AppLogger.debug(
      '[RosterSearch] Search completed',
      data: {'query': query, 'resultsCount': rosterEntries.length},
    );

    return rosterEntries;
  }

  /// Advanced search with contact type filtering
  Future<List<RosterEntry>> searchRosterAdvanced({
    required String query,
    RosterContactType? contactType,
    bool includeVerified = false,
    bool includeUnverified = true,
  }) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.toLowerCase().trim();
    final searchTerms = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();

    final dbQuery = _database.select(_database.roster);

    // Build base conditions
    if (contactType != null) {
      dbQuery.where((t) => t.contactType.equals(contactType.value));
    }

    if (!includeVerified) {
      dbQuery.where((t) => t.isVerified.equals(false));
    }

    if (!includeUnverified) {
      dbQuery.where((t) => t.isVerified.equals(true));
    }

    dbQuery.where((t) => t.isBlocked.equals(false));

    // Add search conditions for each term
    for (final term in searchTerms) {
      final pattern = '%$term%';
      dbQuery.where(
        (t) => t.displayName.like(pattern) | t.contactDetail.like(pattern),
      );
    }

    // Order by verification status and display name
    dbQuery.orderBy([
      (t) => OrderingTerm.desc(t.isVerified), // Verified contacts first
      (t) => OrderingTerm.asc(t.displayName),
    ]);

    final results = await dbQuery.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }

  /// Remove a contact from the roster (server and local)
  Future<void> removeRosterEntry(String id) async {
    try {
      final request = pb.RemoveRosterRequest(id: id);
      // Don't pass manual headers - let the interceptor handle authorization
      await _profileClient.removeRoster(request);

      await (_database.delete(
        _database.roster,
      )..where((t) => t.id.equals(id))).go();

      AppLogger.info('Roster entry removed', data: {'id': id});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to remove roster entry',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Block a roster entry locally
  Future<void> blockRosterEntry(String id) async {
    await (_database.update(_database.roster)..where((t) => t.id.equals(id)))
        .write(const RosterCompanion(isBlocked: Value(true)));
  }

  /// Unblock a roster entry locally
  Future<void> unblockRosterEntry(String id) async {
    await (_database.update(_database.roster)..where((t) => t.id.equals(id)))
        .write(const RosterCompanion(isBlocked: Value(false)));
  }

  /// Get blocked roster entries
  Future<List<RosterEntry>> getBlockedEntries() async {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(true));
    final results = await query.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }

  /// Get roster count
  Future<int> getRosterCount() async {
    final count = await _database.roster.count().getSingle();
    return count;
  }

  // ============================================================================
  // Utility Methods
  // ============================================================================

  String _normalizePhone(String phone) {
    // Remove all non-digit characters except leading +
    final hasPlus = phone.startsWith('+');
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    return hasPlus ? '+$digits' : digits;
  }

  /// Watch roster entries as a stream
  Stream<List<RosterEntry>> watchRoster() {
    final query = _database.select(_database.roster)
      ..where((t) => t.isBlocked.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.displayName)]);

    return query.watch().map(
      (rows) => rows.map(RosterEntry.fromDbRow).toList(),
    );
  }

  // ============================================================================
  // Profile Operations
  // ============================================================================

  /// Fetch profile data from server by ID
  Future<ProfileData?> fetchProfileFromServer(String profileId) async {
    try {
      final request = pb.GetByIdRequest(id: profileId);
      // Don't pass manual headers - let the interceptor handle authorization
      final response = await _profileClient.getById(request);

      if (!response.hasData()) return null;

      final profile = response.data;
      String? name;
      String? avatarUrl;

      // Extract name and avatar from properties
      if (profile.hasProperties()) {
        final props = profile.properties;
        if (props.fields.containsKey('name')) {
          name = props.fields['name']?.stringValue;
        }
        if (props.fields.containsKey('avatar')) {
          avatarUrl = props.fields['avatar']?.stringValue;
        }
        if (props.fields.containsKey('avatarUrl')) {
          avatarUrl = props.fields['avatarUrl']?.stringValue;
        }
      }

      return ProfileData(
        id: profile.id,
        name: name,
        avatarUrl: avatarUrl,
        updatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Failed to fetch profile from server',
        data: {'profileId': profileId, 'error': e.toString()},
      );
      AppLogger.debug(
        'Profile fetch error details',
        data: {'stackTrace': stackTrace.toString()},
      );
      return null;
    }
  }

  /// Fetch and store profile data for multiple profile IDs
  Future<void> fetchAndStoreProfiles(List<String?> profileIds) async {
    if (profileIds.isEmpty) return;

    // Filter out null profileIds and convert to non-nullable list
    final validIds = profileIds
        .where((id) => id != null)
        .cast<String>()
        .toList();
    if (validIds.isEmpty) return;

    final uniqueIds = validIds.toSet().toList();
    AppLogger.debug(
      '[ProfileSync] Fetching ${uniqueIds.length} profiles from server',
    );

    final profiles = <ProfileData>[];
    for (final profileId in uniqueIds) {
      final profile = await fetchProfileFromServer(profileId);
      if (profile != null) {
        profiles.add(profile);
      }
    }

    if (profiles.isNotEmpty) {
      await _storeProfiles(profiles);
      AppLogger.debug('[ProfileSync] Stored ${profiles.length} profiles');
    }
  }

  /// Store profiles in local database
  Future<void> _storeProfiles(List<ProfileData> profiles) async {
    if (profiles.isEmpty) return;

    await _database.batch((batch) {
      for (final profile in profiles) {
        batch.insert(
          _database.profiles,
          profile.toCompanion(),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Get profile from local database
  Future<ProfileData?> getLocalProfile(String profileId) async {
    final query = _database.select(_database.profiles)
      ..where((t) => t.id.equals(profileId));
    final result = await query.getSingleOrNull();
    return result != null ? ProfileData.fromDbRow(result) : null;
  }

  /// Get all profiles with their associated contacts (roster entries)
  /// This is the primary method for displaying contacts - groups by profile
  Future<List<ProfileWithContacts>> getProfilesWithContacts({
    bool includeBlocked = false,
  }) async {
    // Get all roster entries
    final rosterEntries = await getLocalRoster(includeBlocked: includeBlocked);
    if (rosterEntries.isEmpty) return [];

    // Group roster entries by profileId
    final groupedByProfile = <String, List<RosterEntry>>{};
    for (final entry in rosterEntries) {
      final profileKey = entry.profileId ?? 'unlinked'; // Handle null profileId
      groupedByProfile.putIfAbsent(profileKey, () => []).add(entry);
    }

    // Get all profiles (exclude 'unlinked' placeholder)
    final profileIds = groupedByProfile.keys
        .where((id) => id != 'unlinked')
        .toList();
    final query = _database.select(_database.profiles)
      ..where((t) => t.id.isIn(profileIds));
    final profileRows = await query.get();
    final profileMap = {
      for (final p in profileRows) p.id: ProfileData.fromDbRow(p),
    };

    // Build ProfileWithContacts list
    final result = <ProfileWithContacts>[];
    for (final profileId in groupedByProfile.keys) {
      // Skip unlinked contacts - they don't have a real profile
      if (profileId == 'unlinked') continue;
      final contacts = groupedByProfile[profileId]!;

      // Get profile or create placeholder from roster data
      var profile = profileMap[profileId];
      if (profile == null) {
        // Create placeholder profile from roster entry
        final firstContact = contacts.first;
        profile = ProfileData(
          id: profileId,
          name: profileId == 'unlinked'
              ? 'Unknown Contact'
              : firstContact.displayName,
        );
      }

      result.add(ProfileWithContacts(profile: profile, contacts: contacts));
    }

    // Sort by display name
    result.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return result;
  }

  /// Watch profiles with contacts as a stream
  Stream<List<ProfileWithContacts>> watchProfilesWithContacts() =>
      watchRoster().asyncMap((_) => getProfilesWithContacts());

  /// Get all roster entries for a specific profile
  Future<List<RosterEntry>> getRosterEntriesForProfile(String profileId) async {
    final query = _database.select(_database.roster)
      ..where((t) => t.profileId.equals(profileId))
      ..where((t) => t.isBlocked.equals(false));
    final results = await query.get();
    return results.map(RosterEntry.fromDbRow).toList();
  }
}

// ============================================================================
// Providers
// ============================================================================

final rosterRepositoryProvider = FutureProvider<RosterRepository>((ref) async {
  final profileClient = await ref.watch(profileServiceClientProvider.future);

  return RosterRepository(profileClient, AppDatabase.instance);
});

/// Provider for roster entries - returns local roster and syncs to server
/// Does NOT automatically read device contacts - that only happens when user
/// explicitly accesses contact selection functionality
final rosterEntriesProvider = FutureProvider<List<RosterEntry>>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);

  // Get local roster
  final local = await repo.getLocalRoster();

  // Trigger background server sync for unsynced contacts (don't await)
  repo.syncContactsToServer();

  return local;
});

/// Provider for watching roster entries reactively
final rosterStreamProvider = StreamProvider<List<RosterEntry>>((ref) async* {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  yield* repo.watchRoster();
});

/// Provider to force a roster sync
final rosterSyncTriggerProvider = FutureProvider<List<RosterEntry>>((
  ref,
) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.syncIfNeeded(force: true);
});

/// Provider to reconcile local roster with server
final rosterReconcileProvider = FutureProvider<void>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  await repo.reconcileWithServer();
});

/// Provider to check if sync is needed
final rosterSyncNeededProvider = FutureProvider<bool>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.needsSync();
});

/// Provider for blocked roster entries
final blockedRosterEntriesProvider = FutureProvider<List<RosterEntry>>((
  ref,
) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.getBlockedEntries();
});

/// Provider for roster count
final rosterCountProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.getRosterCount();
});

/// Provider for profiles with their associated contacts
/// This is the primary provider for displaying contacts - profile-centric view
/// Does NOT automatically read device contacts - only returns what's in local DB
final profilesWithContactsProvider = FutureProvider<List<ProfileWithContacts>>((
  ref,
) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);

  // Get local data only - does NOT read device contacts
  final local = await repo.getProfilesWithContacts();

  // Trigger background sync of existing local contacts to server (don't await)
  repo.syncContactsToServer();

  return local;
});

/// Stream provider for watching profiles with contacts reactively
final profilesWithContactsStreamProvider =
    StreamProvider<List<ProfileWithContacts>>((ref) async* {
      final repo = await ref.watch(rosterRepositoryProvider.future);
      yield* repo.watchProfilesWithContacts();
    });

/// Provider for Phase 1: Local contact sync (immediate)
/// Reads device contacts and stores them locally without server call
/// This provides instant availability of contacts
final rosterLocalSyncProvider = FutureProvider<List<RosterEntry>>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.syncContactsLocal();
});

/// Provider for Phase 2: Server contact sync (background, best effort)
/// Syncs contacts without profileId to server if not synced in last 2 weeks
/// Updates roster with server response (contactId, profileId, syncedAt)
final rosterServerSyncProvider = FutureProvider<List<RosterEntry>>((ref) async {
  final repo = await ref.watch(rosterRepositoryProvider.future);
  return repo.syncContactsToServer();
});
