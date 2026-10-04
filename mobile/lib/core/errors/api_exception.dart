class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
    this.details,
  });

  factory ApiException.fromJson(Map<String, dynamic> json, int statusCode) {
    if (json.containsKey('error') && json['error'] is Map) {
      final err = json['error'] as Map<String, dynamic>;
      final code = err['code']?.toString() ?? 'API_ERROR';
      final msg = err['message']?.toString() ?? 'An unexpected error occurred';

      if (code == 'TOKEN_REPLAY_DETECTED') {
        return TokenReplayException(message: msg, statusCode: statusCode);
      }
      if (code == 'TOKEN_EXPIRED') {
        return TokenExpiredException(message: msg, statusCode: statusCode);
      }
      if (statusCode == 401) {
        return UnauthorizedException(message: msg, code: code, statusCode: statusCode);
      }

      return ApiException(message: msg, code: code, statusCode: statusCode, details: err);
    }

    // Handle DRF standard validation dict e.g. {"field": ["error message"]}
    if (json.values.any((v) => v is List)) {
      final messages = <String>[];
      json.forEach((k, v) {
        if (v is List) {
          messages.add('$k: ${v.join(", ")}');
        }
      });
      return ValidationException(
        message: messages.join('; '),
        statusCode: statusCode,
        details: json,
      );
    }

    final message = json['message']?.toString() ?? json['detail']?.toString() ?? 'Request failed ($statusCode)';
    return ApiException(message: message, statusCode: statusCode, details: json);
  }

  @override
  String toString() => 'ApiException [$code] (HTTP $statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Unable to connect to KeraLink server. Please check your network connection.',
    super.code = 'NETWORK_ERROR',
    super.statusCode,
  });
}

class TimeoutException extends ApiException {
  const TimeoutException({
    super.message = 'Connection timed out. Please try again.',
    super.code = 'TIMEOUT',
    super.statusCode = 408,
  });
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({
    super.message = 'Authentication required or session expired.',
    super.code = 'UNAUTHORIZED',
    super.statusCode = 401,
  });
}

class TokenExpiredException extends UnauthorizedException {
  const TokenExpiredException({
    super.message = 'Your session has expired. Please log in again.',
    super.code = 'TOKEN_EXPIRED',
    super.statusCode = 401,
  });
}

class TokenReplayException extends UnauthorizedException {
  const TokenReplayException({
    super.message = 'Security alert: Token reuse detected. All sessions terminated.',
    super.code = 'TOKEN_REPLAY_DETECTED',
    super.statusCode = 401,
  });
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.statusCode = 400,
    super.details,
  });
}
