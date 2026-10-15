import 'package:flutter_test/flutter_test.dart';
import 'package:stawi/core/sync/room_type_wire.dart';
import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

void main() {
  test('room types round-trip between the app and chat', () {
    for (final t in ['direct', 'group', 'channel', 'bot']) {
      expect(roomTypeFromWire(roomTypeToWire(t)), t);
    }
    expect(roomTypeToWire(''), pb.RoomType.ROOM_TYPE_GROUP);
    expect(roomTypeFromWire(pb.RoomType.ROOM_TYPE_UNSPECIFIED), 'group');
  });
}
