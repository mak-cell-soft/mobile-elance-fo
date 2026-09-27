# API Integration Guide — WoodApp Mobile

> **Parent:** [AGENTS.md](../AGENTS.md)  
> **Backend Source:** ACYA C# .NET REST API (`https://acya.site/api/`)  
> **Status:** Active & Verified from Codebase

---

## 1. Network Core & Headers

All network operations route through `ApiClient` (`lib/core/network/api_client.dart`), which configures a shared `Dio` instance.

### Mandatory Request Headers
Every outgoing HTTP request (except public login and tenant config resolution) includes:

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <jwt_token>
X-Tenant-Slug: <tenant_slug>
```

> [!IMPORTANT]
> The ACYA backend cross-validates the `X-Tenant-Slug` header against the `tenant_slug` claim inside the JWT. Both headers must always travel together. This is enforced by `AuthInterceptor` (`lib/core/network/interceptors/auth_interceptor.dart`).

---

## 2. Authentication & Session

### Login
* **Service:** `AuthService.login` (`lib/features/auth/services/auth_service.dart`)
* **Endpoint:** `POST account/login`
* **Auth Required:** No
* **Request Payload:**
  ```json
  {
    "login": "string",
    "password": "string"
  }
  ```
* **Response:** Returns `AuthResponse` containing `token` (JWT string), `fullName`, `enterpriseName`, `role`, and expiration data.
* **Storage:** On success, `StorageService.instance.saveSession()` caches the JWT and user metadata in `GetStorage`.

### Automatic 401 Session Expiry
* **Interceptor:** `ErrorInterceptor` (`lib/core/network/interceptors/error_interceptor.dart`)
* **Behavior:** When any endpoint returns HTTP 401 Unauthorized:
  1. Clears local session cache (`StorageService.clearSession()`).
  2. Redirects user to `AppRoutes.login`.
  3. Displays a persistent snackbar: *"Session expirée. Veuillez vous reconnecter."*

---

## 3. Verified Endpoints Catalog

### Tenant & Enterprise

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `enterprise/config` | `GET` | `TenantService.fetchConfig` | Fetches tenant branding DTO (company name, colors, logo URL). Header `X-Tenant-Slug` specifies target tenant. |
| `enterprise/getbyid/{id}` | `GET` | `EnterpriseService.fetchEnterprise` | Retrieves enterprise details including `isManagingConstructions` feature flag. |

---

### Articles, Categories & Stock

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `article` | `GET` | `ArticleService.fetchAll` | Fetches the full active article catalog. Client-side search and filtering are applied in `ArticlesController`. |
| `Category` | `GET` | `CategoryService.fetchAll` | Retrieves categories and nested subcategories (`firstchildren`). |
| `Stock` | `GET` | `StockService.fetchAll` | Retrieves current stock balances per article across all storage sites. |

---

### Construction Sites (Chantiers)

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `chantier` | `GET` | `ChantierService.getAll` | Lists chantiers. Query params: `search` (text), `status` (int), `healthFlag` (int). |
| `chantier/{id}` | `GET` | `ChantierService.getById` | Full details for a single construction site. |
| `chantier/{id}/caisse` | `GET` | `ChantierService.getCaisseSummary` | Financial summary of the site's cash desk (balance, total in, total out, pending count). |
| `chantier/{id}/caisse/transactions` | `GET` | `ChantierService.getCaisseTransactions` | Ledger of cash operations. Query params: `type` (int), `status` (int). |
| `chantier/{id}/caisse/alimentation` | `POST` | `ChantierService.addCaisseAlimentation` | Adds cash replenishment (Alimentation). Restricted to Admin. Body: `{ amount, transactionDate, reason, reference, notes }`. |
| `chantier/{id}/caisse/sortie` | `POST` | `ChantierService.addCaisseSortie` | Records expense/disbursement. Body: `{ amount, transactionDate, reason, beneficiaryPersonId, reference, notes, isMobileRequest }`. |
| `chantier/{id}/caisse/transactions/{txId}/validate` | `POST` | `ChantierService.validateCaisseRequest` | Admin validation or rejection. Body: `{ approve: bool }`. |
| `chantier/{id}/progress-entries` | `GET` | `ChantierService.getProgressEntries` | Timeline milestones and physical progress entries. |
| `chantier/{id}/alerts` | `GET` | `ChantierService.getAlerts` | Operational alerts for the site's Suivi tab. |

---

### Purchases (Achats & Réceptions)

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `Document/_typefiltered` | `POST` | `ReceiptService.fetchReceiptsFiltered` | Fetches Bon de Réception (BR) documents. Body: `{ typeDoc: 2, month: int, year: int, day: int }`. (typeDoc 2 = supplierReceipt). |
| `Counterpart/getall/Supplier` | `GET` | `ReceiptService.fetchSuppliers` | Fetches counterpart suppliers for client-side drop-down filtering. |

---

### Customers

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `CounterPart/GetAll/Customer` | `GET` | `CustomerService.fetchAll` | Fetches customer counterpart directory. Filters out records where `isDeleted == true`. |

---

### Dashboard Analytics & Treasury

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `Analytics/dashboard` | `GET` | `AnalyticsService.fetchDashboardKpis` | Retrieves aggregated KPIs: total sales TTC, receivables, stock alerts. Query params: `month`, `year`. |
| `Document/_type?_type=3` | `GET` | `AnalyticsService.fetchMonthlyPurchaseTtc` | Supplier invoices used to calculate net purchase amounts. |
| `Document/_type?_type=7` | `GET` | `AnalyticsService.fetchMonthlyPurchaseTtc` | Supplier return credit notes subtracted from purchases. |
| `Payments/search` | `POST` | `AnalyticsService.fetchSupplierPurchasePaymentChart` | Paginated search of counterpart payments to calculate supplier disbursement chart points. |
| `Analytics/top-subcategories` | `GET` | `AnalyticsService.fetchTopSubCategories` | Top-selling subcategories and top articles over the trailing `months` parameter (default: 6). |
| `Caisse/principale/balance` | `GET` | `TreasuryService.fetchCaissePrincipaleBalance` | Balance of the Central Vault (`Caisse Principale`). |
| `Caisse/all` | `GET` | `TreasuryService.fetchAllCaisseBalances` | Cash balances broken down per point of sale / site (`Caisse par Point de Vente`). |

---

### Notifications & Stock Alerts

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `notifications/unreads` | `GET` | `NotificationService.fetchUnreads` | Lists unread notifications for the active user. |
| `notifications/{id}/read` | `PUT` | `NotificationService.markAsRead` | Marks notification as read. |
| `notifications/{id}` | `DELETE` | `NotificationService.dismissNotification`| Dismisses or deletes notification. |
| `stock/notifications/missed` | `GET` | `NotificationService.getMissedNotifications`| Retrieves pending inter-site transfer notifications. Query param: `userId`. |
| `notifications/retry-failed` | `POST` | `NotificationService.retryFailedNotifications` | Initiates background retry of failed notification deliveries. |
| `stock/alerts` | `GET` | `NotificationService.fetchStockAlerts` | Retrieves stock items that have fallen below safety thresholds. Query param: `siteId`. |

---

### User Profile

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `Account/profile/{id}` | `GET` | `ProfileService.fetchProfile` | Retrieves full profile record for user ID. |
| `Account/update-profile` | `PUT` | `ProfileService.updateProfile` | Updates profile. Body: `{ email, login, firstName, lastName, phoneNumber, address }`. |

---

### System Settings & AppVariables

| Endpoint | Method | Service | Purpose |
| :--- | :--- | :--- | :--- |
| `AppVariable/getall/{nature}` | `GET` | `SettingsService.fetchVariables` | Fetches configuration variables by category/nature. |
| `AppVariable/daily-ceiling` | `POST` | `SettingsService.upsertDailyCeiling` | Sets or updates maximum daily invoice ceiling. Body: `{ name, value, nature: 'DailyInvoiceCeiling', isactive: true }`. |
| `AppVariable/Add` | `POST` | `SettingsService.addVariable` | Adds generic application variable. |
| `AppVariable/{id}` | `PUT` | `SettingsService.updateVariable` | Updates existing application variable. |
| `AppVariable/{id}` | `DELETE` | `SettingsService.deleteVariable` | Deletes application variable. |

---

## 4. Error Handling Model

Network errors are mapped through `ApiException` (`lib/core/network/api_exception.dart`):

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException({required this.message, this.statusCode, this.details});

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Délai d\'attente dépassé. Vérifiez votre connexion.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        // Extracts backend message or falls back to standard HTTP status text
        return ApiException(
          message: data?['message']?.toString() ?? 'Erreur serveur ($status)',
          statusCode: status,
          details: data,
        );
      case DioExceptionType.connectionError:
        return ApiException(message: 'Impossible de joindre le serveur. Vérifiez votre réseau.');
      default:
        return ApiException(message: 'Une erreur imprévue est survenue.');
    }
  }
}
```
