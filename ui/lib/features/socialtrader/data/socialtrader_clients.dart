import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/networking/api_config.dart';
import '../../../core/networking/client.dart';
import 'gen/socialtrader/v1/links.connect.client.dart';
import 'gen/socialtrader/v1/markets.connect.client.dart';
import 'gen/socialtrader/v1/pools.connect.client.dart';

export 'gen/socialtrader/v1/links.connect.client.dart';
export 'gen/socialtrader/v1/links.pb.dart';
export 'gen/socialtrader/v1/markets.connect.client.dart';
export 'gen/socialtrader/v1/markets.pb.dart';
export 'gen/socialtrader/v1/pools.connect.client.dart';
export 'gen/socialtrader/v1/pools.pb.dart';
export 'gen/socialtrader/v1/trading.pb.dart' show PreparedTx;

part 'socialtrader_clients.g.dart';

/// The generated socialtrader clients (vendored from the socialtrader
/// repository's protos into `gen/`), each over the app's runtime transport:
/// every call carries the signed-in session's token, like the chat and Stawi
/// clients. Reads and prepares are public on the service; wallet linking
/// needs the session.

@Riverpod(keepAlive: true)
PoolServiceClient poolService(Ref ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return PoolServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.socialtraderBaseUrl),
      const [],
    ),
  );
}

@Riverpod(keepAlive: true)
LinkServiceClient linkService(Ref ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return LinkServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.socialtraderBaseUrl),
      const [],
    ),
  );
}

@Riverpod(keepAlive: true)
MarketServiceClient marketService(Ref ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return MarketServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.socialtraderBaseUrl),
      const [],
    ),
  );
}
