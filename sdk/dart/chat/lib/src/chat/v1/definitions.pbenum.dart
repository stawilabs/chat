// This is a generated file - do not edit.
//
// Generated from chat/v1/definitions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Allowed message types. Extendable via new enum values; clients must ignore unknown values.
class RoomEventType extends $pb.ProtobufEnum {
  static const RoomEventType ROOM_EVENT_TYPE_UNSPECIFIED =
      RoomEventType._(0, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_UNSPECIFIED');
  static const RoomEventType ROOM_EVENT_TYPE_SYSTEM =
      RoomEventType._(1, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_SYSTEM');
  static const RoomEventType ROOM_EVENT_TYPE_EVENT =
      RoomEventType._(2, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_EVENT');
  static const RoomEventType ROOM_EVENT_TYPE_MESSAGE =
      RoomEventType._(3, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_MESSAGE');
  static const RoomEventType ROOM_EVENT_TYPE_REACTION =
      RoomEventType._(4, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_REACTION');
  static const RoomEventType ROOM_EVENT_TYPE_TYPING =
      RoomEventType._(5, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_TYPING');
  static const RoomEventType ROOM_EVENT_TYPE_DELIVERED =
      RoomEventType._(6, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_DELIVERED');
  static const RoomEventType ROOM_EVENT_TYPE_READ =
      RoomEventType._(7, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_READ');
  static const RoomEventType ROOM_EVENT_TYPE_MOTION =
      RoomEventType._(8, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_MOTION');
  static const RoomEventType ROOM_EVENT_TYPE_CALL =
      RoomEventType._(10, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_CALL');
  static const RoomEventType ROOM_EVENT_TYPE_ADVERT =
      RoomEventType._(20, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_ADVERT');
  static const RoomEventType ROOM_EVENT_TYPE_FORM_REQUEST =
      RoomEventType._(30, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_FORM_REQUEST');
  static const RoomEventType ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT =
      RoomEventType._(
          31, _omitEnumNames ? '' : 'ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT');

  static const $core.List<RoomEventType> values = <RoomEventType>[
    ROOM_EVENT_TYPE_UNSPECIFIED,
    ROOM_EVENT_TYPE_SYSTEM,
    ROOM_EVENT_TYPE_EVENT,
    ROOM_EVENT_TYPE_MESSAGE,
    ROOM_EVENT_TYPE_REACTION,
    ROOM_EVENT_TYPE_TYPING,
    ROOM_EVENT_TYPE_DELIVERED,
    ROOM_EVENT_TYPE_READ,
    ROOM_EVENT_TYPE_MOTION,
    ROOM_EVENT_TYPE_CALL,
    ROOM_EVENT_TYPE_ADVERT,
    ROOM_EVENT_TYPE_FORM_REQUEST,
    ROOM_EVENT_TYPE_FORM_SUBMISSION_RESULT,
  ];

  static final $core.Map<$core.int, RoomEventType> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static RoomEventType? valueOf($core.int value) => _byValue[value];

  const RoomEventType._(super.value, super.name);
}

class PresenceStatus extends $pb.ProtobufEnum {
  static const PresenceStatus PRESENCE_STATUS_UNSPECIFIED =
      PresenceStatus._(0, _omitEnumNames ? '' : 'PRESENCE_STATUS_UNSPECIFIED');
  static const PresenceStatus PRESENCE_STATUS_OFFLINE =
      PresenceStatus._(1, _omitEnumNames ? '' : 'PRESENCE_STATUS_OFFLINE');
  static const PresenceStatus PRESENCE_STATUS_ONLINE =
      PresenceStatus._(2, _omitEnumNames ? '' : 'PRESENCE_STATUS_ONLINE');

  static const $core.List<PresenceStatus> values = <PresenceStatus>[
    PRESENCE_STATUS_UNSPECIFIED,
    PRESENCE_STATUS_OFFLINE,
    PRESENCE_STATUS_ONLINE,
  ];

  static final $core.List<PresenceStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PresenceStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PresenceStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
