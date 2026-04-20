import 'package:antinvestor_auth_runtime/antinvestor_auth_runtime.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stawi/core/db/database.dart' show Draft;
import 'package:stawi/features/messages/data/draft_repository.dart';

import '../support/mock_auth_runtime.dart';

// The legacy MockAuthService / MockAuthRepository fixtures were removed as
// part of the auth-runtime migration (CHAT-3 / CHAT-4). Tests now inject
// [MockAuthRuntime] via [TestHelpers.overrides]; see
// `test/support/mock_auth_runtime.dart` for the stand-in.

/// Mock DraftRepository for testing that doesn't use database
/// This is a fake implementation that doesn't extend DraftRepository
/// to avoid initializing AppDatabase which creates timers.
class MockDraftRepository implements DraftRepository {
  final Map<String, String> _drafts = {};

  @override
  Future<Draft?> getDraft(String roomId) async {
    return null; // Return null for tests - no draft stored
  }

  @override
  Stream<Draft?> watchDraft(String roomId) {
    return Stream.value(null);
  }

  @override
  Future<void> saveDraft({
    required String roomId,
    required String content,
    String? replyToId,
  }) async {
    // No-op for tests - don't actually save
  }

  @override
  Future<void> deleteDraft(String roomId) async {
    _drafts.remove(roomId);
  }

  @override
  Future<List<String>> getRoomsWithDrafts() async {
    return _drafts.keys.toList();
  }

  @override
  Stream<List<Draft>> watchAllDrafts() {
    return Stream.value([]);
  }

  @override
  Future<Map<String, String>> getDraftsMap() async {
    return {};
  }

  @override
  Stream<Map<String, String>> watchDraftsMap() {
    return Stream.value({});
  }

  @override
  Future<void> clearAllDrafts() async {
    _drafts.clear();
  }
}

/// Provider overrides for testing.
///
/// `mockAuthRuntime` is recreated on every [resetMocks] call so tests
/// that mutate its state don't leak into subsequent tests. The override
/// list is constructed lazily so [overrides] always points at the
/// current instance.
class TestHelpers {
  static final mockDraftRepository = MockDraftRepository();

  static MockAuthRuntime mockAuthRuntime = _buildAuthRuntime();

  static MockAuthRuntime _buildAuthRuntime() => MockAuthRuntime(
        initialState: AuthState.authenticated,
        claimsMap: const <String, dynamic>{
          'sub': 'test-user',
          'contact_id': 'test-contact',
        },
        roles: const <String>['user'],
      );

  static List<Override> get overrides => <Override>[
        draftRepositoryProvider.overrideWithValue(mockDraftRepository),
        authRuntimeProvider.overrideWithValue(mockAuthRuntime),
      ];

  /// Reset the mock runtime between tests so state mutations (logouts,
  /// role changes, etc.) don't leak.
  static void resetMocks() {
    mockAuthRuntime = _buildAuthRuntime();
  }

  static void setAuthenticated(bool authenticated) {
    mockAuthRuntime.setAuthState(
      authenticated ? AuthState.authenticated : AuthState.unauthenticated,
    );
  }

  /// No-op retained for call-site compatibility. The old fixture surfaced
  /// synthetic auth errors; the new runtime-backed harness exercises
  /// error paths through concrete `SecurityEvent` / `AuthState.error`
  /// transitions — use [MockAuthRuntime.emitSecurityEvent] directly.
  static void setShouldThrowAuthError(bool shouldThrow) {}
}

/// Extension to make it easier to create ProviderScope with mocks in tests
extension ProviderScopeTest on WidgetTester {
  Future<void> pumpWidgetWithMocks(Widget child) async {
    await pumpWidget(
      ProviderScope(overrides: TestHelpers.overrides, child: child),
    );
  }
}
