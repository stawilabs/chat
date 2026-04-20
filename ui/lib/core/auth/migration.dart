import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clear legacy openid_client-era tokens so the runtime forces a fresh
/// sign-in on first launch after the migration. Runs once per install;
/// subsequent launches are no-ops.
Future<void> migrateLegacyAuthIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('auth_runtime_migrated') ?? false) return;
  const storage = FlutterSecureStorage();
  for (final key in const [
    'access_token',
    'refresh_token',
    'id_token',
    'token_expires_at',
  ]) {
    try {
      await storage.delete(key: key);
    } catch (_) {}
  }
  await prefs.setBool('auth_runtime_migrated', true);
}
