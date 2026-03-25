/// Background isolates module for offloading heavy operations
///
/// This module provides background isolate implementations for:
/// - Message processing (JSON parsing, validation, deduplication)
/// - Cryptographic operations (hashing, key derivation, HMAC)
/// - Database batch operations (serialization, indexing, filtering)
///
/// Example:
/// ```dart
/// import 'package:chat/core/isolates/isolates.dart';
///
/// // Initialize the isolate manager
/// final manager = IsolateManager.instance;
/// await manager.initialize();
///
/// // Use the message processor
/// final processor = MessageProcessorService(manager);
/// await processor.initialize();
///
/// final result = await processor.processBatch(messages);
/// ```
library;

export 'crypto_isolate.dart';
export 'db_batch_processor.dart';
export 'isolate_manager.dart';
export 'isolate_metrics.dart';
export 'message_processor.dart';
