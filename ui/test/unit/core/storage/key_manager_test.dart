import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/storage/key_manager.dart';

void main() {
  group('KeyManager', () {
    group('keyManagerProvider', () {
      test('provides a KeyManager instance', () {
        // The provider should be available for import
        expect(keyManagerProvider, isNotNull);
      });
    });

    group('KeyManager class', () {
      test('can be instantiated', () {
        // KeyManager should be instantiable
        final keyManager = KeyManager();
        expect(keyManager, isNotNull);
        expect(keyManager, isA<KeyManager>());
      });

      test('has getDeviceId method', () {
        // KeyManager should have the getDeviceId method
        final keyManager = KeyManager();
        expect(keyManager.getDeviceId, isA<Function>());
      });

      test('has deleteAll method', () {
        // KeyManager should have the deleteAll method
        final keyManager = KeyManager();
        expect(keyManager.deleteAll, isA<Function>());
      });
    });
  });

  // Note: Integration tests for KeyManager that require actual storage
  // operations should be run in integration tests with a real device/simulator
  // because FlutterSecureStorage requires native platform channels.
  //
  // The following tests are marked as integration tests:
  // - getDeviceId returns a valid UUID
  // - getDeviceId returns the same ID on subsequent calls
  // - deleteAll clears stored data
  // - New device ID is generated after deleteAll
}
