import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woodapp/core/network/interceptors/logging_interceptor.dart';

void main() {
  group('LoggingInterceptor & Sanitizer Tests', () {
    test('1. Login password is redacted in request body', () {
      final input = {
        'login': 'dev_test_user',
        'password': 'synthetic_cleartext_password_123',
      };
      final sanitized = LoggingInterceptor.sanitizeData(input) as Map<String, dynamic>;

      expect(sanitized['login'], equals('dev_test_user'));
      expect(sanitized['password'], equals('[REDACTED]'));
      expect(sanitized['password'], isNot(contains('synthetic_cleartext_password_123')));
    });

    test('2. Authorization and sensitive headers are redacted', () {
      final headers = {
        'Authorization': 'Bearer synthetic_jwt_token_abc.123.xyz',
        'X-Tenant-Slug': 'development',
        'Content-Type': 'application/json',
        'Cookie': 'session_id=synthetic_session_val',
        'x-api-key': 'synthetic_api_key_456',
      };

      final sanitized = LoggingInterceptor.sanitizeHeaders(headers);

      expect(sanitized['Authorization'], equals('[REDACTED]'));
      expect(sanitized['Cookie'], equals('[REDACTED]'));
      expect(sanitized['x-api-key'], equals('[REDACTED]'));
      expect(sanitized['X-Tenant-Slug'], equals('development'));
      expect(sanitized['Content-Type'], equals('application/json'));
    });

    test('3. JWT in login response is redacted', () {
      final responseBody = {
        'isSuccess': true,
        'message': 'Authentification avec Succés',
        'fullname': 'Dev User',
        'enterpriseName': 'ACYA Dev',
        'token': 'eySyntheticHeader.eySyntheticPayload.syntheticSignature123',
      };

      final response = Response(
        requestOptions: RequestOptions(path: '/api/account/login'),
        statusCode: 200,
        data: responseBody,
      );

      final sanitized = LoggingInterceptor.sanitizeResponse(response) as Map<String, dynamic>;

      expect(sanitized['isSuccess'], isTrue);
      expect(sanitized['fullname'], equals('Dev User'));
      expect(sanitized['token'], equals('[REDACTED]'));
      expect(sanitized['token'], isNot(contains('syntheticSignature123')));
    });

    test('4. FCM device token is redacted in request data', () {
      final fcmPayload = {
        'token': 'synthetic_fcm_registration_token_xyz987',
        'platform': 'android',
        'appVersion': '1.0.0+1',
      };

      final sanitized = LoggingInterceptor.sanitizeData(fcmPayload) as Map<String, dynamic>;

      expect(sanitized['token'], equals('[REDACTED]'));
      expect(sanitized['platform'], equals('android'));
      expect(sanitized['appVersion'], equals('1.0.0+1'));
    });

    test('5. Nested sensitive fields and lists are redacted recursively', () {
      final complexData = {
        'user': {
          'name': 'Test User',
          'security': {
            'oldPassword': 'old_synthetic_password',
            'new_password': 'new_synthetic_password',
          },
        },
        'devices': [
          {'deviceName': 'Pixel', 'device_token': 'synthetic_dev_tok_1'},
          {'deviceName': 'iPhone', 'fcmToken': 'synthetic_fcm_tok_2'},
        ],
        'meta': {'status': 'active'},
      };

      final sanitized = LoggingInterceptor.sanitizeData(complexData) as Map<String, dynamic>;

      final user = sanitized['user'] as Map<String, dynamic>;
      final security = user['security'] as Map<String, dynamic>;
      expect(user['name'], equals('Test User'));
      expect(security['oldPassword'], equals('[REDACTED]'));
      expect(security['new_password'], equals('[REDACTED]'));

      final devices = sanitized['devices'] as List<dynamic>;
      expect((devices[0] as Map)['device_token'], equals('[REDACTED]'));
      expect((devices[1] as Map)['fcmToken'], equals('[REDACTED]'));
      expect((devices[0] as Map)['deviceName'], equals('Pixel'));
    });

    test('6. Sensitive key matching is case-insensitive with variants', () {
      final variants = {
        'PASSWORD': 'secret_val',
        'CurrentPassword': 'secret_val',
        'access_token': 'secret_val',
        'REFRESH-TOKEN': 'secret_val',
        'Client_Secret': 'secret_val',
        'ApiKey': 'secret_val',
        'IdToken': 'secret_val',
      };

      final sanitized = LoggingInterceptor.sanitizeData(variants) as Map<String, dynamic>;

      for (final key in variants.keys) {
        expect(sanitized[key], equals('[REDACTED]'), reason: 'Key $key should be redacted');
      }
    });

    test('7. The original request data remains unchanged (deep immutability)', () {
      final originalData = {
        'login': 'dev_test_user',
        'password': 'synthetic_cleartext_password_123',
        'nested': {'token': 'original_token_value'},
      };

      final sanitized = LoggingInterceptor.sanitizeData(originalData) as Map<String, dynamic>;

      // Sanitized copy has redacted values
      expect(sanitized['password'], equals('[REDACTED]'));
      expect((sanitized['nested'] as Map)['token'], equals('[REDACTED]'));

      // Original is unmodified
      expect(originalData['password'], equals('synthetic_cleartext_password_123'));
      expect((originalData['nested'] as Map)['token'], equals('original_token_value'));
    });

    test('8. Non-sensitive fields remain completely intact and useful for debugging', () {
      final payload = {
        'articleId': 42,
        'quantity': 10.5,
        'inStock': true,
        'description': 'Wood Plank Oak',
        'tags': ['oak', 'premium'],
      };

      final sanitized = LoggingInterceptor.sanitizeData(payload) as Map<String, dynamic>;

      expect(sanitized['articleId'], equals(42));
      expect(sanitized['quantity'], equals(10.5));
      expect(sanitized['inStock'], isTrue);
      expect(sanitized['description'], equals('Wood Plank Oak'));
      expect(sanitized['tags'], equals(['oak', 'premium']));
    });

    test('9. Unsupported or ambiguous payload types do not leak raw sensitive data', () {
      final unsupported = DateTime(2026, 10, 18);
      final sanitized = LoggingInterceptor.sanitizeData(unsupported);

      expect(sanitized, contains('[Type: DateTime (redacted for security)]'));

      // Raw standalone JWT string
      final rawJwt = 'ey123.ey456.signature789';
      final sanitizedJwt = LoggingInterceptor.sanitizeData(rawJwt);
      expect(sanitizedJwt, equals('[REDACTED_JWT]'));
    });

    test('10. Existing interceptor passes through options and response untouched', () {
      final interceptor = LoggingInterceptor();

      // Test onRequest pass-through
      final options = RequestOptions(
        path: '/test',
        data: {'login': 'dev_user', 'password': 'my_password'},
        headers: {'Authorization': 'Bearer 12345'},
      );

      final reqHandler = _TestRequestHandler();
      interceptor.onRequest(options, reqHandler);

      expect(reqHandler.nextOptions, isNotNull);
      expect(identical(reqHandler.nextOptions, options), isTrue);
      expect((options.data as Map)['password'], equals('my_password'));
      expect(options.headers['Authorization'], equals('Bearer 12345'));

      // Test onResponse pass-through
      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: {'token': 'original_jwt'},
      );
      final resHandler = _TestResponseHandler();
      interceptor.onResponse(response, resHandler);

      expect(resHandler.nextResponse, isNotNull);
      expect(identical(resHandler.nextResponse, response), isTrue);
      expect((response.data as Map)['token'], equals('original_jwt'));
    });
  });
}

class _TestRequestHandler extends RequestInterceptorHandler {
  RequestOptions? nextOptions;

  @override
  void next(RequestOptions requestOptions) {
    nextOptions = requestOptions;
  }
}

class _TestResponseHandler extends ResponseInterceptorHandler {
  Response? nextResponse;

  @override
  void next(Response response) {
    nextResponse = response;
  }
}
