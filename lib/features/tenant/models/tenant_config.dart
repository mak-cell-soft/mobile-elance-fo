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
  });

  bool get isActive => status != 'Suspended' && status != 'Expired';

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
    );
  }

  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    final bool hasChantier = json['hasChantierModule'] as bool? ??
        json['hasChantiers'] as bool? ??
        TenantBuildConfig.hasChantierModule;

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
      };
}
