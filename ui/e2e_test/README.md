# E2E Tests

End-to-end tests for the Stawi chat application using [Patrol](https://patrol.leancode.co/).

## Overview

This directory contains comprehensive E2E tests that validate the app's behavior on real devices using the Patrol testing framework. Tests are organized into:

- **Scenarios**: Functional tests for user flows (messaging, sync, auth)
- **Performance**: Benchmarks for startup time, throughput, and latency

## Directory Structure

```
e2e_test/
|-- config/
|   |-- staging_config.dart    # Staging environment URLs and timeouts
|   |-- test_accounts.dart     # Test user credentials
|
|-- helpers/
|   |-- auth_helper.dart       # Login/logout helper methods
|   |-- sync_helper.dart       # Sync and delivery wait methods
|
|-- fixtures/
|   |-- seed_data.dart         # Test data factories
|
|-- scenarios/
|   |-- message_delivery_test.dart   # Message send/receive tests
|   |-- offline_sync_test.dart       # Offline queue and sync tests
|
|-- performance/
|   |-- baselines/
|   |   |-- startup_baseline.dart    # Cold/warm start benchmarks
|   |
|   |-- benchmarks/
|       |-- message_throughput_test.dart  # P95 latency, throughput
|
|-- README.md                  # This file
```

## Prerequisites

1. **Flutter SDK** 3.9 or higher
2. **Patrol CLI**: `dart pub global activate patrol_cli`
3. **Test Accounts**: Configure environment variables (see below)

## Configuration

### Environment Variables

Set these environment variables before running tests:

```bash
# Staging URLs
export E2E_GATEWAY_URL="https://gateway.staging.antinvestor.com"
export E2E_CHAT_URL="https://chat.staging.antinvestor.com"
export E2E_PROFILE_URL="https://profile.staging.antinvestor.com"
export E2E_AUTH_URL="https://auth.staging.antinvestor.com"
export E2E_OAUTH_CLIENT_ID="e2e-test-client"

# Test User 1 (Primary)
export E2E_USER1_EMAIL="<YOUR_TEST_USER1_EMAIL>"
export E2E_USER1_PASSWORD="<YOUR_TEST_USER1_PASSWORD>"
export E2E_USER1_PROFILE_ID="<YOUR_TEST_USER1_PROFILE_ID>"

# Test User 2 (Secondary)
export E2E_USER2_EMAIL="<YOUR_TEST_USER2_EMAIL>"
export E2E_USER2_PASSWORD="<YOUR_TEST_USER2_PASSWORD>"
export E2E_USER2_PROFILE_ID="<YOUR_TEST_USER2_PROFILE_ID>"

# Test User 3 (Optional, for group tests)
export E2E_USER3_EMAIL="<YOUR_TEST_USER3_EMAIL>"
export E2E_USER3_PASSWORD="<YOUR_TEST_USER3_PASSWORD>"
export E2E_USER3_PROFILE_ID="<YOUR_TEST_USER3_PROFILE_ID>"
```

## Running Tests

### Run All E2E Tests

```bash
# On connected device
patrol test -t e2e_test

# On Android emulator
patrol test -t e2e_test --device emulator-5554

# On iOS simulator
patrol test -t e2e_test --device "iPhone 15 Pro"
```

### Run Specific Test File

```bash
# Message delivery tests
patrol test -t e2e_test/scenarios/message_delivery_test.dart

# Offline sync tests
patrol test -t e2e_test/scenarios/offline_sync_test.dart

# Startup performance
patrol test -t e2e_test/performance/baselines/startup_baseline.dart

# Message throughput
patrol test -t e2e_test/performance/benchmarks/message_throughput_test.dart
```

### Run with Verbose Output

```bash
patrol test -t e2e_test --verbose
```

### Build Test APK (for Firebase Test Lab)

```bash
patrol build android --target e2e_test
```

## CI/CD Integration

### GitHub Actions

E2E tests run nightly via `.github/workflows/e2e-nightly.yml`:

- **Schedule**: Every day at 2 AM UTC
- **Environment**: Firebase Test Lab with Pixel 6 (Android 13)
- **Notifications**: Slack alerts on completion

### Manual Trigger

You can manually trigger E2E tests from the GitHub Actions UI:

1. Go to Actions > E2E Nightly Tests
2. Click "Run workflow"
3. Select test suite (all, scenarios, or performance)
4. Optionally enable Slack notification

### Required Secrets

Configure these secrets in GitHub:

- `FIREBASE_PROJECT_ID`: Google Cloud project ID
- `FIREBASE_SERVICE_ACCOUNT`: Service account JSON for Firebase
- `FIREBASE_RESULTS_BUCKET`: GCS bucket for test results
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications
- `E2E_*`: All environment variables listed above

## Performance Thresholds

The performance tests enforce these thresholds (defined in `staging_config.dart`):

| Metric | Threshold | Description |
|--------|-----------|-------------|
| Cold Start | < 3000ms | App launch to first frame |
| Warm Start | < 1000ms | Resume from background |
| Database Init | < 500ms | SQLite initialization |
| Total Startup | < 5000ms | Launch to interactive |
| P95 Latency | < 2000ms | Message delivery (95th percentile) |
| P99 Latency | < 5000ms | Message delivery (99th percentile) |
| Throughput | > 10 msg/sec | Sustained message rate |

## Writing New Tests

### Basic Test Template

```dart
import 'package:patrol/patrol.dart';
import '../config/staging_config.dart';
import '../config/test_accounts.dart';
import '../helpers/auth_helper.dart';
import '../helpers/sync_helper.dart';

void main() {
  patrolTest(
    'Test description',
    ($) async {
      // Validate configuration
      TestAccounts.validateConfiguration();

      // Login
      await $.auth.loginWithCredentials(TestAccounts.user1);

      // Wait for sync
      await $.sync.waitForSyncConnection();

      // Your test logic here
      expect(something, isTrue);
    },
    timeout: Timeout(TestTimeouts.defaultTestTimeout),
  );
}
```

### Using Patrol Finders

```dart
// Find by widget type
final button = $(ElevatedButton);

// Find by text content
final text = $(Text).containing('Hello');

// Find by icon
final icon = $(Icons.send);

// Chain finders
final sendButton = $(IconButton).containing(Icons.send);

// Interactions
await button.tap();
await textField.enterText('message');
await widget.longPress();
```

### Custom Helpers

Add reusable helpers to `helpers/` directory:

```dart
extension MyHelperExtensions on PatrolIntegrationTester {
  MyHelper get myHelper => MyHelper(this);
}

class MyHelper {
  MyHelper(this.$);
  final PatrolIntegrationTester $;

  Future<void> doSomething() async {
    // Implementation
  }
}
```

## Troubleshooting

### Test Timeout

If tests are timing out:
1. Check network connectivity to staging servers
2. Verify test account credentials
3. Increase timeout: `timeout: Timeout(Duration(minutes: 10))`

### Element Not Found

If finders can't locate elements:
1. Use `await $.pumpAndSettle()` before finding
2. Check element is visible (not offscreen)
3. Use more specific finders (combine type + text)

### Firebase Test Lab Failures

1. Check APK was built with correct environment variables
2. Verify service account has Test Lab permissions
3. Review test logs in GCS results bucket

## Maintenance

### Updating Test Accounts

If test accounts change:
1. Update secrets in GitHub
2. Verify accounts exist on staging
3. Ensure accounts have appropriate room memberships

### Adding New Scenarios

1. Create new file in `scenarios/` or `performance/`
2. Import common helpers and config
3. Follow existing test patterns
4. Add to CI workflow if needed

## Related Documentation

- [Patrol Documentation](https://patrol.leancode.co/documentation)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)
