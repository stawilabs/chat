import 'package:flutter_test/flutter_test.dart';

import 'package:stawi/features/profile/data/profile_repository.dart';

void main() {
  group('ContactVerification', () {
    group('ContactInfo', () {
      test('creates email contact correctly', () {
        const contact = ContactInfo(
          id: 'contact-1',
          type: ContactType.email,
          value: 'test@example.com',
        );

        expect(contact.id, equals('contact-1'));
        expect(contact.type, equals(ContactType.email));
        expect(contact.value, equals('test@example.com'));
        expect(contact.isVerified, isFalse);
        expect(contact.isPrimary, isFalse);
      });

      test('creates phone contact correctly', () {
        const contact = ContactInfo(
          id: 'contact-2',
          type: ContactType.phone,
          value: '+1234567890',
          isVerified: true,
          isPrimary: true,
        );

        expect(contact.id, equals('contact-2'));
        expect(contact.type, equals(ContactType.phone));
        expect(contact.value, equals('+1234567890'));
        expect(contact.isVerified, isTrue);
        expect(contact.isPrimary, isTrue);
      });
    });

    group('ProfileUpdateResult', () {
      test('success result has correct properties', () {
        final result = ProfileUpdateResult.success();

        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('failure result has correct properties', () {
        final result = ProfileUpdateResult.failure('Test error');

        expect(result.success, isFalse);
        expect(result.errorMessage, equals('Test error'));
      });
    });

    group('ContactType', () {
      test('email type exists', () {
        expect(ContactType.email, isNotNull);
        expect(ContactType.email.name, equals('email'));
      });

      test('phone type exists', () {
        expect(ContactType.phone, isNotNull);
        expect(ContactType.phone.name, equals('phone'));
      });
    });

    group('Verification flow', () {
      test('unverified contact should show verify option', () {
        const contact = ContactInfo(
          id: 'contact-1',
          type: ContactType.email,
          value: 'test@example.com',
        );

        // Unverified contact should show verify button
        expect(contact.isVerified, isFalse);
      });

      test('verified contact should not show verify option', () {
        const contact = ContactInfo(
          id: 'contact-1',
          type: ContactType.email,
          value: 'test@example.com',
          isVerified: true,
        );

        // Verified contact should not show verify button
        expect(contact.isVerified, isTrue);
      });
    });

    group('Contact identification', () {
      test('contact can be email type', () {
        const contact = ContactInfo(
          id: 'c1',
          type: ContactType.email,
          value: 'test@example.com',
        );

        expect(contact.type == ContactType.email, isTrue);
        expect(contact.type == ContactType.phone, isFalse);
      });

      test('contact can be phone type', () {
        const contact = ContactInfo(
          id: 'c2',
          type: ContactType.phone,
          value: '+1234567890',
        );

        expect(contact.type == ContactType.phone, isTrue);
        expect(contact.type == ContactType.email, isFalse);
      });
    });

    group('Primary contact', () {
      test('contact can be marked as primary', () {
        const contact = ContactInfo(
          id: 'c1',
          type: ContactType.email,
          value: 'test@example.com',
          isPrimary: true,
        );

        expect(contact.isPrimary, isTrue);
      });

      test('contact defaults to non-primary', () {
        const contact = ContactInfo(
          id: 'c1',
          type: ContactType.email,
          value: 'test@example.com',
        );

        expect(contact.isPrimary, isFalse);
      });
    });
  });
}
