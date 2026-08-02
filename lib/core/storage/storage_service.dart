import 'dart:convert';
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
  static const _keyThemeMode = 'theme_mode';

  static Future<void> ensureInitialized() => GetStorage.init();

  // Theme Mode
  String? get themeMode => _box.read<String>(_keyThemeMode);
  Future<void> saveThemeMode(String mode) => _box.write(_keyThemeMode, mode);

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

  // JWT Claims Decoded
  Map<String, dynamic>? get _jwtPayload {
    final jwt = token;
    if (jwt == null || jwt.isEmpty) return null;
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      // Normalize base64 string
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final resp = utf8.decode(base64.decode(normalized));
      return jsonDecode(resp) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Extracts User ID from JWT claim (NameIdentifier)
  int? get userId {
    final claims = _jwtPayload;
    if (claims == null) return null;
    final val = claims['nameid'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
        claims['sub'];
    if (val == null) return null;
    return int.tryParse(val.toString());
  }

  /// Extracts Email from JWT claim
  String? get userEmail {
    final claims = _jwtPayload;
    if (claims == null) return null;
    return claims['email'] ??
        claims['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
  }

  /// Extracts raw Role claim from JWT
  String? get userRole {
    final claims = _jwtPayload;
    if (claims == null) return null;
    return claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
  }

  /// Returns true if the user role is Admin or SuperAdmin
  bool get isAdmin {
    final role = userRole;
    if (role == null) return false;
    final r = role.trim().toLowerCase();
    return r == 'admin' ||
        r == 'superadmin' ||
        r == '10' ||
        r == '20';
  }

  /// Translates application roles to user-friendly French terms, matching navbar.tsx logic.
  String get translatedRole {
    final role = userRole;
    if (role == null || role.isEmpty) return 'Utilisateur';

    final roleNum = int.tryParse(role);
    if (roleNum != null) {
      switch (roleNum) {
        case 10:
          return 'Super Administrateur';
        case 20:
          return 'Administrateur';
        case 30:
          return 'Utilisateur';
        case 40:
          return 'Conducteur';
        case 50:
          return 'Vendeur';
        case 60:
          return 'Agent de Facturation';
        case 70:
          return 'Responsable de Magasin';
        default:
          return 'Utilisateur';
      }
    }

    switch (role.trim().toLowerCase()) {
      case 'superadmin':
        return 'Super Administrateur';
      case 'admin':
        return 'Administrateur';
      case 'user':
        return 'Utilisateur';
      case 'conductor':
        return 'Conducteur';
      case 'seller':
        return 'Vendeur';
      case 'invoiceagent':
        return 'Agent de Facturation';
      case 'storemanager':
        return 'Responsable de Magasin';
      default:
        return role;
    }
  }
}
