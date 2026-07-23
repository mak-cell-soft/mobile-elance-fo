import 'package:dio/dio.dart';

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  server,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          type: ApiErrorType.timeout,
          message: 'La connexion a expiré. Veuillez réessayer.',
          statusCode: statusCode,
          data: data,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          type: ApiErrorType.network,
          message: 'Pas de connexion internet. Vérifiez votre réseau.',
          statusCode: statusCode,
          data: data,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          type: _typeFromStatusCode(statusCode),
          message: _messageFromResponse(statusCode, data),
          statusCode: statusCode,
          data: data,
        );
      default:
        return ApiException(
          type: ApiErrorType.unknown,
          message: 'Une erreur inattendue est survenue.',
          statusCode: statusCode,
          data: data,
        );
    }
  }

  static ApiErrorType _typeFromStatusCode(int? statusCode) {
    switch (statusCode) {
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      default:
        if (statusCode != null && statusCode >= 500) {
          return ApiErrorType.server;
        }
        return ApiErrorType.unknown;
    }
  }

  static String _messageFromResponse(int? statusCode, dynamic data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    switch (statusCode) {
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return "Vous n'avez pas la permission d'effectuer cette action.";
      case 404:
        return 'Ressource introuvable.';
      default:
        if (statusCode != null && statusCode >= 500) {
          return 'Erreur serveur. Veuillez réessayer plus tard.';
        }
        return 'Une erreur est survenue.';
    }
  }
}
