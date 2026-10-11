import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stawi_api/finance_v1.dart' as finance;
import 'package:stawi_api/settlement_v1.dart' as settlement;

import '../../../core/networking/api_config.dart';
import '../../../core/networking/client.dart';

/// The generated Stawi clients (package:stawi_api), each over the app's
/// runtime transport: every call carries the signed-in session's token, like
/// the chat and profile clients.
///
/// Settlement is the one chain writer (account calls, room calls, the
/// genesis); finance is the read model (rooms, templates, statements).

final settlementAccountsProvider = Provider<settlement.AccountServiceClient>((
  ref,
) {
  final runtime = ref.watch(authRuntimeProvider);
  return settlement.AccountServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.settlementBaseUrl),
      const [],
    ),
  );
});

final settlementRoomsProvider = Provider<settlement.RoomServiceClient>((ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return settlement.RoomServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.settlementBaseUrl),
      const [],
    ),
  );
});

final financeRoomsProvider = Provider<finance.RoomServiceClient>((ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return finance.RoomServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.financeBaseUrl),
      const [],
    ),
  );
});

final financeTreasuryProvider = Provider<finance.TreasuryServiceClient>((ref) {
  final runtime = ref.watch(authRuntimeProvider);
  return finance.TreasuryServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.financeBaseUrl),
      const [],
    ),
  );
});

final financeGovernanceProvider = Provider<finance.GovernanceServiceClient>((
  ref,
) {
  final runtime = ref.watch(authRuntimeProvider);
  return finance.GovernanceServiceClient(
    createRuntimeTransportFactory(runtime)(
      Uri.parse(ApiConfig.financeBaseUrl),
      const [],
    ),
  );
});
