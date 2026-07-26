import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// Service responsible for User Profile fetching and updates matching AccountController.cs.
class ProfileService {
  final Dio _dio = ApiClient.instance.dio;

  /// GET /Account/profile/{id}
  Future<Map<String, dynamic>> fetchProfile(int id) async {
    try {
      final response = await _dio.get('Account/profile/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// PUT /Account/update-profile
  /// Model expected: { email, login, firstName, lastName, phoneNumber, address }
  Future<void> updateProfile({
    required String email,
    required String login,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      await _dio.put(
        'Account/update-profile',
        data: {
          'email': email,
          'login': login,
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'address': address,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
