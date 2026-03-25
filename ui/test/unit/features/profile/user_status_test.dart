import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/profile/domain/user_status.dart';

void main() {
  group('UserStatus', () {
    test('has exactly 5 status values', () {
      expect(UserStatus.values.length, equals(5));
    });

    test('offline status has correct properties', () {
      const status = UserStatus.offline;
      expect(status.value, equals(0));
      expect(status.label, equals('Offline'));
      expect(status.color, equals(Colors.grey));
    });

    test('online status has correct properties', () {
      const status = UserStatus.online;
      expect(status.value, equals(1));
      expect(status.label, equals('Online'));
      expect(status.color, equals(Colors.green));
    });

    test('away status has correct properties', () {
      const status = UserStatus.away;
      expect(status.value, equals(2));
      expect(status.label, equals('Away'));
      expect(status.color, equals(Colors.orange));
    });

    test('busy status has correct properties', () {
      const status = UserStatus.busy;
      expect(status.value, equals(3));
      expect(status.label, equals('Busy'));
      expect(status.color, equals(Colors.red));
    });

    test('doNotDisturb status has correct properties', () {
      const status = UserStatus.doNotDisturb;
      expect(status.value, equals(4));
      expect(status.label, equals('Do Not Disturb'));
      expect(status.color, equals(Colors.red));
    });

    group('fromValue', () {
      test('returns correct status for valid values', () {
        expect(UserStatus.fromValue(0), equals(UserStatus.offline));
        expect(UserStatus.fromValue(1), equals(UserStatus.online));
        expect(UserStatus.fromValue(2), equals(UserStatus.away));
        expect(UserStatus.fromValue(3), equals(UserStatus.busy));
        expect(UserStatus.fromValue(4), equals(UserStatus.doNotDisturb));
      });

      test('returns offline for invalid value', () {
        expect(UserStatus.fromValue(-1), equals(UserStatus.offline));
        expect(UserStatus.fromValue(5), equals(UserStatus.offline));
        expect(UserStatus.fromValue(100), equals(UserStatus.offline));
      });
    });

    group('icon', () {
      test('offline has circle_outlined icon', () {
        expect(UserStatus.offline.icon, equals(Icons.circle_outlined));
      });

      test('online has circle icon', () {
        expect(UserStatus.online.icon, equals(Icons.circle));
      });

      test('away has access_time icon', () {
        expect(UserStatus.away.icon, equals(Icons.access_time));
      });

      test('busy has remove_circle icon', () {
        expect(UserStatus.busy.icon, equals(Icons.remove_circle));
      });

      test('doNotDisturb has do_not_disturb_on icon', () {
        expect(UserStatus.doNotDisturb.icon, equals(Icons.do_not_disturb_on));
      });
    });

    group('isActive', () {
      test('online is active', () {
        expect(UserStatus.online.isActive, isTrue);
      });

      test('away is active', () {
        expect(UserStatus.away.isActive, isTrue);
      });

      test('offline is not active', () {
        expect(UserStatus.offline.isActive, isFalse);
      });

      test('busy is not active', () {
        expect(UserStatus.busy.isActive, isFalse);
      });

      test('doNotDisturb is not active', () {
        expect(UserStatus.doNotDisturb.isActive, isFalse);
      });
    });

    group('canReceiveNotifications', () {
      test('online can receive notifications', () {
        expect(UserStatus.online.canReceiveNotifications, isTrue);
      });

      test('away can receive notifications', () {
        expect(UserStatus.away.canReceiveNotifications, isTrue);
      });

      test('busy can receive notifications', () {
        expect(UserStatus.busy.canReceiveNotifications, isTrue);
      });

      test('offline can receive notifications', () {
        expect(UserStatus.offline.canReceiveNotifications, isTrue);
      });

      test('doNotDisturb cannot receive notifications', () {
        expect(UserStatus.doNotDisturb.canReceiveNotifications, isFalse);
      });
    });
  });

  group('UserStatusProfile extension', () {
    test('offline has correct short description', () {
      expect(
        UserStatus.offline.shortDescription,
        equals('Not visible to others'),
      );
    });

    test('online has correct short description', () {
      expect(UserStatus.online.shortDescription, equals('Available to chat'));
    });

    test('away has correct short description', () {
      expect(
        UserStatus.away.shortDescription,
        equals('May be slow to respond'),
      );
    });

    test('busy has correct short description', () {
      expect(UserStatus.busy.shortDescription, equals('Limited availability'));
    });

    test('doNotDisturb has correct short description', () {
      expect(
        UserStatus.doNotDisturb.shortDescription,
        equals('Notifications muted'),
      );
    });
  });
}
