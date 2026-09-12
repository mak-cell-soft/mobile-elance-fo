import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import '../config/tenant_build_config.dart';

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
  static const _keyEnterpriseInfo = 'auth_enterprise_info';
  static const _keyThemeMode = 'theme_mode';

  static Future<void> ensureInitialized() => GetStorage.init();

  // Helper to parse dynamic values (bool, string "true"/"false", int 1/0) into nullable bool
  static bool? _toBool(dynamic val) {
    if (val == null) return null;
    if (val is bool) return val;
    final s = val.toString().trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

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

  // Enterprise Info (cached fresh from GET /Enterprise/getbyid/{id})
  Map<String, dynamic>? get enterpriseInfo =>
      _box.read<Map<String, dynamic>>(_keyEnterpriseInfo);
  Future<void> saveEnterpriseInfo(Map<String, dynamic> info) =>
      _box.write(_keyEnterpriseInfo, info);
  Future<void> clearEnterpriseInfo() => _box.remove(_keyEnterpriseInfo);

  /// Returns whether the enterprise manages constructions (tenant-level feature flag for Chantier module).
  /// Sourced with fallback priority matching fo-acya-app/elance-app.ui useTenantFeatures:
  /// 1. Fresh enterprise info (GET /Enterprise/getbyid/{id}) stored in local storage
  /// 2. JWT claim 'IsManagingConstructions' decoded from session token
  /// 3. Active tenant configuration (assets or backend)
  /// 4. Compile-time build configuration [TenantBuildConfig.hasChantierModule]
  bool get isManagingConstructions {
    // 1. Fresh enterprise cache
    final ent = enterpriseInfo;
    if (ent != null) {
      final val = _toBool(ent['ismanagingconstructions'] ?? ent['isManagingConstructions']);
      if (val != null) return val;
    }

    // 2. JWT claim from session
    final claims = _jwtPayload;
    if (claims != null) {
      final val = _toBool(claims['IsManagingConstructions'] ??
          claims['isManagingConstructions'] ??
          claims['ismanagingconstructions']);
      if (val != null) return val;
    }

    // 3. Tenant config
    final cfg = tenantConfig;
    if (cfg != null) {
      final val = _toBool(cfg['isManagingConstructions'] ??
          cfg['ismanagingconstructions'] ??
          cfg['hasChantierModule'] ??
          cfg['hasChantiers']);
      if (val != null) return val;
    }

    // 4. Default fallback
    return TenantBuildConfig.hasChantierModule;
  }

  /// Checks whether the active tenant has the Chantiers module enabled.
  /// 1. First verifies compile-time build configuration [TenantBuildConfig.hasChantierModule].
  /// 2. When authenticated, evaluates tenant feature flag [isManagingConstructions].
  /// 3. Evaluates runtime tenant config (`hasChantierModule`, `hasChantiers`, or `modules` list).
  bool get hasChantierModule {
    // 1. Compile-time check (e.g. flavor or --dart-define=HAS_CHANTIER_MODULE=false)
    if (!TenantBuildConfig.hasChantierModule) return false;

    // 2. If logged in, evaluate tenant feature flag
    if (isLoggedIn && !isManagingConstructions) {
      return false;
    }

    // 3. Runtime tenant config check
    final cfg = tenantConfig;
    if (cfg != null) {
      final flag = _toBool(cfg['hasChantierModule'] ??
          cfg['hasChantiers'] ??
          cfg['isManagingConstructions'] ??
          cfg['ismanagingconstructions']);
      if (flag == false) {
        return false;
      }

      final modules = cfg['modules'] ?? cfg['features'] ?? cfg['enabledModules'];
      if (modules is List && modules.isNotEmpty) {
        final hasModule = modules.any((m) {
          final s = m.toString().toLowerCase();
          return s == 'chantier' || s == 'chantiers' || s == 'site' || s == 'sites';
        });
        if (!hasModule) return false;
      }
    }

    return true;
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
    await _box.remove(_keyEnterpriseInfo);
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

  /// Extracts DefaultSiteId (sales site ID) from JWT claim
  int? get defaultSiteId {
    final claims = _jwtPayload;
    if (claims == null) return null;
    final val = claims['DefaultSiteId'] ??
        claims['defaultSiteId'] ??
        claims['SiteId'] ??
        claims['siteId'];
    if (val == null) return null;
    return int.tryParse(val.toString());
  }

  /// Extracts DefaultSite address/name from JWT claim
  String? get defaultSite {
    final claims = _jwtPayload;
    if (claims == null) return null;
    return claims['DefaultSite'] ?? claims['defaultSite'];
  }

  /// Extracts raw Role claim from JWT
  String? get userRole {
    final claims = _jwtPayload;
    if (claims == null) return null;
    final val = claims['role'] ??
        claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
        claims['Role'] ??
        claims['roles'];
    if (val is List && val.isNotEmpty) {
      return val.first.toString();
    }
    return val?.toString();
  }

  /// Returns true if the user role is Admin or SuperAdmin
  bool get isAdmin {
    final claims = _jwtPayload;
    if (claims != null) {
      final val = claims['role'] ??
          claims['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ??
          claims['Role'] ??
          claims['roles'];
      if (val is List) {
        return val.any((r) {
          final s = r.toString().trim().toLowerCase();
          return s == 'admin' || s == 'superadmin' || s == '10' || s == '20';
        });
      }
    }
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

  /// Extracts EnterpriseId from JWT claim
  int? get enterpriseId {
    final claims = _jwtPayload;
    if (claims == null) return null;
    final val = claims['EnterpriseId'] ??
        claims['enterpriseId'] ??
        claims['enterprise_id'];
    if (val == null) return null;
    return int.tryParse(val.toString());
  }

  /// Decodes user permissions map from JWT claim 'Permissions', matching fo-acya-app backend
  Map<String, dynamic>? get permissions {
    final claims = _jwtPayload;
    if (claims == null) return null;
    final rawPerms = claims['Permissions'] ?? claims['permissions'];
    if (rawPerms == null) return null;
    if (rawPerms is Map<String, dynamic>) return rawPerms;
    if (rawPerms is String && rawPerms.trim().isNotEmpty) {
      try {
        return jsonDecode(rawPerms) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Checks whether current user has permission for a specific module & action.
  /// Matches usePermissionGuard behavior in elance-app.ui.
  bool hasPermission(String module, {String action = 'canRead'}) {
    if (isAdmin) return true;

    // Chantiers is primarily governed by tenant subscription/feature flag
    if (module.toLowerCase() == 'chantier' || module.toLowerCase() == 'chantiers') {
      return hasChantierModule;
    }

    final perms = permissions;
    if (perms == null || perms.isEmpty) {
      // Fallback: if no explicit permissions configured, allow canRead
      return action == 'canRead';
    }

    // Case-insensitive module lookup
    final moduleKey = perms.keys.firstWhere(
      (k) => k.toLowerCase() == module.toLowerCase(),
      orElse: () => '',
    );
    if (moduleKey.isEmpty) return false;

    final modulePerms = perms[moduleKey];
    if (modulePerms is! Map) return false;

    // Case-insensitive action lookup
    final actionKey = modulePerms.keys.firstWhere(
      (k) => k.toString().toLowerCase() == action.toLowerCase(),
      orElse: () => '',
    );
    if (actionKey.isEmpty) return false;

    return _toBool(modulePerms[actionKey]) ?? false;
  }
}
