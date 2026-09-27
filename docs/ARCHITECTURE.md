# Technical Architecture — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Status:** Active & Verified from Codebase  
> **Target Framework:** Flutter 3.44.8 / Dart 3.12.2

---

## 1. High-Level Architecture Overview

WoodApp Mobile is built with a feature-driven, clean-layer architecture powered by **GetX** for state management, dependency injection, and routing, combined with **Dio** for HTTP transport.

```text
lib/
├── core/                       # Shared framework utilities, services & cross-cutting concerns
│   ├── config/                 # Flavors, environment & compile-time tenant configuration
│   ├── network/                # ApiClient singleton, interceptors & custom exceptions
│   ├── storage/                # StorageService wrapping GetStorage for session & cache
│   ├── theme/                  # Arbor Industrial dynamic theme generator & ThemeService
│   └── utils/                  # Enums (ViewStatus), date helpers & formatting tools
│
├── features/                   # Self-contained business capability modules
│   ├── articles/               # Catalog, article details, categories, and stock
│   ├── auth/                   # Login, session establishment & credential management
│   ├── chantiers/              # Construction sites, financial caisse, progress & alerts
│   ├── customers/              # Counterpart customer directory
│   ├── home/                   # Dashboard analytics, treasury balances, and KPI summaries
│   ├── notifications/          # System alerts, transfer alerts & stock threshold notices
│   ├── profile/                # User profile viewing and profile modification
│   ├── purchases/              # Supplier reception documents (Bon de Réception) & period filters
│   ├── settings/               # App variables, daily invoice ceiling, workflow automation
│   ├── splash/                 # Entrance animated screen & redirection routing
│   └── tenant/                 # Multi-tenant configuration, dynamic logos & selector
│
├── routes/                     # Centralized GetX routing table & route guard middlewares
│   ├── app_pages.dart          # GetPage list mapping routes to views and bindings
│   └── app_routes.dart         # Constant string route names
│
├── main.dart                   # Default entry point (Flavor.development) & bootstrap sequence
├── main_development.dart       # Development entry point
├── main_preprod.dart           # Pre-production entry point
└── main_production.dart        # Production entry point
```

---

## 2. Directory & Layer Guidelines

### `lib/core/`
* **Purpose:** Reusable infrastructure used across multiple features.
* **Belongs here:**
  * `core/config/`: `EnvConfig` (flavor definitions) and `TenantBuildConfig` (compile-time `--dart-define` bindings).
  * `core/network/`: `ApiClient` (Dio instance), `ApiException`, and interceptors (`AuthInterceptor`, `LoggingInterceptor`, `ErrorInterceptor`).
  * `core/storage/`: `StorageService` (typed abstraction over `GetStorage` managing auth tokens, decoded JWT claims, tenant slugs, and permissions).
  * `core/theme/`: `TenantTheme` (dynamic Material 3 theme generation) and `ThemeService` (light/dark mode toggle).
  * `core/utils/`: Generic UI utilities such as `ViewStatus` (`initial`, `loading`, `success`, `empty`, `error`).
* **Does NOT belong here:** Screen views, feature controllers, DTOs specific to a single endpoint, feature-specific business logic.

---

### `lib/features/{feature_name}/`
Every feature follows a standardized internal folder structure:

```text
features/{feature_name}/
├── bindings/       # GetX Bindings injecting controllers and services
├── controllers/    # GetxController holding reactive state and UI actions
├── models/         # Data Transfer Objects (DTOs) with fromJson/toJson
├── services/       # Network calls to backend REST API via ApiClient.instance.dio
├── views/          # Top-level screen widgets (GetView<T> or StatelessWidget)
└── widgets/        # Reusable sub-components scoped specifically to this feature
```

#### Layer Responsibilities Within Features
1. **`models/`**:
   * Plain Dart classes with `fromJson` and `toJson`.
   * Null-safe field definitions matching backend JSON response structures.
   * Example: `lib/features/chantiers/models/chantier_detail.dart`.
2. **`services/`**:
   * Accesses `ApiClient.instance.dio`.
   * Formats HTTP payloads, query parameters, and paths.
   * Handles `DioException` and throws typed `ApiException`.
   * Does NOT manage UI states or show dialogs.
3. **`controllers/`**:
   * Extends `GetxController`.
   * Exposes reactive state variables (`.obs`, e.g., `Rx<ViewStatus> status = ViewStatus.initial.obs;`).
   * Calls services in async methods and mutates observable state.
   * Emits user feedback via `Get.snackbar()` when required.
4. **`views/` & `widgets/`**:
   * Extends `GetView<T>` or `StatelessWidget`.
   * Uses `Obx(() => ...)` to re-render when controller observables change.
   * Does NOT perform network calls or direct local storage writes.

---

## 3. Dependency Injection Pattern

Dependency injection is managed via GetX **Bindings**:

```dart
// Example: lib/features/articles/bindings/articles_binding.dart
class ArticlesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ArticleService>(() => ArticleService());
    Get.lazyPut<CategoryService>(() => CategoryService());
    Get.lazyPut<StockService>(() => StockService());
    Get.lazyPut<ArticlesController>(
      () => ArticlesController(
        articleService: Get.find<ArticleService>(),
        categoryService: Get.find<CategoryService>(),
        stockService: Get.find<StockService>(),
      ),
    );
  }
}
```

* Bindings are declared directly on `GetPage` entries in `lib/routes/app_pages.dart`.
* `Get.lazyPut` guarantees memory is freed when routes are popped unless marked `permanent: true`.

---

## 4. End-to-End Data Flow Sequence

Here is the verified data flow for a representative operation (fetching the Chantiers list with financial caisse data):

```text
User Action (Open Chantiers View)
  │
  ▼
GetPage(name: AppRoutes.chantiers)
  │
  ├── Middleware Check: ChantierGuardMiddleware (verifies StorageService.hasChantierModule)
  └── Binding Instantiation: ChantiersBinding (registers ChantierService & ChantiersListController)
  │
  ▼
ChantiersListView renders -> calls controller.onInit() / controller.loadChantiers()
  │
  ▼
ChantiersListController: status.value = ViewStatus.loading
  │
  ▼
ChantierService.getAll(search: ..., status: ...)
  │
  ▼
ApiClient.instance.dio.get('/chantier')
  │
  ├── AuthInterceptor attaches:
  │     Authorization: Bearer <token>
  │     X-Tenant-Slug: <tenantSlug>
  │
  ▼
ACYA C# Backend (https://acya.site/api/chantier)
  │
  ▼
JSON Response received (HTTP 200 OK)
  │
  ▼
ChantierListItem.fromJson() maps raw list into List<ChantierListItem>
  │
  ▼
ChantiersListController:
  items.assignAll(result);
  status.value = items.isEmpty ? ViewStatus.empty : ViewStatus.success;
  │
  ▼
Obx(() => ...) in ChantiersListView reacts and renders ChantierListCard widgets
```

---

## 5. Session & Storage Architecture

Local persistence is handled through `GetStorage` encapsulated in `lib/core/storage/storage_service.dart`.

### Stored Keys & Data
* **`auth_token`**: Raw JWT string issued by `Account/login`.
* **`tenant_slug`**: Active tenant identifier (e.g. `socofeb`).
* **`tenant_config`**: Serialized active `TenantConfig` JSON map.
* **`auth_fullname`**, **`auth_enterprise_name`**: User display identifiers.
* **`auth_enterprise_info`**: Cached enterprise details from `GET /enterprise/getbyid/{id}`.
* **`theme_mode`**: Stored user preference (`system`, `light`, `dark`).

### JWT Decoding
`StorageService` transparently decodes JWT payload claims to extract:
* `userId`: From `nameid`, `nameidentifier`, or `sub`.
* `userEmail`: From `email` claim.
* `defaultSiteId` / `defaultSite`: From `DefaultSiteId` claim.
* `userRole` / `isAdmin`: Checks if role corresponds to Admin (`20`) or SuperAdmin (`10`).
* `permissions`: Decodes JSON permissions object from `Permissions` claim to govern module-level read/write permissions.

---

## 6. Route Guards & Security

Navigation guards are implemented as `GetMiddleware` in `lib/routes/app_pages.dart`:

```dart
/// Redirects to /home if active user is not Admin/SuperAdmin
class AdminGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!StorageService.instance.isAdmin) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}

/// Redirects to /home if active tenant has chantier module disabled
class ChantierGuardMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!StorageService.instance.hasChantierModule) {
      return const RouteSettings(name: AppRoutes.home);
    }
    return null;
  }
}
```

Agents creating new privileged or feature-flagged routes must apply the corresponding middleware.
