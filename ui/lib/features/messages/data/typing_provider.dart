import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/sync_engine.dart';

part 'typing_provider.g.dart';

/// Represents a user who is currently typing
class TypingUser {
  const TypingUser({required this.profileId, required this.displayName});

  final String profileId;
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypingUser &&
          runtimeType == other.runtimeType &&
          profileId == other.profileId;

  @override
  int get hashCode => profileId.hashCode;
}

@riverpod
class Typing extends _$Typing {
  StreamSubscription? _subscription;
  final Map<String, Timer> _typingTimers = {};
  late String _roomId;
  Timer? _sendTypingDebounce;
  DateTime? _lastTypingSent;

  /// Debounce interval for sending typing events to server (3 seconds)
  static const _typingSendInterval = Duration(seconds: 3);

  /// Auto-clear typing after this duration of no updates (5 seconds)
  static const _typingTimeout = Duration(seconds: 5);

  @override
  Set<TypingUser> build(String roomId) {
    _roomId = roomId; // Store room ID for later use
    _init(roomId);
    ref.onDispose(() {
      _subscription?.cancel();
      _sendTypingDebounce?.cancel();
      for (final timer in _typingTimers.values) {
        timer.cancel();
      }
    });
    return {};
  }

  Future<void> _init(String roomId) async {
    final syncEngine = await ref.read(syncEngineProvider.future);
    _subscription = syncEngine.typingEvents.listen((event) {
      if (event.roomId == roomId) {
        // Use subscription ID to identify the user
        final subscriptionId = event.hasSubscriptionId()
            ? event.subscriptionId
            : '';
        if (subscriptionId.isNotEmpty) {
          // Get profile info for this subscription
          _getTypingUserFromSubscription(roomId, subscriptionId).then((
            typingUser,
          ) {
            if (typingUser != null) {
              if (event.typing) {
                _addTypingUser(typingUser);
              } else {
                _removeTypingUser(typingUser.profileId);
              }
            }
          });
        }
      }
    });
  }

  /// Helper method to get TypingUser from subscription ID
  Future<TypingUser?> _getTypingUserFromSubscription(
    String roomId,
    String subscriptionId,
  ) async {
    try {
      final db = AppDatabase.instance;

      // Get member info
      final memberQuery = db.select(db.roomSubscriptions)
        ..where((t) => t.roomId.equals(roomId) & t.id.equals(subscriptionId));
      final member = await memberQuery.getSingleOrNull();
      if (member?.profileId == null) return null;

      // Try to get profile name
      final profileQuery = db.select(db.profiles)
        ..where((p) => p.id.equals(member!.profileId!));
      final profile = await profileQuery.getSingleOrNull();

      // Fall back to roster for display name
      var displayName = profile?.name ?? '';
      if (displayName.isEmpty && member!.contactId != null) {
        final rosterQuery = db.select(db.roster)
          ..where((r) => r.contactId.equals(member.contactId!));
        final roster = await rosterQuery.getSingleOrNull();
        displayName = roster?.displayName ?? roster?.contactDetail ?? '';
      }

      // Final fallback to profile ID
      if (displayName.isEmpty) {
        displayName = member!.profileId!.substring(0, 8);
      }

      return TypingUser(
        profileId: member!.profileId!,
        displayName: displayName,
      );
    } catch (e) {
      // If we can't find the member, return null
      return null;
    }
  }

  void _addTypingUser(TypingUser user) {
    final existing = state.firstWhere(
      (u) => u.profileId == user.profileId,
      orElse: () => user,
    );

    if (state.contains(existing)) {
      // Reset timer
      _typingTimers[user.profileId]?.cancel();
    } else {
      state = {...state, user};
    }

    // Auto-remove after timeout
    _typingTimers[user.profileId] = Timer(_typingTimeout, () {
      _removeTypingUser(user.profileId);
    });
  }

  void _removeTypingUser(String profileId) {
    _typingTimers[profileId]?.cancel();
    _typingTimers.remove(profileId);
    final existing = state.where((u) => u.profileId == profileId).toSet();
    if (existing.isNotEmpty) {
      state = state.difference(existing);
    }
  }

  /// Send typing event to server with debouncing
  ///
  /// When [isTyping] is true, events are throttled to every 3 seconds
  /// to avoid excessive network traffic while still providing real-time feedback.
  Future<void> sendTyping(bool isTyping) async {
    if (isTyping) {
      // Throttle: only send if enough time has passed since last send
      final now = DateTime.now();
      if (_lastTypingSent != null &&
          now.difference(_lastTypingSent!) < _typingSendInterval) {
        // Skip this event, but schedule one for later if needed
        _sendTypingDebounce?.cancel();
        _sendTypingDebounce = Timer(
          _typingSendInterval - now.difference(_lastTypingSent!),
          () => _doSendTyping(true),
        );
        return;
      }
      await _doSendTyping(true);
    } else {
      // Always send stop typing immediately
      _sendTypingDebounce?.cancel();
      await _doSendTyping(false);
    }
  }

  Future<void> _doSendTyping(bool isTyping) async {
    try {
      _lastTypingSent = DateTime.now();
      final syncEngine = await ref.read(syncEngineProvider.future);
      await syncEngine.sendTyping(_roomId, isTyping);
    } catch (e) {
      // Silently fail for typing events - they're not critical
      AppLogger.error('Failed to send typing event', error: e);
    }
  }
}
