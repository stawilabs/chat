// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reportService)
final reportServiceProvider = ReportServiceProvider._();

final class ReportServiceProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReportService>,
          ReportService,
          FutureOr<ReportService>
        >
    with $FutureModifier<ReportService>, $FutureProvider<ReportService> {
  ReportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reportServiceHash();

  @$internal
  @override
  $FutureProviderElement<ReportService> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReportService> create(Ref ref) {
    return reportService(ref);
  }
}

String _$reportServiceHash() => r'94ed0317eebc62ef537ee6565aabf233ff5aaddc';

/// Provider for all submitted reports

@ProviderFor(myReports)
final myReportsProvider = MyReportsProvider._();

/// Provider for all submitted reports

final class MyReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserReport>>,
          List<UserReport>,
          FutureOr<List<UserReport>>
        >
    with $FutureModifier<List<UserReport>>, $FutureProvider<List<UserReport>> {
  /// Provider for all submitted reports
  MyReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myReportsHash();

  @$internal
  @override
  $FutureProviderElement<List<UserReport>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserReport>> create(Ref ref) {
    return myReports(ref);
  }
}

String _$myReportsHash() => r'ca13c74f40c2d747a873c15ffa8c5609f581bd45';

/// Provider to check if a user has been reported

@ProviderFor(hasReportedUser)
final hasReportedUserProvider = HasReportedUserFamily._();

/// Provider to check if a user has been reported

final class HasReportedUserProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if a user has been reported
  HasReportedUserProvider._({
    required HasReportedUserFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hasReportedUserProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasReportedUserHash();

  @override
  String toString() {
    return r'hasReportedUserProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return hasReportedUser(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HasReportedUserProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasReportedUserHash() => r'def573c6ab0be8f8ae716f8dd79b841d9b0957ea';

/// Provider to check if a user has been reported

final class HasReportedUserFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  HasReportedUserFamily._()
    : super(
        retry: null,
        name: r'hasReportedUserProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if a user has been reported

  HasReportedUserProvider call(String reportedUserId) =>
      HasReportedUserProvider._(argument: reportedUserId, from: this);

  @override
  String toString() => r'hasReportedUserProvider';
}
