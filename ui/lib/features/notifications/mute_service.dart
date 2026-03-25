import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../rooms/data/room_repository.dart';
import '../rooms/data/room_service.dart';
import '../rooms/domain/room.dart';

part 'mute_service.g.dart';

/// Service for managing room mute/unmute functionality
///
/// Handles muting and unmuting notifications for specific chat rooms.
/// Mute state is persisted in the local database and checked before
/// showing notifications.
///
/// Example:
/// ```dart
/// final muteService = ref.read(muteServiceProvider);
///
/// // Mute a room for 8 hours
/// await muteService.muteRoom('room-123', MuteDuration.eightHours);
///
/// // Check if muted
/// final isMuted = await muteService.isRoomMuted('room-123');
///
/// // Unmute
/// await muteService.unmuteRoom('room-123');
/// ```
class MuteService {
  MuteService(this._roomRepository);

  final RoomRepository _roomRepository;

  /// Mute notifications for a room
  ///
  /// [roomId] - The ID of the room to mute
  /// [duration] - How long to mute the room
  ///
  /// Duration options:
  /// - [MuteDuration.eightHours] - Mute for 8 hours
  /// - [MuteDuration.oneWeek] - Mute for 1 week
  /// - [MuteDuration.forever] - Mute until manually unmuted
  Future<void> muteRoom(String roomId, MuteDuration duration) async {
    try {
      final mutedUntil = duration.getMutedUntilTimestamp();
      await _roomRepository.updateMutedUntil(roomId, mutedUntil);

      AppLogger.info(
        'Room muted',
        data: {
          'roomId': roomId,
          'duration': duration.label,
          'mutedUntil': mutedUntil,
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to mute room',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      rethrow;
    }
  }

  /// Unmute notifications for a room
  ///
  /// [roomId] - The ID of the room to unmute
  Future<void> unmuteRoom(String roomId) async {
    try {
      await _roomRepository.updateMutedUntil(roomId, null);

      AppLogger.info('Room unmuted', data: {'roomId': roomId});
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to unmute room',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      rethrow;
    }
  }

  /// Check if a room is currently muted
  ///
  /// Returns true if:
  /// - mutedUntil is 0 (muted forever)
  /// - mutedUntil is a future timestamp
  ///
  /// Also handles expired mutes by returning false when the mute
  /// period has elapsed.
  Future<bool> isRoomMuted(String roomId) async {
    try {
      return await _roomRepository.isRoomMuted(roomId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to check mute status',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      // Default to not muted on error
      return false;
    }
  }

  /// Get the muted until timestamp for a room
  ///
  /// Returns:
  /// - null if not muted
  /// - 0 if muted forever
  /// - timestamp if muted until a specific time
  Future<int?> getMutedUntil(String roomId) async {
    try {
      return await _roomRepository.getMutedUntil(roomId);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to get muted until',
        error: e,
        stackTrace: stackTrace,
        data: {'roomId': roomId},
      );
      return null;
    }
  }

  /// Get a human-readable description of when the mute will expire
  ///
  /// Returns null if not muted, "Forever" if muted forever,
  /// or a time remaining string like "2h 30m" if muted until a specific time.
  Future<String?> getMuteTimeRemaining(String roomId) async {
    final mutedUntil = await getMutedUntil(roomId);

    if (mutedUntil == null) return null;
    if (mutedUntil == 0) return 'Forever';

    final remaining = mutedUntil - DateTime.now().millisecondsSinceEpoch;
    if (remaining <= 0) return null;

    final duration = Duration(milliseconds: remaining);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

/// Provider for MuteService
@riverpod
MuteService muteService(Ref ref) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  return MuteService(roomRepository);
}

/// Provider to check if a specific room is muted
@riverpod
Future<bool> isRoomMuted(Ref ref, String roomId) async {
  final muteService = ref.watch(muteServiceProvider);
  return muteService.isRoomMuted(roomId);
}

/// Provider to get mute time remaining for a room
@riverpod
Future<String?> muteTimeRemaining(Ref ref, String roomId) async {
  final muteService = ref.watch(muteServiceProvider);
  return muteService.getMuteTimeRemaining(roomId);
}

/// Notifier for managing room mute state
///
/// Use this when you need to reactively update UI based on mute state changes.
@riverpod
class RoomMuteState extends _$RoomMuteState {
  late String _roomId;

  @override
  Future<bool> build(String roomId) async {
    _roomId = roomId;
    final muteService = ref.watch(muteServiceProvider);
    return muteService.isRoomMuted(roomId);
  }

  /// Mute the room with the specified duration
  Future<void> mute(MuteDuration duration) async {
    final muteService = ref.read(muteServiceProvider);
    await muteService.muteRoom(_roomId, duration);
    ref.invalidateSelf();
  }

  /// Unmute the room
  Future<void> unmute() async {
    final muteService = ref.read(muteServiceProvider);
    await muteService.unmuteRoom(_roomId);
    ref.invalidateSelf();
  }
}
