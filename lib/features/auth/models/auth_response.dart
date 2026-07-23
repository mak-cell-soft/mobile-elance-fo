import 'package:json_annotation/json_annotation.dart';

part 'auth_response.g.dart';

/// Mirrors UserAuthDto returned by POST /api/account/login.
/// Note: the backend answers HTTP 200 even on invalid credentials —
/// isSuccess is what actually tells you whether the login worked.
@JsonSerializable()
class AuthResponse {
  final bool isSuccess;
  final String? message;
  final String? token;
  final String? fullname;
  final String? enterpriseName;

  AuthResponse({
    required this.isSuccess,
    this.message,
    this.token,
    this.fullname,
    this.enterpriseName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}
