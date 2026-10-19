import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Interceptor that safely logs HTTP requests, responses, and errors in [kDebugMode]
/// while redacting passwords, tokens, authorization headers, and secrets.
class LoggingInterceptor extends Interceptor {
  final Logger _logger;

  LoggingInterceptor({Logger? logger})
      : _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  static const Set<String> _sensitiveHeaderNames = {
    'authorization',
    'proxy-authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'api-key',
    'apikey',
    'x-auth-token',
  };

  /// Determines if a header name represents sensitive authentication material.
  static bool isSensitiveHeader(String headerName) {
    final lower = headerName.toLowerCase().trim();
    if (_sensitiveHeaderNames.contains(lower)) return true;
    if (lower.startsWith('x-auth-')) return true;
    if (lower.contains('token') || lower.contains('secret') || lower.contains('cookie')) {
      return true;
    }
    return false;
  }

  /// Returns a sanitized shallow copy of [headers] with sensitive values redacted.
  static Map<String, dynamic> sanitizeHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return {};
    final sanitized = <String, dynamic>{};
    for (final entry in headers.entries) {
      if (isSensitiveHeader(entry.key)) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Determines if a field key represents sensitive data (passwords, tokens, secrets).
  static bool isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    if (normalized.contains('password')) return true;
    if (normalized.contains('secret')) return true;
    if (normalized.contains('apikey')) return true;
    if (normalized.contains('credential')) return true;
    if (normalized == 'authorization' || normalized == 'proxyauthorization') return true;
    if (normalized == 'token' ||
        normalized.endsWith('token') ||
        normalized.startsWith('token') ||
        normalized.contains('authtoken') ||
        normalized.contains('fcmtoken') ||
        normalized.contains('devicetoken')) {
      return true;
    }
    return false;
  }

  /// Recursively sanitizes [data], replacing sensitive fields with `'[REDACTED]'`.
  /// Never mutates the input [data].
  static dynamic sanitizeData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitizedMap = <String, dynamic>{};
      for (final entry in data.entries) {
        final keyStr = entry.key.toString();
        if (isSensitiveKey(keyStr)) {
          sanitizedMap[keyStr] = '[REDACTED]';
        } else {
          sanitizedMap[keyStr] = sanitizeData(entry.value);
        }
      }
      return sanitizedMap;
    } else if (data is List) {
      return data.map((item) => sanitizeData(item)).toList();
    } else if (data is num || data is bool) {
      return data;
    } else if (data is String) {
      final trimmed = data.trim();
      // Check for JSON string
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          final decoded = jsonDecode(trimmed);
          return jsonEncode(sanitizeData(decoded));
        } catch (_) {
          // If JSON parse fails, check if string resembles a JWT
          if (trimmed.startsWith('ey') && trimmed.split('.').length == 3) {
            return '[REDACTED_JWT]';
          }
          return data;
        }
      }
      // Check if raw string is a JWT
      if (trimmed.startsWith('ey') && trimmed.split('.').length == 3) {
        return '[REDACTED_JWT]';
      }
      return data;
    } else {
      // For unsupported or ambiguous payload types (e.g. FormData, Stream, Uint8List),
      // return a safe summary placeholder rather than risking leaking raw data.
      return '[Type: ${data.runtimeType} (redacted for security)]';
    }
  }

  /// Sanitizes response body with extra conservative handling for authentication endpoints.
  static dynamic sanitizeResponse(Response response) {
    final path = response.requestOptions.uri.path.toLowerCase();
    final isAuthEndpoint = path.contains('login') ||
        path.contains('auth') ||
        path.contains('token') ||
        path.contains('password');

    try {
      final sanitized = sanitizeData(response.data);
      return sanitized;
    } catch (_) {
      if (isAuthEndpoint) {
        return '[REDACTED_AUTH_RESPONSE]';
      }
      return '[UNABLE_TO_SANITIZE_RESPONSE]';
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final safeHeaders = sanitizeHeaders(options.headers);
      final safeBody = sanitizeData(options.data);
      _logger.i('--> ${options.method} ${options.uri}\n'
          'headers: $safeHeaders\n'
          'body: $safeBody');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final safeBody = sanitizeResponse(response);
      _logger.d('<-- ${response.statusCode} ${response.requestOptions.uri}\n'
          'body: $safeBody');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.e('<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}\n'
          '${err.message}');
    }
    handler.next(err);
  }
}
