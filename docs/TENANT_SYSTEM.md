# Multi-Tenant & White-Label System — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Status:** Active & Verified from Codebase

---

## 1. System Philosophy

WoodApp is designed as a **white-label mobile platform** serving distinct enterprise clients ("tenants") of the Élancé / ACYA ERP. Each company receives a customized application experience that mirrors their corporate identity, operational currency, and subscription modules while sharing 100% of the underlying codebase.

---

## 2. Tenant Identity & Parameters

A tenant is defined by an identity model (`TenantConfig` in `lib/features/tenant/models/tenant_config.dart`):

| Parameter | Type | Purpose | Example |
| :--- | :--- | :--- | :--- |
| `tenantId` | `String` | Unique alphanumeric slug identifying the enterprise | `"socofeb"`, `"mansour-construction"` |
| `companyName` | `String` | Legal enterprise name displayed on documents and titles | `"SOCOFEB"`, `"Mansour Construction"` |
| `appName` | `String` | Brand name displayed on app bars and splash screens | `"SOCOFEB"` |
| `packageName` | `String` | Android application ID | `"com.socofeb.woodapp"` |
| `primaryColor` | `String` (Hex) | Primary brand color token for theme generation | `"#1E3A8A"`, `"#1B4332"` |
| `secondaryColor`| `String` (Hex) | Secondary accent color token | `"#3B82F6"`, `"#2D6A4F"` |
| `logo` | `String` (Path)| Local SVG asset path for branding | `"assets/tenants/socofeb/logo.svg"` |
| `baseUrl` | `String` (URL) | Backend API endpoint URL | `"https://acya.site/api/"` |
| `language` | `String` | Preferred UI locale | `"fr"` |
| `currency` | `String` | Financial currency symbol/ISO code | `"TND"`, `"MAD"` |
| `status` | `String` | Tenant subscription status (`Active`, `Suspended`) | `"Active"` |
| `hasChantierModule`| `bool` | Feature flag enabling construction site management | `true` or `false` |
| `isManagingConstructions`| `bool` | Tenant-level feature flag for construction tracking | `true` or `false` |

---

## 3. Configuration Resolution Hierarchy

When the application launches (`lib/main.dart`), `TenantConfig.loadActiveConfig()` searches in order:

```text
1. assets/tenant_config.json (Root override if present)
      │ (not found or invalid)
      ▼
2. assets/tenants/{tenantId}/config.json (Tenant asset directory)
      │ (not found or invalid)
      ▼
3. TenantConfig.fromBuildConfig() (Compile-time --dart-define fallback)
```

### Stored Tenant Session
Once resolved, the configuration is stored in local storage:
```dart
await StorageService.instance.saveTenantSlug(activeConfig.tenantId);
await StorageService.instance.saveTenantConfig(activeConfig.toJson());
ApiClient.instance.setBaseUrl(activeConfig.baseUrl);
```

---

## 4. Android Identity & Package Names

In multi-tenant white-label distributions, each tenant **must** possess a unique Android package name (`applicationId`):

* SOCOFEB: `com.socofeb.woodapp`
* Mansour Construction: `com.mansourconstruction.woodapp`
* Development Default: `com.example.woodapp`

### Why Unique Package Names Are Mandatory
1. **Side-by-side Installation:** Field supervisors, auditors, and contractors who work across multiple companies must be able to install both SOCOFEB and Mansour Construction apps on the same mobile device without package collision.
2. **Notification & Identity Isolation:** Operating system notifications, app sandboxing, and local device caches remain completely isolated per company.
3. **App Store & MDM Deployment:** Allows separate publication or distribution via enterprise MDM / APK portals (`downloads.acya.site/mobile/{tenantId}/`).

---

## 5. Asset Organization

Tenant assets reside under `assets/tenants/{tenantId}/`:

```text
assets/
├── images/
│   └── logo.svg                                # Global fallback logo
├── tenants/
│   ├── socofeb/
│   │   ├── config.json                         # SOCOFEB tenant config
│   │   └── logo.svg                            # SOCOFEB branded SVG logo
│   └── mansour-construction/
│       ├── config.json                         # Mansour Construction config
│       └── logo.svg                            # Mansour Construction branded SVG logo
└── tenant_config.json                          # Active runtime config (copied or injected)
```

Declared in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/tenant_config.json
    - assets/images/logo.svg
    - assets/tenants/socofeb/
    - assets/tenants/mansour-construction/
```

> [!NOTE]
> When adding a new tenant directory under `assets/tenants/`, remember to declare its folder in `pubspec.yaml` so Flutter bundles its SVG and configuration into the app package.

---

## 6. Dynamic Theming

Brand colors are not hard-coded in the UI. Instead, the `TenantTheme` engine (`lib/core/theme/tenant_theme.dart`) consumes hex strings from the active `TenantConfig`:

```dart
final primaryColor = cfg.primaryColor ?? TenantBuildConfig.primaryColor;
final secondaryColor = cfg.secondaryColor ?? TenantBuildConfig.secondaryColor;

GetMaterialApp(
  theme: TenantTheme.buildLight(
    primaryColorHex: primaryColor,
    secondaryColorHex: secondaryColor,
  ),
  darkTheme: TenantTheme.buildDark(
    primaryColorHex: primaryColor,
    secondaryColorHex: secondaryColor,
  ),
  ...
);
```

Components throughout the app inherit these colors naturally through `Theme.of(context).colorScheme.primary` or `colorScheme.secondary`.

---

## 7. Feature Flags & Module Toggling

### `hasChantierModule`
Controls whether the Chantiers (Construction Sites) module is accessible.
* **Resolution Priority:**
  1. Compile-time `--dart-define=HAS_CHANTIER_MODULE=false`
  2. Logged-in enterprise verification (`isManagingConstructions` from `GET /enterprise/getbyid/{id}` or JWT claim)
  3. Runtime tenant configuration (`hasChantierModule` flag or `modules` array)
* **Enforcement:**
  * Route level: `ChantierGuardMiddleware` redirects unauthorized access back to `/home`.
  * UI level: Dashboard tiles and navigation drawers check `StorageService.instance.hasChantierModule`.

---

## 8. Rules for AI Agents: BAD vs. GOOD

### Rule 1: Never Hard-Code a Tenant Slug or Company Name

❌ **BAD:**
```dart
// Hard-coding SOCOFEB assumptions
if (tenantSlug == 'socofeb') {
  showSpecialDiscountBanner();
}
Text('Bienvenue chez SOCOFEB');
```

✅ **GOOD:**
```dart
// Sourcing from dynamic tenant configuration or feature flag
if (tenantConfig.hasFeature('special_discounts')) {
  showSpecialDiscountBanner();
}
final companyName = StorageService.instance.tenantConfig?['companyName'] ?? 'WoodApp';
Text('Bienvenue chez $companyName');
```

---

### Rule 2: Never Hard-Code Colors or Icons for a Tenant

❌ **BAD:**
```dart
// Hard-coded blue specific to SOCOFEB
Container(
  color: Color(0xFF1E3A8A),
  child: SvgPicture.asset('assets/tenants/socofeb/logo.svg'),
)
```

✅ **GOOD:**
```dart
// Using Theme colorScheme and dynamic logo path
final logoPath = StorageService.instance.tenantConfig?['logo'] ?? TenantBuildConfig.logoPath;
Container(
  color: Theme.of(context).colorScheme.primary,
  child: SvgPicture.asset(logoPath),
)
```

---

### Rule 3: Never Assume SOCOFEB is the Only Tenant

Always verify that code changes work seamlessly with other tenants (e.g. `mansour-construction` or generic builds).
