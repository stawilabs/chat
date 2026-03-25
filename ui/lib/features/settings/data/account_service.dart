import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/networking/api_config.dart';
import '../../../core/networking/client.dart';
import '../../../core/storage/key_manager.dart';

part 'account_service.g.dart';

/// Represents a linked device/session
class LinkedDevice {
  const LinkedDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActiveAt,
    required this.isCurrent,
    this.location,
    this.ipAddress,
  });

  factory LinkedDevice.fromJson(Map<String, dynamic> json) {
    return LinkedDevice(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unknown Device',
      platform: json['platform'] as String? ?? 'Unknown',
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.parse(json['last_active_at'] as String)
          : DateTime.now(),
      isCurrent: json['is_current'] as bool? ?? false,
      location: json['location'] as String?,
      ipAddress: json['ip_address'] as String?,
    );
  }

  final String id;
  final String name;
  final String platform;
  final DateTime lastActiveAt;
  final bool isCurrent;
  final String? location;
  final String? ipAddress;

  String get formattedLastActive {
    final now = DateTime.now();
    final diff = now.difference(lastActiveAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${lastActiveAt.day}/${lastActiveAt.month}/${lastActiveAt.year}';
  }

  String get platformIcon {
    final platformLower = platform.toLowerCase();
    if (platformLower.contains('ios') || platformLower.contains('iphone')) {
      return 'phone_iphone';
    } else if (platformLower.contains('android')) {
      return 'phone_android';
    } else if (platformLower.contains('web')) {
      return 'web';
    } else if (platformLower.contains('mac')) {
      return 'laptop_mac';
    } else if (platformLower.contains('windows')) {
      return 'laptop_windows';
    } else if (platformLower.contains('linux')) {
      return 'computer';
    }
    return 'devices';
  }
}

/// Result of account data request
class AccountDataRequest {
  const AccountDataRequest({
    required this.requestId,
    required this.status,
    this.downloadUrl,
    this.expiresAt,
  });

  factory AccountDataRequest.fromJson(Map<String, dynamic> json) {
    return AccountDataRequest(
      requestId: json['request_id'] as String,
      status: AccountDataRequestStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      downloadUrl: json['download_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  final String requestId;
  final AccountDataRequestStatus status;
  final String? downloadUrl;
  final DateTime? expiresAt;
}

enum AccountDataRequestStatus {
  pending,
  processing,
  ready,
  expired,
  failed;

  static AccountDataRequestStatus fromString(String value) {
    return AccountDataRequestStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => AccountDataRequestStatus.pending,
    );
  }
}

/// Service for account management operations
class AccountService {
  AccountService(this._getAccessToken, this._keyManager);

  final Future<String?> Function() _getAccessToken;
  final KeyManager _keyManager;

  /// Get list of linked devices/sessions
  Future<List<LinkedDevice>> getLinkedDevices() async {
    try {
      final token = await _getAccessToken();
      final currentDeviceId = await _keyManager.getDeviceId();

      final uri = Uri.parse('${ApiConfig.devicesBaseUrl}/v1/devices');

      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final devices =
            (json['devices'] as List?)
                ?.map((d) => LinkedDevice.fromJson(d as Map<String, dynamic>))
                .map((device) {
                  // Mark current device
                  if (device.id == currentDeviceId) {
                    return LinkedDevice(
                      id: device.id,
                      name: device.name,
                      platform: device.platform,
                      lastActiveAt: DateTime.now(),
                      isCurrent: true,
                      location: device.location,
                      ipAddress: device.ipAddress,
                    );
                  }
                  return device;
                })
                .toList() ??
            [];

        // Sort: current device first, then by last active
        devices.sort((a, b) {
          if (a.isCurrent) return -1;
          if (b.isCurrent) return 1;
          return b.lastActiveAt.compareTo(a.lastActiveAt);
        });

        return devices;
      }

      // API returned empty/error - return just the current device
      return [
        LinkedDevice(
          id: currentDeviceId,
          name: 'This Device',
          platform: 'Unknown',
          lastActiveAt: DateTime.now(),
          isCurrent: true,
        ),
      ];
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to get linked devices',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Remove a linked device (logout from that device)
  ///
  /// Throws an exception if the operation fails.
  Future<void> removeDevice(String deviceId) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${ApiConfig.devicesBaseUrl}/v1/devices/$deviceId');

      final response = await http.delete(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info(
          '[AccountService] Device removed successfully',
          data: {'deviceId': deviceId},
        );
        return;
      }

      throw Exception('Failed to remove device: HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to remove device',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Request a download of account data
  Future<AccountDataRequest?> requestAccountData() async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/data-export',
      );

      final response = await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AccountDataRequest.fromJson(json);
      }

      AppLogger.warning(
        '[AccountService] Failed to request account data',
        data: {'statusCode': response.statusCode},
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to request account data',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Check status of account data request
  Future<AccountDataRequest?> checkAccountDataStatus(String requestId) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/data-export/$requestId',
      );

      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return AccountDataRequest.fromJson(json);
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to check account data status',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update phone number (initiates verification flow)
  Future<bool> updatePhoneNumber(String phoneNumber) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${ApiConfig.profileBaseUrl}/v1/account/phone');

      final response = await http.put(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'phone': phoneNumber}),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        AppLogger.info('[AccountService] Phone update initiated');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to update phone number',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Update email address (initiates verification flow)
  Future<bool> updateEmail(String email) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${ApiConfig.profileBaseUrl}/v1/account/email');

      final response = await http.put(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        AppLogger.info('[AccountService] Email update initiated');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to update email',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Delete account (requires confirmation)
  Future<bool> deleteAccount({String? reason}) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${ApiConfig.profileBaseUrl}/v1/account');

      final response = await http.delete(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: reason != null ? jsonEncode({'reason': reason}) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info('[AccountService] Account deletion initiated');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to delete account',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // ==========================================================================
  // Two-Factor Authentication
  // ==========================================================================

  /// Get current 2FA status
  Future<TwoFactorStatus> get2FAStatus() async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/2fa/status',
      );

      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TwoFactorStatus.fromJson(json);
      }

      return const TwoFactorStatus(isEnabled: false);
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to get 2FA status',
        error: e,
        stackTrace: stackTrace,
      );
      return const TwoFactorStatus(isEnabled: false);
    }
  }

  /// Initiate 2FA setup - returns secret key and QR code URL
  Future<TwoFactorSetupData?> initiate2FASetup() async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse('${ApiConfig.profileBaseUrl}/v1/account/2fa/setup');

      final response = await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return TwoFactorSetupData.fromJson(json);
      }

      AppLogger.warning(
        '[AccountService] Failed to initiate 2FA setup',
        data: {'statusCode': response.statusCode},
      );
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to initiate 2FA setup',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Verify TOTP code during 2FA setup
  Future<bool> verify2FACode(String code) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/2fa/verify',
      );

      final response = await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        AppLogger.info('[AccountService] 2FA code verified successfully');
        return true;
      }

      AppLogger.warning(
        '[AccountService] 2FA code verification failed',
        data: {'statusCode': response.statusCode},
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to verify 2FA code',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get backup codes after 2FA is enabled
  Future<List<String>> getBackupCodes() async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/2fa/backup-codes',
      );

      final response = await http.get(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final codes = json['codes'] as List<dynamic>?;
        return codes?.map((e) => e.toString()).toList() ?? [];
      }

      return [];
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to get backup codes',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Regenerate backup codes
  Future<List<String>> regenerateBackupCodes() async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/2fa/backup-codes/regenerate',
      );

      final response = await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final codes = json['codes'] as List<dynamic>?;
        AppLogger.info('[AccountService] Backup codes regenerated');
        return codes?.map((e) => e.toString()).toList() ?? [];
      }

      AppLogger.warning(
        '[AccountService] Failed to regenerate backup codes',
        data: {'statusCode': response.statusCode},
      );
      return [];
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to regenerate backup codes',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Disable 2FA with verification code
  Future<bool> disable2FA(String code) async {
    try {
      final token = await _getAccessToken();

      final uri = Uri.parse(
        '${ApiConfig.profileBaseUrl}/v1/account/2fa/disable',
      );

      final response = await http.post(
        uri,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        AppLogger.info('[AccountService] 2FA disabled successfully');
        return true;
      }

      AppLogger.warning(
        '[AccountService] Failed to disable 2FA',
        data: {'statusCode': response.statusCode},
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[AccountService] Failed to disable 2FA',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

// ============================================================================
// Two-Factor Authentication Models
// ============================================================================

/// Data returned when initiating 2FA setup
class TwoFactorSetupData {
  const TwoFactorSetupData({
    required this.secretKey,
    required this.qrCodeUrl,
    required this.issuer,
    required this.accountName,
  });

  factory TwoFactorSetupData.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetupData(
      secretKey: json['secret_key'] as String,
      qrCodeUrl: json['qr_code_url'] as String,
      issuer: json['issuer'] as String? ?? 'Stawi',
      accountName: json['account_name'] as String? ?? '',
    );
  }

  final String secretKey;
  final String qrCodeUrl;
  final String issuer;
  final String accountName;

  /// Generate otpauth:// URI for QR code
  String get otpauthUri =>
      'otpauth://totp/$issuer:$accountName?secret=$secretKey&issuer=$issuer';
}

/// 2FA status information
class TwoFactorStatus {
  const TwoFactorStatus({
    required this.isEnabled,
    this.enabledAt,
    this.backupCodesRemaining,
  });

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) {
    return TwoFactorStatus(
      isEnabled: json['is_enabled'] as bool? ?? false,
      enabledAt: json['enabled_at'] != null
          ? DateTime.parse(json['enabled_at'] as String)
          : null,
      backupCodesRemaining: json['backup_codes_remaining'] as int?,
    );
  }

  final bool isEnabled;
  final DateTime? enabledAt;
  final int? backupCodesRemaining;
}

@riverpod
AccountService accountService(Ref ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  final keyManager = ref.watch(keyManagerProvider);
  return AccountService(() async => tokenManager.accessToken, keyManager);
}

/// Provider to get linked devices
@riverpod
Future<List<LinkedDevice>> linkedDevices(Ref ref) async {
  final service = ref.watch(accountServiceProvider);
  return service.getLinkedDevices();
}

/// Provider to get 2FA status
@riverpod
Future<TwoFactorStatus> twoFactorStatus(Ref ref) async {
  final service = ref.watch(accountServiceProvider);
  return service.get2FAStatus();
}
