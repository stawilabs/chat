// ignore_for_file: sort_constructors_first

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database.dart';

enum FormDraftMode { editing, review }

class FormMessageDraftSnapshot {
  const FormMessageDraftSnapshot({
    required this.eventId,
    required this.roomId,
    required this.formInstanceId,
    required this.answers,
    required this.currentStep,
    required this.mode,
    required this.updatedAt,
  });

  final String eventId;
  final String roomId;
  final String formInstanceId;
  final Map<String, dynamic> answers;
  final int currentStep;
  final FormDraftMode mode;
  final int updatedAt;

  factory FormMessageDraftSnapshot.fromRow(FormMessageDraft row) {
    return FormMessageDraftSnapshot(
      eventId: row.eventId,
      roomId: row.roomId,
      formInstanceId: row.formInstanceId,
      answers: jsonDecode(row.answersJson) as Map<String, dynamic>,
      currentStep: row.currentStep,
      mode: row.mode == 'review' ? FormDraftMode.review : FormDraftMode.editing,
      updatedAt: row.updatedAt,
    );
  }
}

class FormMessageDraftRepository {
  FormMessageDraftRepository(this._database);

  final AppDatabase _database;

  Stream<FormMessageDraftSnapshot?> watchDraft(String eventId) {
    return (_database.formMessageDrafts.select()
          ..where((draft) => draft.eventId.equals(eventId)))
        .watchSingleOrNull()
        .map(
          (row) => row == null ? null : FormMessageDraftSnapshot.fromRow(row),
        );
  }

  Future<FormMessageDraftSnapshot?> getDraft(String eventId) async {
    final row =
        await (_database.formMessageDrafts.select()
              ..where((draft) => draft.eventId.equals(eventId)))
            .getSingleOrNull();
    return row == null ? null : FormMessageDraftSnapshot.fromRow(row);
  }

  Future<void> saveDraft({
    required String eventId,
    required String roomId,
    required String formInstanceId,
    required Map<String, dynamic> answers,
    required int currentStep,
    required FormDraftMode mode,
  }) async {
    await _database.formMessageDrafts.insertOne(
      FormMessageDraftsCompanion.insert(
        eventId: eventId,
        roomId: roomId,
        formInstanceId: formInstanceId,
        answersJson: jsonEncode(answers),
        currentStep: Value(currentStep),
        mode: Value(mode.name),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteDraft(String eventId) async {
    await (_database.formMessageDrafts.delete()
          ..where((draft) => draft.eventId.equals(eventId)))
        .go();
  }
}

final formMessageDraftRepositoryProvider =
    Provider<FormMessageDraftRepository>((ref) {
      return FormMessageDraftRepository(AppDatabase.instance);
    });
