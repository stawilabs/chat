import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/features/messages/domain/room_event.dart';

void main() {
  group('RoomEventType storage and wire compatibility', () {
    test('storage codes are unique and explicit', () {
      final codes = RoomEventType.values
          .map((type) => type.storageCode)
          .toList();
      expect(codes.toSet().length, equals(codes.length));
    });

    test('wire names are unique and explicit', () {
      final wireNames = RoomEventType.values
          .map((type) => type.wireName)
          .toList();
      expect(wireNames.toSet().length, equals(wireNames.length));
    });

    test('supports legacy and current wire names', () {
      expect(
        tryRoomEventTypeFromWireName('RoomEventType.groupCallStageUpdate'),
        equals(RoomEventType.groupCallStageUpdate),
      );
      expect(
        tryRoomEventTypeFromWireName('groupCallStageUpdate'),
        equals(RoomEventType.groupCallStageUpdate),
      );
    });

    test('unknown storage code decodes to unknown', () {
      expect(roomEventTypeFromStorageCode(999), equals(RoomEventType.unknown));
    });
  });
}
