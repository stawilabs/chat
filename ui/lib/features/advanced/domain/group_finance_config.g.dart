// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_finance_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupFinanceConfig _$GroupFinanceConfigFromJson(Map<String, dynamic> json) =>
    _GroupFinanceConfig(
      groupType: $enumDecode(_$GroupTypeEnumMap, json['groupType']),
      groupCurrency: json['groupCurrency'] as String,
      periodType: $enumDecodeNullable(_$PeriodTypeEnumMap, json['periodType']),
      periodicSaving: (json['periodicSaving'] as num?)?.toDouble(),
      groupSavingsDay: json['groupSavingsDay'] == null
          ? null
          : DateTime.parse(json['groupSavingsDay'] as String),
      terminationDate: json['terminationDate'] == null
          ? null
          : DateTime.parse(json['terminationDate'] as String),
      groupTenure: (json['groupTenure'] as num?)?.toInt(),
      registrationFee: (json['registrationFee'] as num?)?.toDouble(),
      membersRequired: (json['membersRequired'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GroupFinanceConfigToJson(_GroupFinanceConfig instance) =>
    <String, dynamic>{
      'groupType': _$GroupTypeEnumMap[instance.groupType]!,
      'groupCurrency': instance.groupCurrency,
      'periodType': _$PeriodTypeEnumMap[instance.periodType],
      'periodicSaving': instance.periodicSaving,
      'groupSavingsDay': instance.groupSavingsDay?.toIso8601String(),
      'terminationDate': instance.terminationDate?.toIso8601String(),
      'groupTenure': instance.groupTenure,
      'registrationFee': instance.registrationFee,
      'membersRequired': instance.membersRequired,
    };

const _$GroupTypeEnumMap = {
  GroupType.grameen: 'grameen',
  GroupType.funding: 'funding',
  GroupType.voluntary: 'voluntary',
  GroupType.temporary: 'temporary',
  GroupType.merryGoRound: 'merryGoRound',
};

const _$PeriodTypeEnumMap = {
  PeriodType.weekly: 'weekly',
  PeriodType.biweekly: 'biweekly',
  PeriodType.monthly: 'monthly',
};
