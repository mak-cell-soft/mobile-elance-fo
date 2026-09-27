# Build and Release Guide — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Status:** Active & Verified from Codebase

---

## 1. Local Development Execution

The app supports multiple entry points corresponding to operational environments:

```bash
# Development (Default)
flutter run -t lib/main_development.dart

# Pre-production
flutter run -t lib/main_preprod.dart

# Production
flutter run -t lib/main_production.dart
```

When targeting a specific Android flavor during development:
```bash
flutter run -t lib/main_production.dart --flavor=socofeb
flutter run -t lib/main_production.dart --flavor=mansour_construction
```

---

## 2. Android Gradle Configuration

Defined in `android/app/build.gradle.kts`:

### Flavor Dimension
```kotlin
flavorDimensions += "tenant"

productFlavors {
    create("development") {
        dimension = "tenant"
        applicationId = "com.example.woodapp"
        resValue("string", "app_name", "WoodApp")
    }
    create("socofeb") {
        dimension = "tenant"
        applicationId = "com.socofeb.woodapp"
        resValue("string", "app_name", "socofeb")
    }
    create("mansour_construction") {
        dimension = "tenant"
        applicationId = "com.mansourconstruction.woodapp"
        resValue("string", "app_name", "Mansour Construction")
    }
}
```

> [!NOTE]
> Gradle flavor identifiers cannot contain hyphens. The tenant slug `mansour-construction` is mapped to `mansour_construction` in Gradle.

---

## 3. Compile-Time Parameters (`--dart-define`)

The application consumes compile-time constants through `TenantBuildConfig` (`lib/core/config/tenant_build_config.dart`):

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `TENANT_ID` | `socofeb` | Tenant slug identifier |
| `COMPANY_NAME` | `SOCOFEB` | Legal enterprise name |
| `APP_NAME` | `socofeb` | Display app name |
| `PACKAGE_NAME` | `com.socofeb.woodapp` | Android package ID |
| `PRIMARY_COLOR` | `#1B4332` | Primary brand color (Hex) |
| `SECONDARY_COLOR` | `#2D6A4F` | Secondary accent color (Hex) |
| `BASE_URL` | `https://acya.site/api/`| Backend API endpoint |
| `ENVIRONMENT` | `production` | Target deployment environment |
| `SUPPORTED_LOCALES`| `fr` | Locale definition |
| `ASSETS_PATH` | `assets/tenants/socofeb/` | Path to tenant assets |
| `HAS_CHANTIER_MODULE` | `true` | Boolean flag enabling construction module |

---

## 4. Tenant Build Script (`build_tenant.ps1`)

The repository includes a PowerShell automation script: `scripts/build_tenant.ps1`.

### Basic Usage
```powershell
# Build SOCOFEB APK
.\scripts\build_tenant.ps1 -TenantId socofeb

# Build Mansour Construction APK
.\scripts\build_tenant.ps1 -TenantId mansour-construction
```

### What the Script Performs
1. Reads `assets/tenants/{tenantId}/config.json` (or `assets/tenant_config.json`) to populate default parameters.
2. Formats the Gradle flavor name (replaces `-` with `_`).
3. Executes `flutter build apk` with all required `--dart-define` parameters.
4. Generates a date-stamped copy in `build/app/outputs/flutter-apk/app-{tenantId}-release-{dd_MM_yyyy}.apk`.
5. Copies the output artifact to `assets/apks_tenants/`.

> [!WARNING]
> **Git Repository Warning regarding `assets/apks_tenants/`:**  
> APK files are ~55MB each. Committing built APKs to Git triggers GitHub file size warnings (>50MB). Do **not** commit new binary APKs to version control; store them on designated artifact servers or Git LFS.

---

## 5. Android Signing Status

Currently in `android/app/build.gradle.kts`:
```kotlin
buildTypes {
    release {
        // Signing with debug keys for local release validation
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

* **Current Status:** Release builds are signed using Android's standard debug keys so that testing `flutter run --release` works out of the box without requiring developer secrets.
* **Production Requirement:** For public or formal distribution, a production keystore (`.jks` / `.keystore`) must be configured with credentials supplied via environment variables (`KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).

### Security Rule
> [!CAUTION]
> **Never commit `.keystore`, `.jks`, or signing credentials to this repository.**  
> Keystores must be injected in CI/CD via GitHub Secrets or kept in secure offline vaults.

---

## 6. Automated CI/CD Architecture (Implemented)

The repository includes the automated tenant build workflow in .github/workflows/mobile-build.yml.

```text
1. Admin Portal (admin.acya.site)
      │ POST /api/admin/mobile/builds
      ▼
2. ACYA Backend API
      │ Dispatches GitHub Actions workflow via REST API (workflow_dispatch)
      ▼
3. GitHub Actions Workflow (.github/workflows/mobile-build.yml)
      │ - Authenticates with ACYA API via X-CI-Token
      │ - Sets status to Building: PATCH /api/admin/mobile/builds/{id}/status
      │ - Fetches dynamic tenant config: GET /api/admin/mobile/builds/{id}/config
      │ - Validates configuration (tenantId, packageName, baseUrl, colors)
      │ - Generates assets/tenant_config.json & stages tenant assets
      │ - Sets up Flutter 3.44.x & Java 17
      │ - Injects Android release keystore from ANDROID_KEYSTORE_BASE64
      │ - Runs test suite: flutter test
      │ - Builds signed APK: flutter build apk --release --flavor={flavor} --dart-define=...
      │ - Computes exact SHA-256 and byte size
      │ - Uploads APK to private storage: POST /api/admin/mobile/builds/{id}/artifact
      │ - Updates build status to Succeeded: PATCH /api/admin/mobile/builds/{id}/status
      ▼
4. ACYA Private Artifact Storage (/storage/private/mobile/{tenantId}/{build}/)
      │ Secure storage outside public web roots
      ▼
5. ACYA Download Portal (Planned: downloads.acya.site/mobile/{tenantId}/)
      │ Download with short-lived HMAC-SHA256 signed token
      ▼
6. Tenant Client Device Installs APK
```

### Required GitHub Secrets:
* ACYA_CI_TOKEN: Least-privilege CI token for authenticating runner callbacks to ACYA API.
* ACYA_API_BASE_URL (optional): Base URL for ACYA API (defaults to https://acya.site/api/).
* ANDROID_KEYSTORE_BASE64 (optional for production): Base64-encoded Android release keystore (.jks / .keystore).
* ANDROID_KEYSTORE_PASSWORD: Password for the Android release keystore.
* ANDROID_KEY_ALIAS: Alias of the release signing key.
* ANDROID_KEY_PASSWORD: Password of the release signing key.

### Architectural Guardrails for Agents
* Never add code that requires manual editing of Dart files to support a new tenant.
* Always ensure tenant configuration can be passed via JSON file or --dart-define.
* Never commit secrets, passwords, or keystores into the repository.
