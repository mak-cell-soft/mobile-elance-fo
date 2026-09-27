# AI Coding Agent Operating Rules — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Status:** Mandatory Behavioral Standard

---

## 1. Operating Protocol Before Modifying Code

Every AI agent working in this repository must execute these steps sequentially:

1. **Read `AGENTS.md`:** Always start with `AGENTS.md` and read the relevant deep-dive document under `docs/` (`ARCHITECTURE.md`, `TENANT_SYSTEM.md`, etc.).
2. **Inspect Existing Implementations:** Search for existing patterns before creating new files.
   * If adding a view, inspect an existing feature view (e.g. `lib/features/chantiers/views/`).
   * If adding a network call, check the existing service for that domain under `lib/features/*/services/`.
3. **Reuse Existing Components & Tokens:**
   * Theme colors: Always use `Theme.of(context).colorScheme.*`.
   * Card styling: Use standard `Card` (styled globally in `TenantTheme`).
   * State enum: Use `ViewStatus` (`lib/core/utils/view_status.dart`).
4. **Avoid Unnecessary Refactoring:** Keep edits minimal, precise, and focused strictly on the requested task. Do not reformat or reorganize unrelated files.

---

## 2. Component & Service Rules

### Before Creating a New Widget
* Search `lib/features/*/widgets/` and `lib/core/theme/` to confirm a similar component does not already exist.
* If a widget is used in more than one feature, place it in an appropriate shared location with clear justification.
* Widgets must be small, composable, and responsive.

### Before Creating a New Service
* Inspect the service catalog in [API Guide](API.md).
* Most endpoints for articles, stock, customers, chantiers, receipts, and analytics are already implemented.
* If a new endpoint is needed, add it to the existing domain service rather than creating duplicate services.

### Before Changing Tenant Configuration
* Check [Tenant System Guide](TENANT_SYSTEM.md).
* Verify how the field is loaded in `TenantConfig` and whether it requires a fallback in `TenantBuildConfig`.
* Ensure that the change remains backward-compatible with all existing tenants (`socofeb`, `mansour-construction`).

### Before Modifying Android / Build Files
* Inspect `android/app/build.gradle.kts` and `pubspec.yaml`.
* Understand how any changes affect Gradle product flavors (`flavorDimensions += "tenant"`) and automated CI/CD builds.

---

## 3. The "NEVER" List

An agent must **never**:
1. ❌ **Never hard-code tenant values:** No hard-coded `socofeb` strings, company names, or colors in generic code.
2. ❌ **Never modify Git remotes:** The dual-remote setup (`origin` + `mobile-elance-fo`) must be preserved.
3. ❌ **Never force push (`git push -f`):** Strictly forbidden.
4. ❌ **Never rewrite Git history or delete branches.**
5. ❌ **Never commit secrets:** No `.keystore`, `.jks`, passwords, API tokens, or private credentials.
6. ❌ **Never delete existing functionality or tests:** Do not remove existing logic to simplify a new feature.
7. ❌ **Never alter the backend:** The C# backend is an external source of truth and must never be modified by mobile tasks.
8. ❌ **Never disable security controls or TLS:** Preserving HTTPS and session authorization is non-negotiable.
9. ❌ **Never commit large binaries (>50MB):** Do not commit built `.apk` or `.aab` files into `assets/apks_tenants/`.
10. ❌ **Never modify dependencies in `pubspec.yaml` unnecessarily:** Adding or upgrading dependencies requires clear technical justification.

---

## 4. Verification Protocol After Modifying Code

After completing any code modifications, the agent must execute:

```bash
# 1. Static Analysis
flutter analyze

# 2. Test Suite Execution
flutter test

# 3. Formatting Verification
dart format --output=none --set-exit-if-changed .
```

### Reporting Requirements
In the final response to the user, the agent must report:
* The exact files created, modified, or deleted.
* The output of `flutter analyze` (must be: *No issues found!*).
* The output of `flutter test` (must confirm all tests pass).
* Any architectural assumptions or open questions requiring developer input.
