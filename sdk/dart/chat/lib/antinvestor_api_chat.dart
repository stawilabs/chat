/// Dart client library for Ant Investor Chat Service.
///
/// Provides Chat service functionality using Connect RPC protocol.
library;

// Chat service
export 'src/chat/v1/chat.pb.dart';
export 'src/chat/v1/chat.pbenum.dart';
export 'src/chat/v1/chat.pbjson.dart';
export 'src/chat/v1/chat.connect.client.dart';
export 'src/chat/v1/chat.connect.spec.dart';

// Chat definitions
export 'src/chat/v1/definitions.pb.dart';
export 'src/chat/v1/definitions.pbenum.dart';

// Chat gateway
export 'src/chat/v1/gateway.pb.dart';
export 'src/chat/v1/gateway.pbenum.dart';
export 'src/chat/v1/gateway.connect.client.dart';
export 'src/chat/v1/gateway.connect.spec.dart';

// Chat payload types
export 'src/chat/v1/payload_type.pb.dart';
export 'src/chat/v1/payload_type.pbenum.dart';

// Common types
export 'src/common/v1/common.pb.dart';
export 'src/common/v1/common.pbenum.dart';
export 'src/google/protobuf/struct.pb.dart';
export 'src/google/protobuf/timestamp.pb.dart';
