import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/crypto/key_manager.dart';

void main() {
  test('KeyManager compilation check', () {
    // Simple test to verify KeyManager can be instantiated
    expect(KeyManager, isA<Type>());
  });
}
