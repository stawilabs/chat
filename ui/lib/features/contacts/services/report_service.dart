import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xid/xid.dart';

import '../../../core/db/database.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/pending_job.dart';
import '../../../core/sync/pending_job_repository.dart';
import '../../../core/sync/sync_engine.dart';

part 'report_service.g.dart';

/// Report reason categories
enum ReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  inappropriateContent('inappropriate_content', 'Inappropriate Content'),
  other('other', 'Other');

  const ReportReason(this.value, this.displayName);

  final String value;
  final String displayName;

  static ReportReason fromValue(String value) => ReportReason.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ReportReason.other,
  );
}

/// Report status
enum ReportStatus {
  pending('pending'),
  reviewed('reviewed'),
  resolved('resolved'),
  dismissed('dismissed');

  const ReportStatus(this.value);

  final String value;

  static ReportStatus fromValue(String value) => ReportStatus.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ReportStatus.pending,
  );
}

/// Domain model for a user report
class UserReport {
  UserReport({
    required this.id,
    required this.reportedUserId,
    required this.reason,
    required this.reportedAt,
    this.details,
    this.evidenceEventIds,
    this.status = ReportStatus.pending,
  });

  factory UserReport.fromDbRow(Report row) => UserReport(
    id: row.id,
    reportedUserId: row.reportedUserId,
    reason: ReportReason.fromValue(row.reason),
    details: row.details,
    evidenceEventIds: row.evidenceEventIds != null
        ? (jsonDecode(row.evidenceEventIds!) as List<dynamic>).cast<String>()
        : null,
    reportedAt: DateTime.fromMillisecondsSinceEpoch(row.reportedAt),
    status: ReportStatus.fromValue(row.status),
  );

  final String id;
  final String reportedUserId;
  final ReportReason reason;
  final String? details;
  final List<String>? evidenceEventIds;
  final DateTime reportedAt;
  final ReportStatus status;

  ReportsCompanion toCompanion() => ReportsCompanion.insert(
    id: id,
    reportedUserId: reportedUserId,
    reason: reason.value,
    details: Value(details),
    evidenceEventIds: Value(
      evidenceEventIds != null ? jsonEncode(evidenceEventIds) : null,
    ),
    reportedAt: reportedAt.millisecondsSinceEpoch,
    status: Value(status.value),
  );
}

/// Service for reporting users
///
/// Provides functionality to:
/// - Submit reports for spam, harassment, inappropriate content
/// - Store reports locally
/// - Queue reports for server submission
/// - Get report history
class ReportService {
  ReportService(this._database, this._pendingJobRepository);

  final AppDatabase _database;
  final PendingJobRepository _pendingJobRepository;

  // ============================================================================
  // Report Submission
  // ============================================================================

  /// Submit a report against a user
  ///
  /// The report is stored locally and queued for server submission.
  /// Returns the created report.
  Future<UserReport> submitReport({
    required String reportedUserId,
    required ReportReason reason,
    String? details,
    List<String>? evidenceEventIds,
  }) async {
    try {
      AppLogger.info(
        '[ReportService] Submitting report',
        data: {
          'reportedUserId': reportedUserId,
          'reason': reason.value,
          'hasDetails': details != null,
          'evidenceCount': evidenceEventIds?.length ?? 0,
        },
      );

      final report = UserReport(
        id: Xid().toString(),
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        evidenceEventIds: evidenceEventIds,
        reportedAt: DateTime.now(),
      );

      // Save to local database
      await _database.into(_database.reports).insert(report.toCompanion());

      // Queue job for server submission
      await _pendingJobRepository.addJob(JobType.custom, {
        'action': 'submit_report',
        'reportId': report.id,
        'reportedUserId': reportedUserId,
        'reason': reason.value,
        'details': details,
        'evidenceEventIds': evidenceEventIds,
      });

      AppLogger.info(
        '[ReportService] Report submitted successfully',
        data: {'reportId': report.id},
      );

      return report;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ReportService] Failed to submit report',
        error: e,
        stackTrace: stackTrace,
        data: {'reportedUserId': reportedUserId, 'reason': reason.value},
      );
      rethrow;
    }
  }

  /// Submit a report and optionally block the user
  Future<UserReport> submitReportAndBlock({
    required String reportedUserId,
    required ReportReason reason,
    String? details,
    List<String>? evidenceEventIds,
    bool blockUser = false,
  }) async {
    final report = await submitReport(
      reportedUserId: reportedUserId,
      reason: reason,
      details: details,
      evidenceEventIds: evidenceEventIds,
    );

    if (blockUser) {
      // Block the user after reporting
      await (_database.update(_database.roster)
            ..where((t) => t.profileId.equals(reportedUserId)))
          .write(const RosterCompanion(isBlocked: Value(true)));

      AppLogger.info(
        '[ReportService] User blocked after report',
        data: {'reportedUserId': reportedUserId},
      );
    }

    return report;
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Get all reports submitted by the user
  Future<List<UserReport>> getMyReports() async {
    final query = _database.select(_database.reports)
      ..orderBy([(t) => OrderingTerm.desc(t.reportedAt)]);

    final results = await query.get();
    return results.map(UserReport.fromDbRow).toList();
  }

  /// Get reports for a specific user
  Future<List<UserReport>> getReportsForUser(String reportedUserId) async {
    final query = _database.select(_database.reports)
      ..where((t) => t.reportedUserId.equals(reportedUserId))
      ..orderBy([(t) => OrderingTerm.desc(t.reportedAt)]);

    final results = await query.get();
    return results.map(UserReport.fromDbRow).toList();
  }

  /// Check if user has already been reported
  Future<bool> hasReportedUser(String reportedUserId) async {
    final query = _database.select(_database.reports)
      ..where((t) => t.reportedUserId.equals(reportedUserId))
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Get report by ID
  Future<UserReport?> getReport(String reportId) async {
    final query = _database.select(_database.reports)
      ..where((t) => t.id.equals(reportId));

    final result = await query.getSingleOrNull();
    return result != null ? UserReport.fromDbRow(result) : null;
  }

  /// Get count of pending reports
  Future<int> getPendingReportCount() async {
    final query = _database.select(_database.reports)
      ..where((t) => t.status.equals(ReportStatus.pending.value));

    final results = await query.get();
    return results.length;
  }

  // ============================================================================
  // Report Status Management
  // ============================================================================

  /// Update report status (called when server responds)
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    await (_database.update(_database.reports)
          ..where((t) => t.id.equals(reportId)))
        .write(ReportsCompanion(status: Value(status.value)));

    AppLogger.info(
      '[ReportService] Report status updated',
      data: {'reportId': reportId, 'status': status.value},
    );
  }

  /// Delete a local report (e.g., if submission failed permanently)
  Future<void> deleteReport(String reportId) async {
    await (_database.delete(
      _database.reports,
    )..where((t) => t.id.equals(reportId))).go();

    AppLogger.info(
      '[ReportService] Report deleted',
      data: {'reportId': reportId},
    );
  }
}

// ============================================================================
// Providers
// ============================================================================

@riverpod
Future<ReportService> reportService(Ref ref) async {
  final jobRepo = ref.watch(pendingJobRepositoryProvider);
  return ReportService(AppDatabase.instance, jobRepo);
}

/// Provider for all submitted reports
@riverpod
Future<List<UserReport>> myReports(Ref ref) async {
  final service = await ref.watch(reportServiceProvider.future);
  return service.getMyReports();
}

/// Provider to check if a user has been reported
@riverpod
Future<bool> hasReportedUser(Ref ref, String reportedUserId) async {
  final service = await ref.watch(reportServiceProvider.future);
  return service.hasReportedUser(reportedUserId);
}
