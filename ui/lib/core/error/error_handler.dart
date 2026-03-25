import 'package:flutter/material.dart';

import '../logging/app_logger.dart';

/// Global error handler for consistent error display and logging
class ErrorHandler {
  /// Handle an error with user-friendly feedback
  ///
  /// Logs the error and shows a SnackBar with an appropriate message.
  /// Optionally provides a retry action.
  static void handleError(
    BuildContext context,
    Object error,
    StackTrace? stackTrace, {
    String? userMessage,
    VoidCallback? onRetry,
  }) {
    // Log the error
    AppLogger.error(
      'Error handled by ErrorHandler',
      error: error,
      stackTrace: stackTrace,
    );

    // Determine user-friendly message
    final message = userMessage ?? _getUserMessage(error);

    // Show SnackBar with error
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    }
  }

  /// Get a user-friendly error message based on the exception type
  static String _getUserMessage(Object error) {
    if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is ValidationException) {
      return error.message;
    } else if (error is PermissionDeniedException) {
      return error.message;
    } else if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network.';
    } else if (error.toString().contains('FormatException')) {
      return 'Invalid data format. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Show a success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: duration,
        ),
      );
    }
  }

  /// Show an info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), duration: duration));
    }
  }
}

/// Custom exception for validation errors
class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Custom exception for permission denied errors
class PermissionDeniedException implements Exception {
  PermissionDeniedException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Custom exception for network errors
class NetworkException implements Exception {
  NetworkException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Custom exception for timeout errors
class TimeoutException implements Exception {
  TimeoutException(this.message);
  final String message;

  @override
  String toString() => message;
}
