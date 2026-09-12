import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../core/config/tenant_build_config.dart';

/// Tenant Configuration model containing branding, company parameters,
/// and API settings for a specific company / tenant.
class TenantConfig {
  final String? tenantId;
  final String? companyName;
  final String? appName;
  final String? packageName;
  final String? name;
  final String? logo;
  final String? logoUrl;
  final String? faviconUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? baseUrl;
  final String? environment;
  final String? supportedLocales;
  final String? assetsPath;
  final String? language;
  final String? currency;
  final String? status;
  final bool hasChantierModule;
  final bool isManagingConstructions;

  TenantConfig({
    this.tenantId,
    this.companyName,
    this.appName,
    this.packageName,
    this.name,
    this.logo,
    this.logoUrl,
    this.faviconUrl,
    this.primaryColor,
    this.secondaryColor,
    this.baseUrl,
    this.environment,
    this.supportedLocales,
    this.assetsPath,
    this.language,
    this.currency,
    this.status,
    this.hasChantierModule = true,
    this.isManagingConstructions = true,
  });

  bool get isActive => status != 'Suspended' && status != 'Expired';

  /// Loads tenant config dynamically:
  /// 1. Attempts to read manually defined `assets/tenant_config.json`
  /// 2. If not present or error, attempts `assets/tenants/${TenantBuildConfig.tenantId}/config.json`
  /// 3. Falls back to compile-time `TenantConfig.fromBuildConfig()`
  static Future<TenantConfig> loadActiveConfig() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/tenant_config.json');
      if (jsonStr.trim().isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return TenantConfig.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to tenant-specific or build config
    }

    try {
      final path = 'assets/tenants/${TenantBuildConfig.tenantId}/config.json';
      final jsonStr = await rootBundle.loadString(path);
      if (jsonStr.trim().isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        return TenantConfig.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to build config
    }

    return TenantConfig.fromBuildConfig();
  }

  /// Factory constructing [TenantConfig] from compile-time build configuration.
  factory TenantConfig.fromBuildConfig() {
    return TenantConfig(
      tenantId: TenantBuildConfig.tenantId,
      companyName: TenantBuildConfig.companyName,
      appName: TenantBuildConfig.appName,
      packageName: TenantBuildConfig.packageName,
      name: TenantBuildConfig.appName,
      logo: TenantBuildConfig.logoPath,
      primaryColor: TenantBuildConfig.primaryColor,
      secondaryColor: TenantBuildConfig.secondaryColor,
      baseUrl: TenantBuildConfig.baseUrl,
      environment: TenantBuildConfig.environment,
      supportedLocales: TenantBuildConfig.supportedLocales,
      assetsPath: TenantBuildConfig.assetsPath,
      language: TenantBuildConfig.supportedLocales,
      status: 'Active',
      hasChantierModule: TenantBuildConfig.hasChantierModule,
      isManagingConstructions: TenantBuildConfig.hasChantierModule,
    );
  }

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    bool parseBoolFlag(dynamic val, {bool defaultValue = true}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      final s = val.toString().trim().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return defaultValue;
    }

    final dynamic explicitChantierFlag = json['hasChantierModule'] ??
        json['hasChantiers'] ??
        json['isManagingConstructions'] ??
        json['ismanagingconstructions'];

    final bool hasChantier = explicitChantierFlag != null
        ? parseBoolFlag(explicitChantierFlag, defaultValue: TenantBuildConfig.hasChantierModule)
        : TenantBuildConfig.hasChantierModule;

    final dynamic explicitManagingConstructions = json['isManagingConstructions'] ??
        json['ismanagingconstructions'] ??
        explicitChantierFlag;

    final bool managingConstructions = explicitManagingConstructions != null
        ? parseBoolFlag(explicitManagingConstructions, defaultValue: hasChantier)
        : hasChantier;

    return TenantConfig(
      tenantId: json['tenantId']?.toString() ?? TenantBuildConfig.tenantId,
      companyName: json['companyName']?.toString() ?? json['name']?.toString() ?? TenantBuildConfig.companyName,
      appName: json['appName']?.toString() ?? json['name']?.toString() ?? TenantBuildConfig.appName,
      packageName: json['packageName']?.toString() ?? TenantBuildConfig.packageName,
      name: json['name']?.toString() ?? json['appName']?.toString() ?? TenantBuildConfig.appName,
      logo: json['logo']?.toString() ?? TenantBuildConfig.logoPath,
      logoUrl: json['logoUrl']?.toString(),
      faviconUrl: json['faviconUrl']?.toString(),
      primaryColor: json['primaryColor']?.toString() ?? TenantBuildConfig.primaryColor,
      secondaryColor: json['secondaryColor']?.toString() ?? TenantBuildConfig.secondaryColor,
      baseUrl: json['baseUrl']?.toString() ?? TenantBuildConfig.baseUrl,
      environment: json['environment']?.toString() ?? TenantBuildConfig.environment,
      supportedLocales: json['supportedLocales']?.toString() ?? TenantBuildConfig.supportedLocales,
      assetsPath: json['assetsPath']?.toString() ?? TenantBuildConfig.assetsPath,
      language: json['language']?.toString() ?? TenantBuildConfig.supportedLocales,
      currency: json['currency']?.toString() ?? 'MAD',
      status: json['status']?.toString() ?? 'Active',
      hasChantierModule: hasChantier,
      isManagingConstructions: managingConstructions,
    );
  }

  Map<String, dynamic> toJson() => {
        'tenantId': tenantId ?? TenantBuildConfig.tenantId,
        'companyName': companyName ?? TenantBuildConfig.companyName,
        'appName': appName ?? TenantBuildConfig.appName,
        'packageName': packageName ?? TenantBuildConfig.packageName,
        'name': name ?? TenantBuildConfig.appName,
        'logo': logo ?? TenantBuildConfig.logoPath,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (faviconUrl != null) 'faviconUrl': faviconUrl,
        'primaryColor': primaryColor ?? TenantBuildConfig.primaryColor,
        'secondaryColor': secondaryColor ?? TenantBuildConfig.secondaryColor,
        'baseUrl': baseUrl ?? TenantBuildConfig.baseUrl,
        'environment': environment ?? TenantBuildConfig.environment,
        'supportedLocales': supportedLocales ?? TenantBuildConfig.supportedLocales,
        'assetsPath': assetsPath ?? TenantBuildConfig.assetsPath,
        'language': language ?? TenantBuildConfig.supportedLocales,
        if (currency != null) 'currency': currency,
        'status': status ?? 'Active',
        'hasChantierModule': hasChantierModule,
        'hasChantiers': hasChantierModule,
        'isManagingConstructions': isManagingConstructions,
        'ismanagingconstructions': isManagingConstructions,
      };
}
