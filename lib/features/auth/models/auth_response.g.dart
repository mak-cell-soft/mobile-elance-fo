// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  isSuccess: json['isSuccess'] as bool,
  message: json['message'] as String?,
  token: json['token'] as String?,
  fullname: json['fullname'] as String?,
  enterpriseName: json['enterpriseName'] as String?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'isSuccess': instance.isSuccess,
      'message': instance.message,
      'token': instance.token,
      'fullname': instance.fullname,
      'enterpriseName': instance.enterpriseName,
    };
