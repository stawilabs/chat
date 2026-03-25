import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/profile/data/profile_repository.dart';

void main() {
  group('ProfileUpdateResult', () {
    test('success creates successful result', () {
      final result = ProfileUpdateResult.success();

      expect(result.success, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('failure creates failed result with message', () {
      const message = 'Error occurred';
      final result = ProfileUpdateResult.failure(message);

      expect(result.success, isFalse);
      expect(result.errorMessage, equals(message));
    });
  });

  group('ContactInfo', () {
    test('creates email contact correctly', () {
      const contact = ContactInfo(
        id: 'test-id',
        type: ContactType.email,
        value: 'test@example.com',
        isVerified: true,
        isPrimary: true,
      );

      expect(contact.id, equals('test-id'));
      expect(contact.type, equals(ContactType.email));
      expect(contact.value, equals('test@example.com'));
      expect(contact.isVerified, isTrue);
      expect(contact.isPrimary, isTrue);
    });

    test('creates phone contact correctly', () {
      const contact = ContactInfo(
        id: 'test-id-2',
        type: ContactType.phone,
        value: '+1234567890',
      );

      expect(contact.id, equals('test-id-2'));
      expect(contact.type, equals(ContactType.phone));
      expect(contact.value, equals('+1234567890'));
      expect(contact.isVerified, isFalse);
      expect(contact.isPrimary, isFalse);
    });

    test('defaults isVerified and isPrimary to false', () {
      const contact = ContactInfo(
        id: 'test-id',
        type: ContactType.email,
        value: 'test@example.com',
      );

      expect(contact.isVerified, isFalse);
      expect(contact.isPrimary, isFalse);
    });
  });

  group('ContactType', () {
    test('email type exists', () {
      expect(ContactType.email, isNotNull);
    });

    test('phone type exists', () {
      expect(ContactType.phone, isNotNull);
    });

    test('has exactly two values', () {
      expect(ContactType.values.length, equals(2));
    });
  });
}
