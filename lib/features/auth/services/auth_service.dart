import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio = ApiClient.instance.dio;

  Future<AuthResponse> login({required String login, required String password}) async {
    try {
      final response = await _dio.post(
        'account/login',
        data: {'login': login, 'password': password},
      );
      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
