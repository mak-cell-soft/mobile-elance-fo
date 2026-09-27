# Project Status & Capabilities Audit — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Repository:** `git@github.com:mak-cell-soft/mobile-elance-fo.git`  
> **Last Verified:** September 2026

---

## 1. Implemented & Verified Capabilities

The following capabilities are fully implemented in the codebase and verified through static analysis (`flutter analyze`: clean) and automated testing (`flutter test`: 23 passing tests):

### Multi-Tenant Architecture
* **3-Tier Configuration Loading:** Loads from `assets/tenant_config.json`, then `assets/tenants/{tenantId}/config.json`, and falls back to compile-time `--dart-define` constants in `TenantBuildConfig`.
* **Tenant Session Storage:** Caches active tenant configuration and slug in `GetStorage` via `StorageService`.
* **Dynamic Branded Logos:** Dynamically resolves SVG logos per tenant (`assets/tenants/{tenantId}/logo.svg`) with fallback to global `assets/images/logo.svg`.
* **Active Tenant Packages:** Verified configurations for `socofeb` and `mansour-construction`.

### Theming & Design System
* **Arbor Industrial Design System:** Implemented via Material 3 in `lib/core/theme/tenant_theme.dart`.
* **Dynamic Theme Generation:** Consumes tenant-defined `primaryColor` and `secondaryColor` hex strings to build high-contrast dark and light themes.
* **Theme Switching:** Persistent user theme mode preference managed via `ThemeService`.

### Authentication & Session Security
* **Login Flow:** Dedicated screen, binding, and controller (`/login`) interfacing with `POST account/login`.
* **JWT Claim Decoding:** `StorageService` decodes user claims directly from the token: `userId`, `email`, `role`, `isAdmin`, `DefaultSiteId`, and granular `permissions`.
* **Automatic Request Interception:**
  * `AuthInterceptor`: Automatically attaches `Authorization: Bearer <token>` and `X-Tenant-Slug: <slug>`.
  * `ErrorInterceptor`: Automatically catches 401 Unauthorized responses, clears session, redirects to `/login`, and notifies the user.

### Feature Modules
* **Articles & Catalog:**
  * Catalog listing (`GET /article`) with client-side reactive search and multi-criteria filter sheet.
  * Categories and subcategories (`GET /Category`).
  * Real-time stock balances per site (`GET /Stock`).
  * Article detail view (`/articles/detail`).
* **Construction Sites (Chantiers):**
  * Site directory with search, status, and health filters (`GET /chantier`).
  * Detailed view with General, Suivi (Timeline), and Caisse tabs (`/chantiers/detail`).
  * Cash desk financial summary (`GET /chantier/{id}/caisse`).
  * Cash transaction ledger (`GET /chantier/{id}/caisse/transactions`).
  * Cash replenishment / Alimentation (`POST /chantier/{id}/caisse/alimentation`).
  * Expense / Disbursement requests with field user flow (`POST /chantier/{id}/caisse/sortie`).
  * Admin approval/rejection workflow (`POST /chantier/{id}/caisse/transactions/{txId}/validate`).
  * Progress timeline entries (`GET /chantier/{id}/progress-entries`).
  * Operational alerts (`GET /chantier/{id}/alerts`).
* **Purchases (Achats & Réceptions):**
  * Supplier receipt documents (*Bon de Réception*) (`POST /Document/_typefiltered`).
  * Counterpart supplier drop-down filtering (`GET /Counterpart/getall/Supplier`).
  * Monthly and annual period navigation bar.
  * Detailed document modal sheet displaying items, quantities, and totals.
* **Customers:**
  * Customer counterpart directory (`GET /CounterPart/GetAll/Customer`).
  * Instant search and native phone dialing via `url_launcher`.
* **Home / Executive Dashboard:**
  * KPI summary cards (`GET /Analytics/dashboard`).
  * Central vault cash balance (`GET /Caisse/principale/balance`).
  * Point of sale cash balances (`GET /Caisse/all`).
  * Supplier purchase vs. payment comparison chart.
  * Top-selling subcategories chart (`GET /Analytics/top-subcategories`).
* **Notifications & Alerts:**
  * Unread system notifications (`GET /notifications/unreads`).
  * Read confirmation (`PUT /notifications/{id}/read`) and dismissal (`DELETE /notifications/{id}`).
  * Inter-site stock transfer notifications (`GET /stock/notifications/missed`).
  * Critical stock threshold alerts (`GET /stock/alerts`).
* **User Profile & Settings:**
  * Profile view and profile modification (`GET /Account/profile/{id}`, `PUT /Account/update-profile`).
  * AppVariables configuration (`GET /AppVariable/getall/{nature}`, `POST`, `PUT`, `DELETE`).
  * Daily invoice ceiling management (`POST /AppVariable/daily-ceiling`).

### Navigation & Routing
* Complete GetX route structure in `AppRoutes` and `AppPages`.
* Route protection via `AdminGuardMiddleware` and `ChantierGuardMiddleware`.

### Build & Scripting
* Android Gradle product flavors: `development`, `socofeb`, `mansour_construction`.
* PowerShell tenant build script: `scripts/build_tenant.ps1`.
* Dual-remote Git push configuration (`origin` + `mobile-elance-fo`).

---

## 2. In-Progress Capabilities

* **Structured i18n Dictionary System:**
  * *Current State:* All UI strings, error messages, and snackbars are implemented directly in French. `intl` is initialized for French date formatting.
  * *Pending:* Creation of a formal localized key-value catalog (e.g. `.arb` files or GetX `Translations`) to support runtime language switching between French, Arabic, and English based on the tenant's `language` parameter.
* **Android Release Keystore Configuration:**
  * *Current State:* `android/app/build.gradle.kts` release build type currently points to Android's debug signing key (`signingConfig = signingConfigs.getByName("debug")`).
  * *Pending:* Integration of a production keystore configuration driven by secure environment variables.

---

## 3. Planned Capabilities

* **Automated Multi-Tenant CI/CD Pipeline:**
  * GitHub Actions workflow triggered from `admin.acya.site` / ACYA API.
  * Automatic injection of tenant config, branding assets, and Android signing keys.
  * Publishing of signed APKs to `downloads.acya.site/mobile/{tenantId}/`.
* **Sales Order Creation (Bons de Commande):**
  * Mobile order taking and quotation generation for field sales representatives.
* **Offline-First Synchronization:**
  * Local SQLite/Hive cache allowing field technicians and site managers to review documents and record expenses without active cellular coverage.

---

## 4. Known Technical Limitations

1. **Single Backend Server:** All flavors (`development`, `preprod`, `production`) currently route to the single deployed production server at `https://acya.site/api/`. Isolated staging or sandbox backend instances are not yet provisioned.
2. **Binary APKs in Git History:** Previous release APKs (~55MB each) were committed to `assets/apks_tenants/`, causing GitHub file size warnings (`GH001`). No new binary APKs should be committed.
3. **In-Memory Catalog Filtering:** The backend endpoint `GET /article` returns the full non-deleted catalog without server-side pagination. Search, category filtering, and sorting are executed entirely client-side.
