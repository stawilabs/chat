import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keys `lib/core/networking/api_config.dart` reads with
/// `String.fromEnvironment`. An env file key outside this set is a typo
/// that would silently fall back to the compiled-in default.
const _knownKeys = {
  'APP_ENVIRONMENT',
  'API_BASE_URL',
  'CHAT_URL',
  'GATEWAY_URL',
  'PROFILE_URL',
  'DEVICES_URL',
  'FILES_URL',
  'SETTLEMENT_URL',
  'FINANCE_URL',
  'OAUTH2_ISSUER_URL',
};

/// Secrets CI passes with `--dart-define`; they must never be committed.
const _secretKeys = {
  'SENTRY_DSN',
  'OAUTH2_CLIENT_ID',
  'GOOGLE_SERVER_CLIENT_ID',
};

Map<String, Object?> _load(String environment) {
  final file = File('env/$environment.json');
  expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  return jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
}

void main() {
  for (final environment in ['staging', 'production']) {
    group('env/$environment.json', () {
      late Map<String, Object?> values;
      setUp(() => values = _load(environment));

      test('defines every endpoint key and nothing unknown', () {
        expect(values.keys.toSet(), equals(_knownKeys));
      });

      test('holds no secrets', () {
        expect(values.keys.toSet().intersection(_secretKeys), isEmpty);
      });

      test('names its own environment', () {
        expect(values['APP_ENVIRONMENT'], environment);
      });

      test('uses https URLs on live stawi.org hosts', () {
        for (final entry in values.entries) {
          if (entry.key == 'APP_ENVIRONMENT') continue;
          final uri = Uri.parse(entry.value! as String);
          expect(uri.scheme, 'https', reason: entry.key);
          expect(uri.host, endsWith('.stawi.org'), reason: entry.key);
        }
      });
    });
  }
}
