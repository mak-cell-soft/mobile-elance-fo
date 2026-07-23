import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.i('--> ${options.method} ${options.uri}\n'
          'headers: ${options.headers}\n'
          'body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      _logger.d('<-- ${response.statusCode} ${response.requestOptions.uri}\n'
          'body: ${response.data}');
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
