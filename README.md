# AMED — Glass Factory Management System

A production-ready Flutter application (Android + iOS) for managing customer
accounts at a glass factory. The project ships **two roles in one binary**:

- **Customer App** — account statement, transactions, order tracking with
  production stages, notifications.
- **Admin App** — KPI dashboard and date-range reports.

---

## Highlights

- **Flutter** (latest stable) + **Dart 3**
- **Clean / feature-first architecture**
- **Riverpod** for state management
- **GoRouter** for navigation with role-based redirects
- **SharedPreferences** for login persistence (Remember Me)
- **Mock REST layer** (`MockXxxRepository`) ready to be swapped with `Dio`
- Full **Arabic RTL**, Apple-style modern UI (soft shadows, rounded cards)
- **Light + Dark** mode (follows system)

---

## Folder structure

```
lib/
├── main.dart
├── app.dart                       # MaterialApp.router, RTL, themes
├── core/
│   ├── error/failures.dart        # Failure / AuthFailure / NetworkFailure
│   ├── mock/mock_data.dart        # Central in-memory dataset
│   ├── router/app_router.dart     # GoRouter + auth redirect
│   ├── storage/local_storage.dart # SharedPreferences wrapper
│   ├── theme/app_theme.dart       # Apple-style light/dark themes
│   ├── utils/formatters.dart      # currency / date (Arabic)
│   └── widgets/                   # Reusable: AppCard, StatTile, EmptyState
└── features/
    ├── auth/
    │   ├── data/{models,services}
    │   ├── providers/auth_provider.dart
    │   └── presentation/{role_select_screen,login_screen}.dart
    ├── customer/
    │   ├── data/{models,repositories}
    │   ├── providers/account_provider.dart
    │   └── presentation/{customer_shell,home_screen,transactions_screen,
    │                     notifications_screen,profile_screen,widgets/}
    ├── orders/
    │   ├── data/{models,repositories}
    │   ├── providers/orders_provider.dart
    │   └── presentation/{order_details_screen,widgets/production_tracker}
    ├── transactions/
    │   ├── data/{models,repositories}
    │   └── providers/transactions_provider.dart
    ├── notifications/
    │   ├── data/{models,repositories}
    │   └── providers/notifications_provider.dart
    └── admin/
        ├── data/{models,repositories}
        ├── providers/admin_provider.dart
        └── presentation/{admin_shell,admin_dashboard_screen,reports_screen}
assets/
└── mock/sample_data.json          # Sample JSON payload
```

Each feature follows the same internal layout:

```
feature_x/
├── data/
│   ├── models/        # Plain Dart JSON models
│   ├── services/      # (optional) low-level API clients
│   └── repositories/  # Abstract repo + Mock implementation
├── providers/         # Riverpod providers (use-cases live here)
└── presentation/      # Screens + reusable widgets
```

---

## Architecture

Lightweight clean-architecture flavour:

1. **Presentation** widgets read state from **Riverpod providers** only.
2. **Providers** call **Repositories** (abstract interfaces).
3. **Repositories** are wired to `Mock*` implementations today; swap for a
   `Rest*` implementation backed by `Dio` when the API is ready — no UI
   change required.
4. Errors bubble up as typed `Failure` subclasses (`AuthFailure`, …) and
   the UI maps them to localized Arabic messages.

```
UI  →  Provider  →  Repository(abstract)  →  Mock | REST  →  Backend
```

State is exposed via `FutureProvider`, `StateProvider` and
`StateNotifierProvider` — no `setState` is used outside trivial form widgets.

---

## Authentication & demo credentials

The role picker at startup chooses which app to enter. Demo accounts:

| Role     | Username   | Password |
|----------|------------|----------|
| Customer | `customer` | `123456` |
| Admin    | `admin`    | `123456` |

"Remember me" persists the session token and user in `SharedPreferences`.
The router redirects unauthenticated users to `/role` and gates admin
routes behind `role == 'admin'`.

---

## Production stages

Order tracking visualizes every stage of glass manufacturing:

`Cutting → Coloring → Oven → Double Glass → Silicone → Sandblast → Laminated → Ready for Delivery`

Implemented in [lib/features/orders/presentation/widgets/production_tracker.dart](lib/features/orders/presentation/widgets/production_tracker.dart).

---

## Notifications

Triggered server-side and displayed in the bell tab with an unread badge:
new order, order updated, payment added, accounting entry, order ready.

---

## Admin dashboard KPIs

Current cash, today's meters, today's orders value, delivered value,
purchases today, current inventory, expenses today, revenues today, total
customer debts.

Reports support date-range filtering:
- Re-manufacturing report
- Top 5 customers by orders
- Top 5 customers by debt

---

## How to run

```bash
flutter pub get

flutter devices                  # pick a device
flutter run                      # auto-select
flutter run -d ios               # iOS simulator
flutter run -d android           # Android emulator
```

Hot reload with `r`, hot restart with `R`.

### Release builds

```bash
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android AAB
flutter build ios --release          # iOS (needs Xcode + signing)
```

---

## Swapping mock data for a real REST API

1. Implement a `Rest*Repository` next to each `Mock*Repository`, using `Dio`.
2. Update the matching provider in `features/*/providers/*.dart`:

```dart
final ordersRepositoryProvider =
    Provider<OrdersRepository>((_) => RestOrdersRepository(dio));
```

Nothing else has to change — the UI is decoupled from the data source.

---

## Localization & RTL

The app forces `Locale('ar')` and wraps the navigator in
`Directionality(textDirection: TextDirection.rtl)`. English locale is
also registered, so adding an in-app language switch later is a one-line
change.
