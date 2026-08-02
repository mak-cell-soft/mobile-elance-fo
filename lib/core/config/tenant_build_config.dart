/// Compile-time configuration for multi-tenant custom app builds.
/// Values are supplied at build time via `--dart-define` arguments:
/// e.g. `flutter build apk --flavor=socofeb --dart-define=TENANT_ID=socofeb --dart-define=APP_NAME=socofeb`
class TenantBuildConfig {
  TenantBuildConfig._();

  static const String tenantId = String.fromEnvironment('TENANT_ID', defaultValue: 'socofeb');
  static const String companyName = String.fromEnvironment('COMPANY_NAME', defaultValue: 'SOCOFEB');
  static const String appName = String.fromEnvironment('APP_NAME', defaultValue: 'socofeb');
  static const String packageName = String.fromEnvironment('PACKAGE_NAME', defaultValue: 'com.socofeb.woodapp');
  static const String primaryColor = String.fromEnvironment('PRIMARY_COLOR', defaultValue: '#1B4332');
  static const String secondaryColor = String.fromEnvironment('SECONDARY_COLOR', defaultValue: '#2D6A4F');
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: 'https://acya.site/api/');
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
  static const String supportedLocales = String.fromEnvironment('SUPPORTED_LOCALES', defaultValue: 'fr');
  static const String assetsPath = String.fromEnvironment('ASSETS_PATH', defaultValue: 'assets/tenants/socofeb/');

  /// Returns true if this APK was built specifically for a pre-configured tenant.
  static bool get isEmbedded => tenantId.trim().isNotEmpty;

  /// Gets the resolved logo SVG asset path for the tenant.
  static String get logoPath {
    if (assetsPath.isNotEmpty) {
      return '${assetsPath.endsWith('/') ? assetsPath : '$assetsPath/'}logo.svg';
    }
    return 'assets/images/logo.svg';
  }
}
