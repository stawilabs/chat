import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/rooms/domain/room.dart';

void main() {
  group('Room member limit', () {
    test('defaultMemberLimit is 256', () {
      expect(defaultMemberLimit, equals(256));
    });

    test('effectiveMemberLimit returns memberLimit when set', () {
      const room = Room(
        id: 'test-room',
        name: 'Test Room',
        type: 'group',
        memberLimit: 100,
      );
      expect(room.effectiveMemberLimit, equals(100));
    });

    test('effectiveMemberLimit returns default when memberLimit is null', () {
      const room = Room(id: 'test-room', name: 'Test Room', type: 'group');
      expect(room.effectiveMemberLimit, equals(defaultMemberLimit));
    });

    test('isGroup returns true for group type', () {
      const room = Room(id: 'test-room', name: 'Test Room', type: 'group');
      expect(room.isGroup, isTrue);
      expect(room.isDirect, isFalse);
    });

    test('isDirect returns true for direct type', () {
      const room = Room(id: 'test-room', name: 'Test Room', type: 'direct');
      expect(room.isDirect, isTrue);
      expect(room.isGroup, isFalse);
    });

    group('canAddMembers', () {
      test('returns true when limit not reached', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
        );
        expect(room.canAddMembers(5), isTrue);
        expect(room.canAddMembers(9), isTrue);
      });

      test('returns false when limit reached', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
        );
        expect(room.canAddMembers(10), isFalse);
        expect(room.canAddMembers(15), isFalse);
      });

      test('returns true when limit disabled', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
          memberLimitEnabled: false,
        );
        expect(room.canAddMembers(100), isTrue);
      });
    });

    group('getRemainingSlots', () {
      test('returns correct remaining slots', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
        );
        expect(room.getRemainingSlots(5), equals(5));
        expect(room.getRemainingSlots(9), equals(1));
        expect(room.getRemainingSlots(0), equals(10));
      });

      test('returns 0 when at or over limit', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
        );
        expect(room.getRemainingSlots(10), equals(0));
        expect(room.getRemainingSlots(15), equals(0));
      });

      test('returns default limit when limit disabled', () {
        const room = Room(
          id: 'test-room',
          name: 'Test Room',
          type: 'group',
          memberLimit: 10,
          memberLimitEnabled: false,
        );
        expect(room.getRemainingSlots(100), equals(defaultMemberLimit));
      });
    });

    test('memberLimitEnabled defaults to true', () {
      const room = Room(id: 'test-room', name: 'Test Room', type: 'group');
      expect(room.memberLimitEnabled, isTrue);
    });
  });
}
