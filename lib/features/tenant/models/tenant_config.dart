import 'package:json_annotation/json_annotation.dart';

part 'tenant_config.g.dart';

/// Mirrors the payload of GET /api/enterprise/config.
/// The tenant slug itself isn't part of this response (it's what the
/// caller sent in X-Tenant-Slug), so it's stored alongside this, not in it.
@JsonSerializable()
class TenantConfig {
  final String? name;
  final String? logoUrl;
  final String? faviconUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? language;
  final String? currency;
  final String? status;

  TenantConfig({
    this.name,
    this.logoUrl,
    this.faviconUrl,
    this.primaryColor,
    this.secondaryColor,
    this.language,
    this.currency,
    this.status,
  });

  bool get isActive => status != 'Suspended' && status != 'Expired';

  factory TenantConfig.fromJson(Map<String, dynamic> json) =>
      _$TenantConfigFromJson(json);

  Map<String, dynamic> toJson() => _$TenantConfigToJson(this);
}
