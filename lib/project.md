# CLAUDE.md

# WoodApp Mobile

## Project Overview

WoodApp Mobile is a Flutter application that will support multiple companies (tenants) using a single codebase.

The backend and web application already exist. The Flutter application should reuse the existing backend APIs and follow the same business logic whenever possible.

Current goal (Phase 1):

- Tenant selection
- Authentication
- Article listing
- Search
- Filtering

Everything else will come later.

---

# IMPORTANT

## Read Only

The existing backend is the source of truth.

Claude MUST NEVER modify anything on the server.

Only inspect files and understand how the backend works.

Do NOT change:

- Backend code
- Database
- API
- Web application

Read only.

---

# Existing Project

The backend and web application are already deployed on our Ubuntu server.

When connected through SSH, inspect the existing implementation to understand how everything works.

Useful locations:

Authentication

wood-app.api/src/ms.webapp.api.acya/ms.webapp.api.acya/Controllers/Authentication/AccountController.cs

Articles

wood-app.api/src/ms.webapp.api.acya/ms.webapp.api.acya/Controllers/ArticleController.cs

Tenant implementation example (Web App)

elance-app.ui/src/components/TenantProvider.tsx

The TenantProvider is especially important because the Flutter app must implement the same tenant concept.

---

# Multi Tenant Architecture

This application is multi-tenant.

Every company has:

- its own tenant
- logo
- colors
- branding
- authentication
- data

The mobile application must adapt automatically depending on the selected tenant.

Flow:

App Launch

↓

Tenant Selection

↓

Download tenant configuration

↓

Apply branding

- logo
- colors
- app name
- theme

↓

Authenticate

↓

Load company data

↓

Home

---

# Flutter Flavors

Use Flutter Flavors.

Example:

development

preprod

production

Each flavor can point to different environments.

Inside every environment we can still choose the tenant.

Example

Production

├── Company A

├── Company B

├── Company C

Development

├── Company A

├── Company B

---

# Tenant

The first screen should ask the user which company they want to connect to.

Once selected:

Store tenant information locally.

Then:

- configure API base url if needed
- configure branding
- configure colors
- configure logo

The login screen must already display the tenant branding.

---

# Branding

Each tenant can have:

Logo

Primary Color

Secondary Color

App Name

Theme

Branding should be loaded dynamically.

Avoid hardcoded values.

---

# Authentication

Authentication must use the existing backend.

Study:

AccountController.cs

Understand:

- Login endpoint
- Request body
- Response
- JWT
- Refresh token
- User information

Reuse the existing API.

Do not create a new authentication flow.

---

# Articles

Current mobile feature:

Articles

Use:

ArticleController.cs

Implement:

- Pagination
- Search
- Filters
- Pull to refresh
- Infinite scrolling if supported

Reuse backend filtering whenever available.

Do not filter locally if the backend already supports it.

---

# Flutter Architecture

Keep architecture simple.

Recommended structure:

lib/

core/

config/

constants/

theme/

network/

storage/

models/

services/

modules/

authentication/

tenant/

articles/

widgets/

routes/

main.dart

---

# State Management

Use GetX.

Use:

GetMaterialApp

GetX Controllers

Bindings

Dependency Injection

Reactive variables

Avoid unnecessary complexity.

No Bloc.

No Riverpod.

---

# Networking

Use Dio.

Create:

ApiClient

AuthenticationInterceptor

LoggingInterceptor

ErrorInterceptor

JWT should be automatically attached.

Handle:

401

403

500

Network timeout

Offline

---

# Local Storage

Use:

GetStorage

or

Hive

Store:

JWT

Refresh Token

Tenant

Theme

User

---

# Models

Generate models from backend JSON.

Prefer:

json_serializable

or

freezed

Keep models clean.

---

# Folder Structure

lib/

core/

network/

storage/

theme/

config/

modules/

tenant/

authentication/

articles/

shared/

widgets/

---

# UI

Material 3

Responsive

Modern

Minimal

Fast

Reusable widgets.

---

# Theme

Each tenant has different branding.

ThemeData should be generated dynamically.

Example:

TenantTheme

↓

ThemeData

↓

Entire application updates automatically.

---

# Navigation

Use GetX Navigation.

Example:

Splash

↓

Tenant

↓

Login

↓

Home

↓

Articles

---

# Error Handling

Every API call should return:

Loading

Success

Error

Empty

Show friendly error messages.

---

# Logging

Use logger package.

Only detailed logs in debug mode.

---

# Coding Rules

Follow clean code.

Small widgets.

Small controllers.

Avoid duplicated code.

Prefer composition.

---

# Things To Inspect

Authentication flow

Tenant Provider implementation

Article endpoints

Search implementation

Filtering implementation

Pagination

DTOs

Authentication middleware

JWT validation

Branding implementation

Theme loading

---

# Important Constraints

Do NOT modify server code.

Do NOT modify backend.

Do NOT modify database.

Do NOT change APIs.

Only consume existing APIs.

---

# Development Strategy

Phase 1

✅ Tenant Selection

✅ Login

✅ Articles

✅ Search

✅ Filters

Phase 2

Remaining application features.

---

# If Something Is Missing

Before implementing a feature, ask questions whenever:

- an endpoint is unclear
- request/response is missing
- tenant configuration is unknown
- branding source is unknown
- authentication behavior is unclear

Never guess business logic.

Always inspect the backend first.
And I would organize it like this:

lib/
│
├── core/
│   ├── api/
│   ├── config/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── tenant/
│   ├── auth/
│   ├── articles/
│   └── home/
│
├── routes/
│
├── bindings/
│
└── main.dart