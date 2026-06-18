import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/auth/runtime_provider.dart';

void main() {
  group('kChatAuthConfig', () {
    test('requests only scopes allowed by the Stawi Chat OAuth client', () {
      expect(kChatAuthConfig.scopes, ['openid', 'profile', 'offline_access']);
      expect(kChatAuthConfig.scopes, isNot(contains('contact')));
    });
  });
}
