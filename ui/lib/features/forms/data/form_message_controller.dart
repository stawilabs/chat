import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../messages/data/message_providers.dart';
import '../../messages/data/message_sending_service.dart';
import '../../messages/domain/room_event.dart' as domain;
import '../../rooms/data/room_subscription_service.dart';
import '../domain/form_logic.dart';
import '../domain/form_message_models.dart';
import 'form_message_draft_repository.dart';

part 'form_message_controller.g.dart';

enum FormUiMode { editing, review }

class FormMessageUiState {
  const FormMessageUiState({
    required this.form,
    required this.answers,
    required this.currentStep,
    required this.currentSubscriptionId,
    required this.mode,
    required this.reviewConfirmed,
    required this.isSubmitting,
    required this.hydrated,
    required this.validationMessages,
    this.submissionError,
  });

  final FormRequestMessageModel form;
  final Map<String, dynamic> answers;
  final int currentStep;
  final String? currentSubscriptionId;
  final FormUiMode mode;
  final bool reviewConfirmed;
  final bool isSubmitting;
  final bool hydrated;
  final Map<String, String> validationMessages;
  final String? submissionError;

  bool get isReviewing => mode == FormUiMode.review;
  List<int> get visibleStepIndexes =>
      FormLogic.visibleStepIndexes(form.schema, answers);
  bool get hasVisibleSteps => visibleStepIndexes.isNotEmpty;
  int get currentVisibleStepPosition {
    final index = visibleStepIndexes.indexOf(currentStep);
    return index >= 0 ? index : 0;
  }

  bool get isLastStep =>
      !hasVisibleSteps ||
      currentVisibleStepPosition >= visibleStepIndexes.length - 1;
  bool get canEditForm =>
      form.permissions.canEditForSubscription(currentSubscriptionId);
  bool get canSubmitForm =>
      form.permissions.canSubmitForSubscription(currentSubscriptionId);

  FormMessageUiState copyWith({
    Map<String, dynamic>? answers,
    int? currentStep,
    String? currentSubscriptionId,
    FormUiMode? mode,
    bool? reviewConfirmed,
    bool? isSubmitting,
    bool? hydrated,
    Map<String, String>? validationMessages,
    String? submissionError,
    bool clearSubmissionError = false,
  }) {
    return FormMessageUiState(
      form: form,
      answers: answers ?? this.answers,
      currentStep: currentStep ?? this.currentStep,
      currentSubscriptionId:
          currentSubscriptionId ?? this.currentSubscriptionId,
      mode: mode ?? this.mode,
      reviewConfirmed: reviewConfirmed ?? this.reviewConfirmed,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hydrated: hydrated ?? this.hydrated,
      validationMessages: validationMessages ?? this.validationMessages,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
    );
  }
}

typedef FormSubmissionLookup = ({String eventId, String? senderId});

final latestFormSubmissionEventProvider = StreamProvider.autoDispose
    .family<domain.RoomEvent?, FormSubmissionLookup>((ref, params) {
      final repository = ref.watch(messageRepositoryProvider);
      return repository.watchLatestChildEventByType(
        params.eventId,
        domain.RoomEventType.formSubmissionResult,
        senderId: params.senderId,
      );
    });

@riverpod
class FormMessageController extends _$FormMessageController {
  late domain.RoomEvent _message;

  FormMessageDraftRepository get _draftRepository =>
      ref.read(formMessageDraftRepositoryProvider);

  MessageSendingService get _messageSendingService =>
      ref.read(messageSendingServiceProvider);

  @override
  FormMessageUiState build(domain.RoomEvent message) {
    _message = message;
    final form = FormRequestMessageModel.fromContent(message.content);
    final initialAnswers = <String, dynamic>{
      ...form.initialValues,
      ...form.serverDraftValues,
    };

    Future<void>.microtask(_hydrateDraft);

    return FormMessageUiState(
      form: form,
      answers: initialAnswers,
      currentStep: 0,
      currentSubscriptionId: null,
      mode: FormUiMode.editing,
      reviewConfirmed: false,
      isSubmitting: false,
      hydrated: false,
      validationMessages: const {},
    );
  }

  Future<void> _hydrateDraft() async {
    final draftFuture = _draftRepository.getDraft(_message.id);
    final draft = await draftFuture;
    String? currentSubscriptionId;
    try {
      currentSubscriptionId = await ref.read(
        currentUserSubscriptionIdProvider(_message.roomId).future,
      );
    } catch (_) {
      currentSubscriptionId = null;
    }
    if (!ref.mounted) {
      return;
    }

    final draftAnswers = draft == null
        ? state.answers
        : <String, dynamic>{...state.answers, ...draft.answers};
    final normalizedStep = FormLogic.normalizeStepIndex(
      state.form.schema,
      draftAnswers,
      preferredIndex: draft?.currentStep ?? state.currentStep,
    );

    if (draft == null) {
      state = state.copyWith(
        hydrated: true,
        currentSubscriptionId: currentSubscriptionId,
        currentStep: normalizedStep,
      );
      return;
    }

    state = state.copyWith(
      hydrated: true,
      currentSubscriptionId: currentSubscriptionId,
      answers: draftAnswers,
      currentStep: normalizedStep,
      mode: draft.mode == FormDraftMode.review
          ? FormUiMode.review
          : FormUiMode.editing,
    );
  }

  void updateAnswer(String fieldKey, Object? value) {
    if (!state.canEditForm) {
      return;
    }
    final nextAnswers = Map<String, dynamic>.from(state.answers);
    if (value == null) {
      nextAnswers.remove(fieldKey);
    } else {
      nextAnswers[fieldKey] = value;
    }

    state = state.copyWith(
      answers: nextAnswers,
      currentStep: FormLogic.normalizeStepIndex(
        state.form.schema,
        nextAnswers,
        preferredIndex: state.currentStep,
      ),
      validationMessages: {...state.validationMessages}..remove(fieldKey),
      clearSubmissionError: true,
    );
    _persistDraft();
  }

  void nextStep() {
    if (!state.canEditForm) {
      return;
    }
    final issues = FormLogic.validateStep(
      state.form.schema,
      state.currentStep,
      state.answers,
    );
    if (issues.isNotEmpty) {
      state = state.copyWith(
        validationMessages: {
          for (final issue in issues) issue.fieldKey: issue.message,
        },
      );
      return;
    }

    if (state.isLastStep) {
      enterReview();
      return;
    }

    final nextVisible = FormLogic.nextVisibleStepIndex(
      state.form.schema,
      state.answers,
      state.currentStep,
    );
    if (nextVisible == null) {
      enterReview();
      return;
    }

    state = state.copyWith(
      currentStep: nextVisible,
      validationMessages: const {},
    );
    _persistDraft();
  }

  void previousStep() {
    if (!state.canEditForm) {
      return;
    }
    if (state.mode == FormUiMode.review) {
      state = state.copyWith(mode: FormUiMode.editing);
      _persistDraft();
      return;
    }
    if (!state.form.permissions.canGoBack) {
      return;
    }
    final previousVisible = FormLogic.previousVisibleStepIndex(
      state.form.schema,
      state.answers,
      state.currentStep,
    );
    if (previousVisible == null) {
      return;
    }
    state = state.copyWith(currentStep: previousVisible);
    _persistDraft();
  }

  void jumpToStep(int stepIndex) {
    if (!state.canEditForm) {
      return;
    }
    state = state.copyWith(
      currentStep: FormLogic.normalizeStepIndex(
        state.form.schema,
        state.answers,
        preferredIndex: stepIndex.clamp(0, state.form.schema.steps.length - 1),
      ),
      mode: FormUiMode.editing,
    );
    _persistDraft();
  }

  void jumpToStepById(String stepId) {
    final stepIndex = FormLogic.stepIndexById(state.form.schema, stepId);
    if (stepIndex == null) {
      return;
    }
    jumpToStep(stepIndex);
  }

  void enterReview() {
    if (!state.canSubmitForm) {
      state = state.copyWith(
        submissionError:
            'Only the assigned member can review and submit this form.',
      );
      return;
    }
    final issues = FormLogic.validateAll(state.form.schema, state.answers);
    if (issues.isNotEmpty) {
      state = state.copyWith(
        mode: FormUiMode.editing,
        currentStep: issues.first.stepIndex ?? state.currentStep,
        validationMessages: {
          for (final issue in issues) issue.fieldKey: issue.message,
        },
      );
      _persistDraft();
      return;
    }

    state = state.copyWith(
      mode: FormUiMode.review,
      validationMessages: const {},
    );
    _persistDraft();
  }

  void setReviewConfirmed(bool value) {
    if (!state.canSubmitForm) {
      return;
    }
    state = state.copyWith(reviewConfirmed: value, clearSubmissionError: true);
  }

  Future<void> submit() async {
    if (!state.canSubmitForm) {
      state = state.copyWith(
        submissionError: 'Only the assigned member can submit this form.',
      );
      return;
    }
    if (!state.reviewConfirmed) {
      state = state.copyWith(
        submissionError: 'Confirm the reviewed details before submitting.',
      );
      return;
    }

    final issues = FormLogic.validateAll(state.form.schema, state.answers);
    if (issues.isNotEmpty) {
      state = state.copyWith(
        mode: FormUiMode.editing,
        currentStep: issues.first.stepIndex ?? 0,
        validationMessages: {
          for (final issue in issues) issue.fieldKey: issue.message,
        },
      );
      _persistDraft();
      return;
    }

    state = state.copyWith(isSubmitting: true, clearSubmissionError: true);
    try {
      final reviewSections = FormLogic.buildReviewSections(
        state.form.schema,
        state.answers,
      );
      final submission = FormSubmissionResultMessageModel(
        formInstanceId: state.form.formInstanceId,
        schemaId: state.form.schemaId,
        schemaVersion: state.form.schemaVersion,
        sourceEventId: _message.id,
        state: FormMessageState.submitted,
        reviewConfirmed: true,
        submissionSnapshot: FormSubmissionSnapshotModel(
          formInstanceId: state.form.formInstanceId,
          schemaId: state.form.schemaId,
          schemaVersion: state.form.schemaVersion,
          answers: state.answers,
          formattedSections: reviewSections,
          submittedBySubscriptionId: '',
          status: FormMessageState.submitted,
          submittedAt: DateTime.now().toUtc(),
        ),
      );

      await _messageSendingService.sendFormSubmissionResult(
        roomId: _message.roomId,
        parentEventId: _message.id,
        submission: submission,
      );
      await _draftRepository.deleteDraft(_message.id);
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(isSubmitting: false);
    } catch (_) {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(
        isSubmitting: false,
        submissionError: 'Submission failed. Retry from the review screen.',
      );
    }
  }

  Future<void> _persistDraft() {
    if (!state.form.permissions.canSaveDraft || !state.canEditForm) {
      return Future<void>.value();
    }
    return _draftRepository.saveDraft(
      eventId: _message.id,
      roomId: _message.roomId,
      formInstanceId: state.form.formInstanceId,
      answers: state.answers,
      currentStep: state.currentStep,
      mode: state.mode == FormUiMode.review
          ? FormDraftMode.review
          : FormDraftMode.editing,
    );
  }
}
