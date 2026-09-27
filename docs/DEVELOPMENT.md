# Developer & Agent Onboarding Guide — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Status:** Active & Verified from Codebase

---

## 1. Prerequisites & Environment

Before developing or running tests on WoodApp Mobile, verify your toolchain matches the repository's verified baseline:

* **Flutter SDK:** `3.44.8` (channel stable)
* **Dart SDK:** `3.12.2`
* **Java Development Kit:** JDK 17 (required for Gradle and Android compilation)
* **Android SDK:** Compile SDK 34+, NDK matching flutter version
* **Git:** Configured with SSH access to GitHub

Check your local environment:
```bash
flutter --version
dart --version
java -version
```

---

## 2. Installation & Initial Setup

1. **Clone & Navigate:**
   ```bash
   cd c:\Users\amine\StudioProjects\Elance\WOODAPP
   ```

2. **Fetch Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Static Analysis:**
   ```bash
   flutter analyze
   ```
   *Expected output: `No issues found!`*

4. **Run Unit & Widget Tests:**
   ```bash
   flutter test
   ```
   *Expected output: `All tests passed!` (23 tests)*

---

## 3. Running Locally

### Development Mode (Default)
Runs with hot-reload enabled, debug banner hidden, and dev configuration:
```bash
flutter run -t lib/main_development.dart
```

### Pre-production & Production Flavors
```bash
# Preprod
flutter run -t lib/main_preprod.dart

# Production with SOCOFEB flavor
flutter run -t lib/main_production.dart --flavor=socofeb

# Production with Mansour Construction flavor
flutter run -t lib/main_production.dart --flavor=mansour_construction
```

---

## 4. Code Quality & Verification Commands

Always run these verification commands before presenting changes:

```bash
# Static analysis
flutter analyze

# Test suite
flutter test

# Check formatting (does not modify files)
dart format --output=none --set-exit-if-changed .

# Re-format code if required
dart format .
```

---

## 5. Troubleshooting & Known Gotchas

### 1. `LocaleDataException` on French Date Formatting
* **Symptom:** Crash or exception when formatting dates with `DateFormat.yMMMMd('fr')`.
* **Cause:** `intl` package requires explicit date symbol initialization for non-English locales.
* **Fix:** Already handled in `lib/main.dart` via `await initializeDateFormatting('fr_FR', null)`. Do not remove this initialization call.

---

### 2. HTTP 401 Unauthorized / Token Rejection
* **Symptom:** Valid login credentials succeed, but subsequent calls to protected endpoints fail with 401.
* **Cause:** The ACYA backend strictly validates that the `X-Tenant-Slug` header matches the `tenant_slug` claim inside the JWT token.
* **Fix:** Ensure both `Authorization: Bearer <token>` and `X-Tenant-Slug: <slug>` headers are attached. `AuthInterceptor` manages this automatically; do not bypass `ApiClient.instance.dio`.

---

### 3. Large File Warning on Git Push (`GH001`)
* **Symptom:** Warning during push: `File assets/apks_tenants/... is 55.98 MB; this is larger than GitHub's recommended maximum file size of 50.00 MB`.
* **Cause:** Build script `scripts/build_tenant.ps1` previously deposited built release APKs into `assets/apks_tenants/`, which were tracked in git.
* **Rule:** Do **not** commit new `.apk` or `.aab` binaries to git. Keep them in `build/` or upload them directly to artifact distribution servers.

---

### 4. Gradle Flavor Hyphenation Error
* **Symptom:** Gradle build fails with syntax errors when passing `--flavor=mansour-construction`.
* **Cause:** Android Gradle plugins reject hyphens (`-`) in product flavor names.
* **Rule:** Gradle flavors use underscores (e.g. `mansour_construction`), while tenant IDs in JSON and API calls use hyphens (e.g. `mansour-construction`). `build_tenant.ps1` automatically translates hyphens to underscores for Gradle.

---

### 5. Dual Remote Git Synchronization
* **Symptom:** Push goes to one repository but not the other.
* **Verification:** Run `git remote -v`. Ensure `origin` has two push URLs:
  1. `git@github.com:afsus12/WOODAPP.git`
  2. `git@github.com:mak-cell-soft/mobile-elance-fo.git`
* **Rule:** Never delete or overwrite this dual-remote configuration.
