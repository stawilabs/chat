// This is a generated file - do not edit.
//
// Generated from common/v1/permissions.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'permissions.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'permissions.pbenum.dart';

/// RoleBinding maps a standard role to the permissions it grants within a service.
/// Used to generate OPL permit functions and enforce role-based access control.
class RoleBinding extends $pb.GeneratedMessage {
  factory RoleBinding({
    StandardRole? role,
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = create();
    if (role != null) result.role = role;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  RoleBinding._();

  factory RoleBinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RoleBinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RoleBinding',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..e<StandardRole>(1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: StandardRole.ROLE_UNSPECIFIED,
        valueOf: StandardRole.valueOf,
        enumValues: StandardRole.values)
    ..pPS(2, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleBinding clone() => RoleBinding()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoleBinding copyWith(void Function(RoleBinding) updates) =>
      super.copyWith((message) => updates(message as RoleBinding))
          as RoleBinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoleBinding create() => RoleBinding._();
  @$core.override
  RoleBinding createEmptyInstance() => create();
  static $pb.PbList<RoleBinding> createRepeated() => $pb.PbList<RoleBinding>();
  @$core.pragma('dart2js:noInline')
  static RoleBinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RoleBinding>(create);
  static RoleBinding? _defaultInstance;

  /// The role being granted permissions.
  @$pb.TagNumber(1)
  StandardRole get role => $_getN(0);
  @$pb.TagNumber(1)
  set role(StandardRole value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$pb.TagNumber(1)
  void clearRole() => $_clearField(1);

  /// Permissions granted to this role. Must be a subset of ServicePermissions.permissions.
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get permissions => $_getList(1);
}

/// MethodPermissions declares access control requirements for an RPC method.
class MethodPermissions extends $pb.GeneratedMessage {
  factory MethodPermissions({
    $core.Iterable<$core.String>? permissions,
    $core.bool? allowUnauthenticated,
  }) {
    final result = create();
    if (permissions != null) result.permissions.addAll(permissions);
    if (allowUnauthenticated != null)
      result.allowUnauthenticated = allowUnauthenticated;
    return result;
  }

  MethodPermissions._();

  factory MethodPermissions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MethodPermissions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MethodPermissions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'permissions')
    ..aOB(2, _omitFieldNames ? '' : 'allowUnauthenticated')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MethodPermissions clone() => MethodPermissions()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MethodPermissions copyWith(void Function(MethodPermissions) updates) =>
      super.copyWith((message) => updates(message as MethodPermissions))
          as MethodPermissions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MethodPermissions create() => MethodPermissions._();
  @$core.override
  MethodPermissions createEmptyInstance() => create();
  static $pb.PbList<MethodPermissions> createRepeated() =>
      $pb.PbList<MethodPermissions>();
  @$core.pragma('dart2js:noInline')
  static MethodPermissions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MethodPermissions>(create);
  static MethodPermissions? _defaultInstance;

  /// Permissions required to call this method, e.g. "profile_view", "contact_manage".
  /// All listed permissions must be satisfied (AND logic).
  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get permissions => $_getList(0);

  /// If true, the method can be called without authentication.
  @$pb.TagNumber(2)
  $core.bool get allowUnauthenticated => $_getBF(1);
  @$pb.TagNumber(2)
  set allowUnauthenticated($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAllowUnauthenticated() => $_has(1);
  @$pb.TagNumber(2)
  void clearAllowUnauthenticated() => $_clearField(2);
}

/// ServicePermissions declares all permissions a service requires to function.
/// This serves as a registry of permissions that must be provisioned for the service,
/// and includes role bindings for OPL generation and authorization enforcement.
class ServicePermissions extends $pb.GeneratedMessage {
  factory ServicePermissions({
    $core.String? namespace,
    $core.Iterable<$core.String>? permissions,
    $core.Iterable<RoleBinding>? roleBindings,
  }) {
    final result = create();
    if (namespace != null) result.namespace = namespace;
    if (permissions != null) result.permissions.addAll(permissions);
    if (roleBindings != null) result.roleBindings.addAll(roleBindings);
    return result;
  }

  ServicePermissions._();

  factory ServicePermissions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServicePermissions.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServicePermissions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'common.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'namespace')
    ..pPS(2, _omitFieldNames ? '' : 'permissions')
    ..pc<RoleBinding>(
        3, _omitFieldNames ? '' : 'roleBindings', $pb.PbFieldType.PM,
        subBuilder: RoleBinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServicePermissions clone() => ServicePermissions()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServicePermissions copyWith(void Function(ServicePermissions) updates) =>
      super.copyWith((message) => updates(message as ServicePermissions))
          as ServicePermissions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServicePermissions create() => ServicePermissions._();
  @$core.override
  ServicePermissions createEmptyInstance() => create();
  static $pb.PbList<ServicePermissions> createRepeated() =>
      $pb.PbList<ServicePermissions>();
  @$core.pragma('dart2js:noInline')
  static ServicePermissions getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServicePermissions>(create);
  static ServicePermissions? _defaultInstance;

  /// Namespace for this service's permissions, used for OPL namespace generation
  /// and ensuring consistency across authorization systems.
  /// e.g. "service_profile", "service_payment", "service_partition".
  @$pb.TagNumber(1)
  $core.String get namespace => $_getSZ(0);
  @$pb.TagNumber(1)
  set namespace($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNamespace() => $_has(0);
  @$pb.TagNumber(1)
  void clearNamespace() => $_clearField(1);

  /// All permissions this service needs, e.g. "profile_view", "profile_create".
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get permissions => $_getList(1);

  /// Role-to-permission mappings for this service. Used to generate OPL permit
  /// functions and for runtime role-based access control.
  @$pb.TagNumber(3)
  $pb.PbList<RoleBinding> get roleBindings => $_getList(2);
}

class Permissions {
  static final methodPermissions = $pb.Extension<MethodPermissions>(
      _omitMessageNames ? '' : 'google.protobuf.MethodOptions',
      _omitFieldNames ? '' : 'methodPermissions',
      50000,
      $pb.PbFieldType.OM,
      defaultOrMaker: MethodPermissions.getDefault,
      subBuilder: MethodPermissions.create);
  static final servicePermissions = $pb.Extension<ServicePermissions>(
      _omitMessageNames ? '' : 'google.protobuf.ServiceOptions',
      _omitFieldNames ? '' : 'servicePermissions',
      50000,
      $pb.PbFieldType.OM,
      defaultOrMaker: ServicePermissions.getDefault,
      subBuilder: ServicePermissions.create);
  static void registerAllExtensions($pb.ExtensionRegistry registry) {
    registry.add(methodPermissions);
    registry.add(servicePermissions);
  }
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
