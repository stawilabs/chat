import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';

/// Repository for managing message draft persistence
///
/// Drafts are automatically saved as users type and restored when
/// they return to a chat room. Each room can have one draft at a time.
class DraftRepository {
  DraftRepository(this._database);

  final AppDatabase _database;

  /// Get the draft for a specific room
  ///
  /// Returns null if no draft exists for the room.
  Future<Draft?> getDraft(String roomId) async {
    return (_database.drafts.select()..where((d) => d.roomId.equals(roomId)))
        .getSingleOrNull();
  }

  /// Watch the draft for a specific room
  ///
  /// Returns a stream that emits the current draft or null.
  Stream<Draft?> watchDraft(String roomId) {
    return (_database.drafts.select()..where((d) => d.roomId.equals(roomId)))
        .watchSingleOrNull();
  }

  /// Save or update a draft for a room
  ///
  /// If the content is empty, the draft is deleted instead.
  /// The [replyToId] is optional and stores the ID of the message
  /// being replied to, if any.
  Future<void> saveDraft({
    required String roomId,
    required String content,
    String? replyToId,
  }) async {
    final trimmedContent = content.trim();

    // Delete draft if content is empty
    if (trimmedContent.isEmpty) {
      await deleteDraft(roomId);
      return;
    }

    await _database.drafts.insertOne(
      DraftsCompanion.insert(
        roomId: roomId,
        content: trimmedContent,
        replyToId: Value(replyToId),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Delete the draft for a specific room
  ///
  /// Called when a message is sent or when the user clears the draft.
  Future<void> deleteDraft(String roomId) async {
    await (_database.drafts.delete()..where((d) => d.roomId.equals(roomId)))
        .go();
  }

  /// Get all rooms that have drafts
  ///
  /// Returns a list of room IDs that have unsent drafts.
  Future<List<String>> getRoomsWithDrafts() async {
    final drafts = await _database.drafts.select().get();
    return drafts.map((d) => d.roomId).toList();
  }

  /// Watch all drafts
  ///
  /// Returns a stream of all drafts, useful for showing draft
  /// indicators in the room list.
  Stream<List<Draft>> watchAllDrafts() {
    return _database.drafts.select().watch();
  }

  /// Get drafts as a map for efficient lookup
  ///
  /// Returns a map from room ID to draft content.
  Future<Map<String, String>> getDraftsMap() async {
    final drafts = await _database.drafts.select().get();
    return {for (final d in drafts) d.roomId: d.content};
  }

  /// Watch drafts as a map for efficient lookup
  ///
  /// Returns a stream of maps from room ID to draft content.
  Stream<Map<String, String>> watchDraftsMap() {
    return _database.drafts.select().watch().map(
      (drafts) => {for (final d in drafts) d.roomId: d.content},
    );
  }

  /// Clear all drafts
  ///
  /// Used when logging out or clearing app data.
  Future<void> clearAllDrafts() async {
    await _database.drafts.delete().go();
  }
}

/// Provider for DraftRepository
final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return DraftRepository(AppDatabase.instance);
});

/// Provider to watch the draft for a specific room
final roomDraftProvider = StreamProvider.family<Draft?, String>((ref, roomId) {
  final repository = ref.watch(draftRepositoryProvider);
  return repository.watchDraft(roomId);
});

/// Provider to watch all drafts as a map
final draftsMapProvider = StreamProvider<Map<String, String>>((ref) {
  final repository = ref.watch(draftRepositoryProvider);
  return repository.watchDraftsMap();
});
