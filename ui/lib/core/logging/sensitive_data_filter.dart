/// Filters and masks sensitive data from log messages and data maps
///
/// Ensures that sensitive information like passwords, tokens, keys,
/// and personal information are not logged in plain text.
class SensitiveDataFilter {
  /// Patterns that indicate sensitive field names (case-insensitive)
  static const List<String> _sensitiveFieldPatterns = [
    'password',
    'passwd',
    'secret',
    'token',
    'api_key',
    'apikey',
    'api-key',
    'access_token',
    'refresh_token',
    'auth',
    'authorization',
    'bearer',
    'credential',
    'private_key',
    'privatekey',
    'private-key',
    'ssn',
    'social_security',
    'credit_card',
    'creditcard',
    'card_number',
    'cvv',
    'cvc',
    'pin',
    'otp',
    'phone',
    'email',
    'address',
    'account_number',
    'routing_number',
    'bank_account',
  ];

  /// Regex patterns for detecting sensitive data in strings
  static final List<RegExp> _sensitiveValuePatterns = [
    // Email addresses
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    // Phone numbers (various formats)
    RegExp(
      r'\b\+?[0-9]{1,3}[-.\s]?\(?[0-9]{2,3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}\b',
    ),
    // Credit card numbers (16 digits, with or without separators)
    RegExp(r'\b(?:\d{4}[-\s]?){3}\d{4}\b'),
    // JWT tokens (three base64 segments separated by dots)
    RegExp(r'\beyJ[A-Za-z0-9_-]*\.eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\b'),
    // Bearer tokens
    RegExp(r'\bBearer\s+[A-Za-z0-9_-]+\b', caseSensitive: false),
    // UUIDs (often used for tokens/keys)
    // Only mask UUIDs that appear to be tokens (prefixed with specific keywords)
    RegExp(
      r'\b(?:token|key|secret|auth)[=:\s]+[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b',
      caseSensitive: false,
    ),
  ];

  /// The mask to use for sensitive data
  static const String _mask = '***REDACTED***';

  /// Short mask for inline replacements
  static const String _shortMask = '***';

  /// Filter a data map, masking any sensitive values
  static Map<String, dynamic> filterData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return {};
    }

    return _filterMap(data);
  }

  static Map<String, dynamic> _filterMap(Map<String, dynamic> map) {
    final filtered = <String, dynamic>{};

    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      if (_isSensitiveKey(key)) {
        filtered[key] = _mask;
      } else if (value is Map<String, dynamic>) {
        filtered[key] = _filterMap(value);
      } else if (value is List) {
        filtered[key] = _filterList(value);
      } else if (value is String) {
        filtered[key] = filterString(value);
      } else {
        filtered[key] = value;
      }
    }

    return filtered;
  }

  static List<dynamic> _filterList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _filterMap(item);
      } else if (item is List) {
        return _filterList(item);
      } else if (item is String) {
        return filterString(item);
      }
      return item;
    }).toList();
  }

  /// Check if a key name indicates sensitive data
  static bool _isSensitiveKey(String key) {
    final lowerKey = key.toLowerCase();
    return _sensitiveFieldPatterns.any(lowerKey.contains);
  }

  /// Filter a string value, masking any detected sensitive patterns
  static String filterString(String value) {
    var filtered = value;

    for (final pattern in _sensitiveValuePatterns) {
      filtered = filtered.replaceAllMapped(pattern, (match) => _shortMask);
    }

    return filtered;
  }

  /// Filter a log message, masking sensitive patterns
  static String filterMessage(String message) {
    return filterString(message);
  }

  /// Filter error messages, masking sensitive patterns
  static String? filterError(Object? error) {
    if (error == null) return null;
    return filterString(error.toString());
  }

  /// Filter stack trace, removing potentially sensitive file paths
  /// (keeps the stack trace structure but can mask specific paths if needed)
  static String? filterStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return null;
    // Stack traces generally don't contain sensitive data,
    // but we filter the string representation just in case
    return filterString(stackTrace.toString());
  }
}
