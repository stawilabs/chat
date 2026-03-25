/// Centralized error types for the application
enum ErrorType { network, authentication, validation, server, unknown }

/// Application error with user-friendly messaging
class AppError {
  const AppError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
  });

  /// Create error from exception
  factory AppError.fromException(Object error, [StackTrace? stack]) {
    if (error is AppError) return error;

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection') ||
        error.toString().contains('Network')) {
      return AppError(
        type: ErrorType.network,
        message: 'Connection lost. Please check your internet connection.',
        technicalDetails: error.toString(),
        stackTrace: stack,
      );
    }

    // Auth errors
    if (error.toString().contains('401') ||
        error.toString().contains('Unauthorized') ||
        error.toString().contains('auth')) {
      return AppError(
        type: ErrorType.authentication,
        message: 'Session expired. Please log in again.',
        technicalDetails: error.toString(),
        stackTrace: stack,
      );
    }

    // Server errors
    if (error.toString().contains('500') ||
        error.toString().contains('503') ||
        error.toString().contains('Server')) {
      return AppError(
        type: ErrorType.server,
        message: 'Server error. Please try again later.',
        technicalDetails: error.toString(),
        stackTrace: stack,
      );
    }

    // Unknown
    return AppError(
      type: ErrorType.unknown,
      message: 'Something went wrong. Please try again.',
      technicalDetails: error.toString(),
      stackTrace: stack,
    );
  }
  final ErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}
