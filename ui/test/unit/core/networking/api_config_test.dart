import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/networking/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('uses the production Google server client ID by default', () {
      expect(
        ApiConfig.googleServerClientId,
        '265397001887-hjrrjml6ekekmrjlg4ku4bsgtobgid85.apps.googleusercontent.com',
      );
    });

    test('defaults every endpoint to the live stawi.org hosts', () {
      expect(ApiConfig.apiBaseUrl, 'https://api.stawi.org');
      expect(ApiConfig.chatBaseUrl, 'https://chat.stawi.org');
      expect(ApiConfig.gatewayBaseUrl, 'https://gateway.stawi.org');
      expect(ApiConfig.profileBaseUrl, 'https://api.stawi.org/profile');
      expect(ApiConfig.devicesBaseUrl, 'https://api.stawi.org/devices');
      expect(ApiConfig.filesBaseUrl, 'https://api.stawi.org/files');
      expect(ApiConfig.oauth2IssuerUrl, 'https://oauth2.stawi.org');
    });
  });
}
