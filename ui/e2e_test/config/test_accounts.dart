/// Test account configurations for E2E tests.
///
/// Test accounts are loaded from environment variables to ensure security
/// and allow different credentials for different test environments.
library;

/// Represents a test account with credentials.
class TestAccount {
  /// Creates a new test account.
  const TestAccount({
    required this.email,
    required this.password,
    required this.profileId,
    this.displayName,
    this.phoneNumber,
  });

  /// The account email address.
  final String email;

  /// The account password.
  final String password;

  /// The server-assigned profile ID for this account.
  final String profileId;

  /// Optional display name for the account.
  final String? displayName;

  /// Optional phone number for the account.
  final String? phoneNumber;

  /// Whether this account has valid credentials configured.
  bool get isConfigured => email.isNotEmpty && password.isNotEmpty;

  @override
  String toString() =>
      'TestAccount(email: $email, profileId: $profileId, displayName: $displayName)';
}

/// Static collection of test accounts for E2E tests.
///
/// All credentials are loaded from environment variables:
/// - E2E_USER1_EMAIL, E2E_USER1_PASSWORD, E2E_USER1_PROFILE_ID
/// - E2E_USER2_EMAIL, E2E_USER2_PASSWORD, E2E_USER2_PROFILE_ID
/// - E2E_USER3_EMAIL, E2E_USER3_PASSWORD, E2E_USER3_PROFILE_ID
class TestAccounts {
  /// Private constructor to prevent instantiation.
  TestAccounts._();

  /// Primary test user account.
  ///
  /// Used for single-user tests and as the sender in multi-user tests.
  static const TestAccount user1 = TestAccount(
    email: String.fromEnvironment('E2E_USER1_EMAIL'),
    password: String.fromEnvironment('E2E_USER1_PASSWORD'),
    profileId: String.fromEnvironment('E2E_USER1_PROFILE_ID'),
    displayName: String.fromEnvironment(
      'E2E_USER1_DISPLAY_NAME',
      defaultValue: 'Test User 1',
    ),
    phoneNumber: String.fromEnvironment('E2E_USER1_PHONE'),
  );

  /// Secondary test user account.
  ///
  /// Used as the receiver in two-user message delivery tests.
  static const TestAccount user2 = TestAccount(
    email: String.fromEnvironment('E2E_USER2_EMAIL'),
    password: String.fromEnvironment('E2E_USER2_PASSWORD'),
    profileId: String.fromEnvironment('E2E_USER2_PROFILE_ID'),
    displayName: String.fromEnvironment(
      'E2E_USER2_DISPLAY_NAME',
      defaultValue: 'Test User 2',
    ),
    phoneNumber: String.fromEnvironment('E2E_USER2_PHONE'),
  );

  /// Tertiary test user account.
  ///
  /// Used for group chat tests and multi-party scenarios.
  static const TestAccount user3 = TestAccount(
    email: String.fromEnvironment('E2E_USER3_EMAIL'),
    password: String.fromEnvironment('E2E_USER3_PASSWORD'),
    profileId: String.fromEnvironment('E2E_USER3_PROFILE_ID'),
    displayName: String.fromEnvironment(
      'E2E_USER3_DISPLAY_NAME',
      defaultValue: 'Test User 3',
    ),
    phoneNumber: String.fromEnvironment('E2E_USER3_PHONE'),
  );

  /// List of all configured test accounts.
  static List<TestAccount> get all => [user1, user2, user3];

  /// Returns accounts that have valid credentials configured.
  static List<TestAccount> get configured =>
      all.where((account) => account.isConfigured).toList();

  /// Checks if at least one test account is configured.
  static bool get hasConfiguredAccounts => configured.isNotEmpty;

  /// Checks if all required accounts (user1, user2) are configured.
  static bool get hasMinimumAccounts =>
      user1.isConfigured && user2.isConfigured;

  /// Validates that required test accounts are configured.
  ///
  /// Throws [StateError] if minimum required accounts are not available.
  static void validateConfiguration() {
    if (!hasMinimumAccounts) {
      throw StateError(
        'E2E test accounts not configured. '
        'Please set E2E_USER1_* and E2E_USER2_* environment variables.',
      );
    }
  }
}
