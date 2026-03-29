//
//  Generated code. Do not modify.
//  source: gnostic/openapi/v3/annotations.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'openapiv3.pb.dart' as $6;

class Annotations {
  static final document = $pb.Extension<$6.Document>(_omitMessageNames ? '' : 'google.protobuf.FileOptions', _omitFieldNames ? '' : 'document', 1143, $pb.PbFieldType.OM, defaultOrMaker: $6.Document.getDefault, subBuilder: $6.Document.create);
  static final operation = $pb.Extension<$6.Operation>(_omitMessageNames ? '' : 'google.protobuf.MethodOptions', _omitFieldNames ? '' : 'operation', 1143, $pb.PbFieldType.OM, defaultOrMaker: $6.Operation.getDefault, subBuilder: $6.Operation.create);
  static final schema = $pb.Extension<$6.Schema>(_omitMessageNames ? '' : 'google.protobuf.MessageOptions', _omitFieldNames ? '' : 'schema', 1143, $pb.PbFieldType.OM, defaultOrMaker: $6.Schema.getDefault, subBuilder: $6.Schema.create);
  static final property = $pb.Extension<$6.Schema>(_omitMessageNames ? '' : 'google.protobuf.FieldOptions', _omitFieldNames ? '' : 'property', 1143, $pb.PbFieldType.OM, defaultOrMaker: $6.Schema.getDefault, subBuilder: $6.Schema.create);
  static void registerAllExtensions($pb.ExtensionRegistry registry) {
    registry.add(document);
    registry.add(operation);
    registry.add(schema);
    registry.add(property);
  }
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
