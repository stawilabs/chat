import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/logging/sensitive_data_filter.dart';

void main() {
  group('SensitiveDataFilter content-key redaction', () {
    test('redacts message-content keys but keeps ids/types', () {
      final filtered = SensitiveDataFilter.filterData({
        'body': 'send 5000 to chama',
        'senderName': 'Jane Doe',
        'roomName': 'Family Chama',
        'roomId': 'd8d05sspf2tdifellecg',
        'messageId': 'abc123',
        'contentType': 'text',
      });

      expect(filtered['body'], '***REDACTED***');
      expect(filtered['senderName'], '***REDACTED***');
      expect(filtered['roomName'], '***REDACTED***');
      // Non-sensitive identifiers/types must survive for debuggability.
      expect(filtered['roomId'], 'd8d05sspf2tdifellecg');
      expect(filtered['messageId'], 'abc123');
      expect(filtered['contentType'], 'text');
    });

    test('redacts content nested inside a notification data map', () {
      final filtered = SensitiveDataFilter.filterData({
        'data': {
          'roomId': 'room1',
          'message': 'secret transfer details',
          'senderName': 'Bob',
        },
      });

      final data = filtered['data'] as Map<String, dynamic>;
      expect(data['roomId'], 'room1');
      expect(data['message'], '***REDACTED***');
      expect(data['senderName'], '***REDACTED***');
    });

    test('still redacts credential-pattern keys', () {
      final filtered = SensitiveDataFilter.filterData({
        'access_token': 'xyz',
        'phoneNumber': '+254712345678',
      });
      expect(filtered['access_token'], '***REDACTED***');
      expect(filtered['phoneNumber'], '***REDACTED***');
    });
  });
}
