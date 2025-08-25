/// Base exception class for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  AuthenticationException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Authorization/Permission related exceptions
class AuthorizationException extends AppException {
  AuthorizationException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Database/Firestore related exceptions
class DatabaseException extends AppException {
  DatabaseException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Validation related exceptions
class ValidationException extends AppException {
  ValidationException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// File upload/storage related exceptions
class StorageException extends AppException {
  StorageException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// User not found exception
class UserNotFoundException extends AppException {
  UserNotFoundException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Product not found exception
class ProductNotFoundException extends AppException {
  ProductNotFoundException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Rate limiting exception
class RateLimitException extends AppException {
  RateLimitException(String message, {String? code, dynamic details})
    : super(message, code: code, details: details);
}

/// Custom exception handler utility
class ExceptionHandler {
  static String getErrorMessage(Exception exception) {
    if (exception is AppException) {
      return exception.message;
    } else if (exception.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    } else if (exception.toString().contains('permission')) {
      return 'Permission denied. Please check your access rights.';
    } else if (exception.toString().contains('auth')) {
      return 'Authentication error. Please login again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  static AppException parseFirebaseException(Exception exception) {
    String errorMessage = exception.toString().toLowerCase();

    if (errorMessage.contains('network')) {
      return NetworkException('Network connection failed');
    } else if (errorMessage.contains('permission-denied')) {
      return AuthorizationException('Permission denied');
    } else if (errorMessage.contains('unauthenticated')) {
      return AuthenticationException('User not authenticated');
    } else if (errorMessage.contains('not-found')) {
      return DatabaseException('Document not found');
    } else if (errorMessage.contains('already-exists')) {
      return ValidationException('Resource already exists');
    } else {
      return AppException('Unknown error occurred');
    }
  }
}
