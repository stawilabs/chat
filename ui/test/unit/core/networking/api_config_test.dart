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
  });
}
