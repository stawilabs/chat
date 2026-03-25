/// Main entry point for E2E tests.
///
/// This file serves as the test entry point for Patrol and imports
/// all test scenarios and performance benchmarks.
///
/// Run with:
/// ```bash
/// patrol test -t e2e_test
/// ```
library;

import 'performance/baselines/startup_baseline.dart' as startup_baseline;
import 'performance/benchmarks/message_throughput_test.dart'
    as message_throughput;
import 'scenarios/message_delivery_test.dart' as message_delivery;
import 'scenarios/offline_sync_test.dart' as offline_sync;

void main() {
  // Run all scenario tests
  message_delivery.main();
  offline_sync.main();

  // Run all performance tests
  startup_baseline.main();
  message_throughput.main();
}
