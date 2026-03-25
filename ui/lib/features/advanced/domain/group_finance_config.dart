import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_finance_config.freezed.dart';
part 'group_finance_config.g.dart';

/// Types of financial groups supported
enum GroupType {
  grameen,
  funding,
  voluntary,
  temporary,
  merryGoRound;

  String get displayName => switch (this) {
    GroupType.grameen => 'Grameen (Table Banking)',
    GroupType.funding => 'Funding',
    GroupType.voluntary => 'Voluntary Savings',
    GroupType.temporary => 'Temporary',
    GroupType.merryGoRound => 'Merry-Go-Round',
  };

  String get description => switch (this) {
    GroupType.grameen =>
      'Members save periodically and can borrow from the pool at low interest rates.',
    GroupType.funding => 'Members contribute towards a common goal or fund.',
    GroupType.voluntary =>
      'Members save voluntarily with no fixed schedule or amount.',
    GroupType.temporary =>
      'Time-bound group that terminates on a specific date.',
    GroupType.merryGoRound =>
      'Members take turns receiving the total periodic contribution (ROSCA).',
  };

  bool get requiresPeriodicity => switch (this) {
    GroupType.grameen || GroupType.merryGoRound => true,
    _ => false,
  };

  bool get requiresTerminationDate => this == GroupType.temporary;
}

/// Periodicity options for savings cycles
enum PeriodType {
  weekly,
  biweekly,
  monthly;

  String get displayName => switch (this) {
    PeriodType.weekly => 'Weekly',
    PeriodType.biweekly => 'Bi-weekly',
    PeriodType.monthly => 'Monthly',
  };
}

/// Configuration for a financial group
@freezed
abstract class GroupFinanceConfig with _$GroupFinanceConfig {
  const factory GroupFinanceConfig({
    required GroupType groupType,
    required String groupCurrency,
    PeriodType? periodType,
    double? periodicSaving,
    DateTime? groupSavingsDay,
    DateTime? terminationDate,
    int? groupTenure,
    double? registrationFee,
    int? membersRequired,
  }) = _GroupFinanceConfig;

  factory GroupFinanceConfig.fromJson(Map<String, dynamic> json) =>
      _$GroupFinanceConfigFromJson(json);

  const GroupFinanceConfig._();

  /// Validate configuration and return list of error messages
  List<String> validate() {
    final errors = <String>[];

    if (groupCurrency.trim().isEmpty) {
      errors.add('Currency is required');
    }

    if (groupType.requiresPeriodicity) {
      if (periodType == null) {
        errors.add('Period type is required for ${groupType.displayName}');
      }
      if (periodicSaving == null || periodicSaving! <= 0) {
        errors.add('Periodic saving amount must be greater than 0');
      }
    }

    if (groupType.requiresTerminationDate) {
      if (terminationDate == null) {
        errors.add('Termination date is required for temporary groups');
      } else if (terminationDate!.isBefore(DateTime.now())) {
        errors.add('Termination date must be in the future');
      }
    }

    if (registrationFee != null && registrationFee! < 0) {
      errors.add('Registration fee cannot be negative');
    }

    if (membersRequired != null && membersRequired! < 2) {
      errors.add('At least 2 members are required');
    }

    return errors;
  }

  /// Whether the configuration is valid
  bool get isValid => validate().isEmpty;

  /// Compact summary string for display
  String get summary {
    final parts = <String>[groupType.displayName, groupCurrency];
    if (periodType != null) parts.add(periodType!.displayName);
    if (periodicSaving != null) {
      parts.add('$groupCurrency ${periodicSaving!.toStringAsFixed(0)}');
    }
    return parts.join(' \u00b7 ');
  }
}
