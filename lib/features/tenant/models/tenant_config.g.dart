// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantConfig _$TenantConfigFromJson(Map<String, dynamic> json) => TenantConfig(
  name: json['name'] as String?,
  logoUrl: json['logoUrl'] as String?,
  faviconUrl: json['faviconUrl'] as String?,
  primaryColor: json['primaryColor'] as String?,
  secondaryColor: json['secondaryColor'] as String?,
  language: json['language'] as String?,
  currency: json['currency'] as String?,
  status: json['status'] as String?,
);

Map<String, dynamic> _$TenantConfigToJson(TenantConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'logoUrl': instance.logoUrl,
      'faviconUrl': instance.faviconUrl,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'language': instance.language,
      'currency': instance.currency,
      'status': instance.status,
    };
