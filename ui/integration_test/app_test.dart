/// Main entry point for integration tests.
///
/// This file aggregates all integration tests to be run via:
/// ```
/// flutter test integration_test/app_test.dart
/// ```
///
/// Or for device testing:
/// ```
/// flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
/// ```
library;

import 'package:integration_test/integration_test.dart';

import 'auth_flow_test.dart' as auth_tests;
import 'message_flow_test.dart' as message_tests;
import 'room_flow_test.dart' as room_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Authentication flow tests
  auth_tests.main();

  // Message flow tests
  message_tests.main();

  // Room management tests
  room_tests.main();
}
