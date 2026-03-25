import 'package:antinvestor_api_common/antinvestor_api_common.dart'
    show TokenRefreshResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/auth/data/auth_repository.dart';

import '../../../test_helpers/test_helpers.dart';

void main() {
  late MockAuthService mockAuthService;
  late AuthRepository repository;

  setUp(() {
    mockAuthService = MockAuthService();
    repository = AuthRepository(mockAuthService);
    mockAuthService.setAuthenticated(false);
    mockAuthService.setShouldThrowError(false);
  });

  group('AuthRepository', () {
    group('isLoggedIn', () {
      test('returns false when not authenticated', () async {
        mockAuthService.setAuthenticated(false);

        final result = await repository.isLoggedIn();

        expect(result, isFalse);
      });

      test('returns true when authenticated', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.isLoggedIn();

        expect(result, isTrue);
      });

      test('throws when auth service throws', () async {
        mockAuthService.setShouldThrowError(true);

        expect(() => repository.isLoggedIn(), throwsException);
      });
    });

    group('logout', () {
      test('clears authentication state', () async {
        mockAuthService.setAuthenticated(true);
        expect(await repository.isLoggedIn(), isTrue);

        await repository.logout();

        expect(await repository.isLoggedIn(), isFalse);
      });
    });

    group('isTokenExpired', () {
      test('returns false for valid token', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.isTokenExpired();

        expect(result, isFalse);
      });
    });

    group('getTimeUntilRefreshNeeded', () {
      test('returns duration when authenticated', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.getTimeUntilRefreshNeeded();

        expect(result, isNotNull);
        expect(result!.inMinutes, greaterThan(0));
      });
    });

    group('hasValidAccessToken', () {
      test('returns false when not authenticated', () async {
        mockAuthService.setAuthenticated(false);

        final result = await repository.hasValidAccessToken();

        expect(result, isFalse);
      });

      test('returns true when authenticated', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.hasValidAccessToken();

        expect(result, isTrue);
      });
    });

    group('ensureValidAccessTokenWithStatus', () {
      test('returns token when authenticated', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.ensureValidAccessTokenWithStatus();

        expect(result.token, isNotNull);
        expect(result.needsRelogin, isFalse);
      });

      test('returns needsRelogin when auth fails', () async {
        mockAuthService.setShouldThrowError(true);

        final result = await repository.ensureValidAccessTokenWithStatus();

        expect(result.token, isNull);
        expect(result.needsRelogin, isTrue);
      });
    });

    group('refreshTokenWithResult', () {
      test('returns success when authenticated', () async {
        mockAuthService.setAuthenticated(true);

        final result = await repository.refreshTokenWithResult();

        expect(result.result, equals(TokenRefreshResult.success));
        expect(result.error, isNull);
      });
    });
  });
}
