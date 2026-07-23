import 'package:get_storage/get_storage.dart';

/// Thin wrapper around GetStorage so the rest of the app never touches
/// raw string keys directly.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final GetStorage _box = GetStorage();

  static const _keyTenantSlug = 'tenant_slug';
  static const _keyTenantConfig = 'tenant_config';
  static const _keyToken = 'auth_token';
  static const _keyFullName = 'auth_fullname';
  static const _keyEnterpriseName = 'auth_enterprise_name';

  static Future<void> ensureInitialized() => GetStorage.init();

  // Tenant
  String? get tenantSlug => _box.read<String>(_keyTenantSlug);
  Future<void> saveTenantSlug(String slug) => _box.write(_keyTenantSlug, slug);

  Map<String, dynamic>? get tenantConfig =>
      _box.read<Map<String, dynamic>>(_keyTenantConfig);
  Future<void> saveTenantConfig(Map<String, dynamic> json) =>
      _box.write(_keyTenantConfig, json);

  Future<void> clearTenant() async {
    await _box.remove(_keyTenantSlug);
    await _box.remove(_keyTenantConfig);
  }

  // Auth
  String? get token => _box.read<String>(_keyToken);
  String? get fullName => _box.read<String>(_keyFullName);
  String? get enterpriseName => _box.read<String>(_keyEnterpriseName);

  Future<void> saveSession({
    required String token,
    String? fullName,
    String? enterpriseName,
  }) async {
    await _box.write(_keyToken, token);
    if (fullName != null) await _box.write(_keyFullName, fullName);
    if (enterpriseName != null) {
      await _box.write(_keyEnterpriseName, enterpriseName);
    }
  }

  Future<void> clearSession() async {
    await _box.remove(_keyToken);
    await _box.remove(_keyFullName);
    await _box.remove(_keyEnterpriseName);
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}
