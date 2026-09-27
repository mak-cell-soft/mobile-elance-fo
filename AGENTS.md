# AGENTS.md — WoodApp Mobile (Élancé / ACYA)

> **Audience:** AI Coding Agents & Engineers  
> **Repository:** `git@github.com:mak-cell-soft/mobile-elance-fo.git` (also synchronized with `git@github.com:afsus12/WOODAPP.git`)  
> **Last Verified:** September 2026

---

## 1. Project Overview

**WoodApp Mobile** is the multi-tenant cross-platform mobile client for the **Élancé / ACYA** enterprise platform (specialized ERP for timber trading, wood industry, building materials, and construction site management).

### Key Characteristics
* **White-Label & Multi-Tenant:** A single Flutter codebase serves multiple enterprise tenants (e.g., SOCOFEB, Mansour Construction). Each tenant receives custom branding, colors, app name, logo, Android package identity, and feature toggles.
* **Shared Backend:** The mobile app connects to the existing ACYA C# .NET REST API deployed at `https://acya.site/api/`. The backend is the source of truth and must **never** be altered by mobile tasks.
* **Dual-Remote Repository:** The repository is configured to push simultaneously to both the legacy remote (`afsus12/WOODAPP.git`) and the primary organization remote (`mak-cell-soft/mobile-elance-fo.git`).

---

## 2. Quick Documentation Index

To maintain single-source-of-truth and avoid conflicting documentation, detailed technical guides are partitioned under `docs/`:

| Document | Purpose |
| :--- | :--- |
| [Architecture Guide](docs/ARCHITECTURE.md) | Layer boundaries, directory map, data flow, DI, and patterns |
| [Tenant System](docs/TENANT_SYSTEM.md) | Multi-tenant branding, config loading, feature flags, and rules |
| [Build & Release](docs/BUILD_AND_RELEASE.md) | Gradle flavors, `--dart-define`, release builds, signing, CI/CD |
| [API Integration](docs/API.md) | Endpoints, headers (`X-Tenant-Slug`, JWT), request/response DTOs |
| [Development Guide](docs/DEVELOPMENT.md) | Prerequisites, running locally, debugging, linting, and testing |
| [AI Agent Rules](docs/AI_AGENT_RULES.md) | Mandatory protocol, safety constraints, and review checklist |
| [Project Status](docs/PROJECT_STATUS.md) | Implemented modules, in-progress items, planned pipeline, limitations |
| [Changelog](docs/CHANGELOG.md) | Log of notable changes |

---

## 3. Critical Architecture Rules

The codebase follows a strict separation of concerns using **GetX**:

```text
UI (Views & Feature Widgets)
        ↓
Controllers (GetxController with Rx observables)
        ↓
Feature Services (Business & Data Services)
        ↓
Network Layer (ApiClient Dio singleton + Interceptors)
        ↓
Backend REST API (https://acya.site/api/)
```

### Strict Rules for Agents
1. **Views do NOT make HTTP requests:** Views only trigger controller actions and react to state via `Obx(() => ...)` or `GetView<T>`.
2. **State lives in Controllers:** Never store mutable domain state inside StatefulWidget states or global variables.
3. **Services communicate via `ApiClient`:** All HTTP requests must use `ApiClient.instance.dio` so headers, authentication tokens, and logging are applied consistently.
4. **JWT & Tenant Slug must travel together:** The backend validates `Authorization: Bearer <token>` alongside `X-Tenant-Slug: <slug>`. The `AuthInterceptor` attaches both automatically.
5. **Controllers are registered in Bindings:** Every route in `lib/routes/app_pages.dart` uses a `Binding` to lazily inject its controller.

---

## 4. Tenant Architecture Summary

Tenants are identified by a unique alphanumeric slug (`tenantId`, e.g. `socofeb`, `mansour-construction`).

### Configuration Resolution Hierarchy
When the app boots, `TenantConfig.loadActiveConfig()` evaluates:
1. `assets/tenant_config.json` (active runtime config override)
2. `assets/tenants/{tenantId}/config.json` (tenant package directory)
3. Compile-time `--dart-define` constants via `TenantBuildConfig` (fallback defaults)

### Active Example Configuration
```json
{
  "tenantId": "socofeb",
  "companyName": "SOCOFEB",
  "appName": "SOCOFEB",
  "packageName": "com.socofeb.woodapp",
  "name": "SOCOFEB",
  "logo": "assets/tenants/socofeb/logo.svg",
  "primaryColor": "#1E3A8A",
  "secondaryColor": "#3B82F6",
  "baseUrl": "https://acya.site/api/",
  "environment": "production",
  "supportedLocales": "fr",
  "assetsPath": "assets/tenants/socofeb/",
  "language": "fr",
  "currency": "TND",
  "status": "Active",
  "hasChantierModule": true
}
```

> [!IMPORTANT]
> This JSON is an **example**. Agents must **never hard-code** SOCOFEB or any single tenant's values into application logic.

### Feature Flags & Permissions
* **`hasChantierModule`:** Controls visibility and route access (`ChantierGuardMiddleware`) to construction site management. Checked hierarchically: compile-time define -> JWT claim `IsManagingConstructions` -> runtime tenant config.
* **`StorageService.instance.hasPermission(module, action)`:** Evaluates permissions encoded directly in the JWT payload claims for the authenticated user.
* **`StorageService.instance.isAdmin`:** Checks if the user holds Admin or SuperAdmin roles (`role == '10'` or `'20'`).

*For full details, see [Tenant System](docs/TENANT_SYSTEM.md).*

---

## 5. API & Network Conventions

* **Base URL:** `EnvConfig.apiBaseUrl` (defaults to `https://acya.site/api/`). Can be updated dynamically per tenant via `ApiClient.instance.setBaseUrl(...)`.
* **Client Location:** `lib/core/network/api_client.dart`
* **Interceptors:**
  * `AuthInterceptor`: Attaches `Authorization: Bearer <token>` and `X-Tenant-Slug: <slug>`.
  * `LoggingInterceptor`: Pretty logs outgoing requests and responses.
  * `ErrorInterceptor`: Catches `401 Unauthorized`, clears local session, redirects to `/login`, and displays an expired-session snackbar.
* **Error Handling:** Wrap service calls in `try/catch` on `DioException` and rethrow `ApiException.fromDioException(e)`.

*For the complete catalog of verified endpoints, see [API Integration Guide](docs/API.md).*

---

## 6. Navigation & Routes

Defined centrally in `lib/routes/`:
* `AppRoutes` (`lib/routes/app_routes.dart`): Static route string constants (`/splash`, `/login`, `/home`, `/articles`, `/chantiers`, etc.).
* `AppPages` (`lib/routes/app_pages.dart`): Route definitions with views, bindings, and middlewares.
* **Route Guards:**
  * `AdminGuardMiddleware`: Restricts route (e.g. `/receipts`) to Admin/SuperAdmin.
  * `ChantierGuardMiddleware`: Redirects to `/home` if `hasChantierModule` is false.

---

## 7. UI & Design System

The application implements the **Arbor Industrial** design system via Material 3:
* **Theme Builder:** `lib/core/theme/tenant_theme.dart` (`TenantTheme.buildDark()` and `TenantTheme.buildLight()`).
* **Palette:**
  * Dark mode surface: `#041329` (Nocturnal Navy)
  * Surface container: `#112036`
  * Text: High-contrast cool grey `#D6E3FF`
  * Brand Accent: Dynamically seeded from tenant's `primaryColor` and `secondaryColor` hex strings.
* **Component Standards:**
  * Cards: `16px` border radius with subtle outline (`outlineVariant.withValues(alpha: 0.6)`).
  * Inputs: `14px` border radius, filled container background.
  * Buttons: `14px` border radius, high-contrast foreground color on primary background.
  * Status States: Use `ViewStatus` enum (`lib/core/utils/view_status.dart`: `initial`, `loading`, `success`, `empty`, `error`).

---

## 8. Localization & Strings

* **Current Language:** French (`fr` / `fr_FR`).
* **Locale Setup:** Initialized via `initializeDateFormatting('fr_FR', null)` in `lib/main.dart`.
* **Constraint:** All user-facing UI text is currently in French. Agents must maintain French text for user-facing labels, snackbars, and error messages. Do not mix unlocalized English strings into the interface.

---

## 9. Security Constraints

Agents must strictly enforce:
1. **Never commit secrets:** No `.keystore`, `.jks`, passwords, API tokens, or private keys.
2. **Never log credentials or JWTs:** Sanitized logging only.
3. **Never disable TLS verification:** Always preserve secure HTTPS connections.
4. **Never bypass permissions:** Respect `AdminGuardMiddleware`, `ChantierGuardMiddleware`, and `StorageService.hasPermission`.

---

## 10. Git Rules

The local repository is configured with dual push destinations:
```text
origin              git@github.com:afsus12/WOODAPP.git (fetch)
origin              git@github.com:afsus12/WOODAPP.git (push)
origin              git@github.com:mak-cell-soft/mobile-elance-fo.git (push)
mobile-elance-fo    git@github.com:mak-cell-soft/mobile-elance-fo.git (fetch)
mobile-elance-fo    git@github.com:mak-cell-soft/mobile-elance-fo.git (push)
```

* **Never delete or overwrite this remote setup.**
* **Routine pushes:** `git push` automatically pushes to **both** remotes.
* **Inspection before git actions:**
  ```bash
  git remote -v
  git status
  git branch -vv
  ```
* **No force-pushing or history rewriting:** Strictly prohibited without explicit authorization.

---

## 11. Verified Build & Verification Commands

All commands run from the project root (`WOODAPP`):

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis (must report: No issues found!)
flutter analyze

# 3. Run unit and widget tests (23 passing tests)
flutter test

# 4. Check formatting without mutating files
dart format --output=none --set-exit-if-changed .

# 5. Run locally in development
flutter run -t lib/main_development.dart

# 6. Build tenant release APK via PowerShell script
.\scripts\build_tenant.ps1 -TenantId socofeb
.\scripts\build_tenant.ps1 -TenantId mansour-construction
```

---

## 12. Automated Build System Pipeline (Implemented)

ACYA employs an automated APK generation pipeline (.github/workflows/mobile-build.yml):

```text
admin.acya.site
       ↓
ACYA API
       ↓
Build Request
       ↓
GitHub Actions Workflow
       ↓
Tenant Configuration & Asset Injection
       ↓
flutter build apk --flavor={tenant} --dart-define=...
       ↓
Signed APK
       ↓
downloads.acya.site/mobile/{tenantId}/
       ↓
Tenant Customer Download
```

### Critical Compatibility Requirement
Agents **must never** introduce architecture that requires manual source code modification to onboard or build for a new tenant. All tenant differences must be driven exclusively through:
* `assets/tenants/{tenantId}/`
* `--dart-define` compile-time parameters
* Runtime API fetches (`GET /enterprise/config`)
