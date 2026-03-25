import 'dart:io' as io;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';

/// Provider for TLS client factory.
final certificatePinningProvider = Provider<CertificatePinning>(
  (ref) => CertificatePinning(),
);

/// TLS client factory.
///
/// Certificate pinning has been removed. The app relies on the platform
/// trust store to avoid outages from frequent certificate rotation.
class CertificatePinning {
  CertificatePinning();

  /// Create an HTTP client using the platform trust store.
  io.HttpClient createPinnedHttpClient() {
    return io.HttpClient()
      ..connectionTimeout = ApiConfig.connectionTimeout
      ..idleTimeout = ApiConfig.idleTimeout
      ..maxConnectionsPerHost = 4
      ..autoUncompress = true;
  }
}
