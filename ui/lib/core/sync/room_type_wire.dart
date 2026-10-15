import 'package:stawi_api_chat/stawi_api_chat.dart' as pb;

/// Maps the app's local room type to the chat wire enum.
pb.RoomType roomTypeToWire(String local) {
  switch (local) {
    case 'direct':
      return pb.RoomType.ROOM_TYPE_DIRECT;
    case 'channel':
      return pb.RoomType.ROOM_TYPE_CHANNEL;
    case 'bot':
      return pb.RoomType.ROOM_TYPE_BOT;
    default:
      return pb.RoomType.ROOM_TYPE_GROUP;
  }
}

/// Maps the chat wire enum to the app's local room type.
String roomTypeFromWire(pb.RoomType t) {
  if (t == pb.RoomType.ROOM_TYPE_DIRECT) return 'direct';
  if (t == pb.RoomType.ROOM_TYPE_CHANNEL) return 'channel';
  if (t == pb.RoomType.ROOM_TYPE_BOT) return 'bot';
  return 'group';
}
