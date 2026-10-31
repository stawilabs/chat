import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/networking/api_config.dart';

part 'socialtrader_capabilities.g.dart';

/// The capability the service announces when it can create pools for rooms
/// with its pool-creator key (PoolService.CreatePool).
const String createPoolCapability = 'socialtrader_create_pool';

/// Parses GET /v1/system/capabilities: an object of flags
/// ({"socialtrader_create_pool": true}) or a list under "capabilities".
/// Anything else is no capability at all.
Set<String> parseCapabilities(String body) {
  if (body.isEmpty) return const {};
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const {};
  }
  if (decoded is! Map<String, dynamic>) return const {};
  final listed = decoded['capabilities'];
  if (listed is List) {
    return {
      for (final c in listed)
        if (c is String) c,
    };
  }
  return {
    for (final entry in decoded.entries)
      if (entry.value == true) entry.key,
  };
}

/// The HTTP client the capabilities probe uses; tests override it.
@Riverpod(keepAlive: true)
http.Client capabilitiesHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

/// What the socialtrader service says it can do. A service that does not
/// answer (older build, offline) announces nothing, so every gated feature
/// stays hidden rather than failing later.
@Riverpod(keepAlive: true)
Future<Set<String>> socialTraderCapabilities(Ref ref) async {
  try {
    final response = await ref
        .watch(capabilitiesHttpClientProvider)
        .get(
          Uri.parse('${ApiConfig.socialtraderBaseUrl}/v1/system/capabilities'),
        )
        .timeout(ApiConfig.connectionTimeout);
    if (response.statusCode != 200) return const {};
    return parseCapabilities(response.body);
  } on Exception {
    return const {};
  }
}

/// Whether the service can create a pool for a new trading group.
@riverpod
Future<bool> canCreatePool(Ref ref) async =>
    (await ref.watch(socialTraderCapabilitiesProvider.future))
        .contains(createPoolCapability);
