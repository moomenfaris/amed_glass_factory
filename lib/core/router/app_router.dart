import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/cash_accounts_screen.dart';
import '../../features/admin/presentation/customer_debts_screen.dart';
import '../../features/admin/presentation/expenses_screen.dart';
import '../../features/admin/presentation/period_report_screen.dart';
import '../../features/admin/data/models/admin_reporting.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/customer/presentation/customer_shell.dart';
import '../../features/customer/presentation/completed_movements_screen.dart';
import '../../features/customer/presentation/home_screen.dart';
import '../../features/customer/presentation/transactions_screen.dart';
import '../../features/customer/presentation/profile_screen.dart';
import '../../features/employee/presentation/employee_customer_home_screen.dart';
import '../../features/employee/presentation/employee_customer_transactions_screen.dart';
import '../../features/employee/presentation/employee_customers_screen.dart';
import '../../features/employee/presentation/employee_shell.dart';
import '../../features/employee/presentation/employee_warehouse_screen.dart';
import '../../features/staff/presentation/staff_home_screen.dart';
import '../../features/staff/presentation/staff_plus_hours_screen.dart';
import '../../features/staff/presentation/staff_placeholder_screen.dart';
import '../../features/staff/presentation/staff_shell.dart';
import '../../features/images/presentation/movement_images_screen.dart';
import '../../features/invoices/presentation/invoice_screen.dart';
import '../../features/orders/presentation/order_details_screen.dart';
import '../../features/orders/presentation/movement_details_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final loggedIn = auth.isLoggedIn;
      final role = auth.role;

      // Hold every route on the splash until CheckUserState resolves.
      if (auth.bootstrapping) return loc == '/splash' ? null : '/splash';

      if (loc == '/splash') return null;

      if (loc == '/login') {
        if (loggedIn) {
          if (role == 'admin') return '/admin';
          if (role == 'employee') return '/employee/completed-movements';
          if (role == 'staff') return '/staff/home';
          return '/home';
        }
        return null;
      }
      if (!loggedIn) return '/login';
      // role-based gating
      final adminAllowed =
          loc.startsWith('/admin') ||
          loc.startsWith('/invoices/') ||
          loc.startsWith('/movement-images/');
      if (role == 'admin' && !adminAllowed) return '/admin';
      final employeeAllowed =
          loc.startsWith('/employee') ||
          loc.startsWith('/movements/') ||
          loc.startsWith('/invoices/') ||
          loc.startsWith('/movement-images/');
      if (role == 'employee' && !employeeAllowed) {
        return '/employee/completed-movements';
      }
      if (role == 'staff' && !loc.startsWith('/staff')) return '/staff/home';
      if (role == 'customer' && loc.startsWith('/admin')) return '/home';
      if (role == 'customer' && loc.startsWith('/employee')) return '/home';
      if (role == 'customer' && loc.startsWith('/staff')) return '/home';
      if (role == 'admin' && loc.startsWith('/staff')) return '/admin';
      if (role == 'employee' && loc.startsWith('/staff')) {
        return '/employee/completed-movements';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),

      // Customer shell with bottom nav
      ShellRoute(
        builder: (c, s, child) => CustomerShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
          GoRoute(
            path: '/transactions',
            builder: (c, s) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/completed-movements',
            builder: (c, s) => const CompletedMovementsScreen(),
          ),
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ],
      ),

      // Employee shell (2 pages only)
      ShellRoute(
        builder: (c, s, child) => EmployeeShell(child: child),
        routes: [
          GoRoute(
            path: '/employee/completed-movements',
            builder: (c, s) => const CompletedMovementsScreen(),
          ),
          GoRoute(
            path: '/employee/customers',
            builder: (c, s) => const EmployeeCustomersScreen(),
          ),
          GoRoute(
            path: '/employee/customers/:codeCom',
            builder: (c, s) {
              final code = int.tryParse(s.pathParameters['codeCom'] ?? '') ?? 0;
              final name = s.uri.queryParameters['name'];
              return EmployeeCustomerHomeScreen(
                codeCom: code,
                customerName: name,
                transactionsRouteBase: '/employee/customers',
              );
            },
          ),
          GoRoute(
            path: '/employee/customers/:codeCom/transactions',
            builder: (c, s) {
              final code = int.tryParse(s.pathParameters['codeCom'] ?? '') ?? 0;
              final name = s.uri.queryParameters['name'];
              return EmployeeCustomerTransactionsScreen(
                codeCom: code,
                customerName: name,
              );
            },
          ),
          GoRoute(
            path: '/employee/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/employee/warehouse',
            builder: (c, s) => const EmployeeWarehouseScreen(),
          ),
        ],
      ),

      // Staff shell
      ShellRoute(
        builder: (c, s, child) => StaffShell(child: child),
        routes: [
          GoRoute(
            path: '/staff/home',
            builder: (c, s) => const StaffHomeScreen(),
          ),
          GoRoute(
            path: '/staff/plus-hours',
            builder: (c, s) {
              final id = int.tryParse(s.uri.queryParameters['id'] ?? '') ?? 0;
              final atRaw = s.uri.queryParameters['at'];
              final at = DateTime.tryParse(atRaw ?? '') ?? DateTime.now();
              return StaffPlusHoursScreen(employeeId: id, at: at);
            },
          ),
          GoRoute(
            path: '/staff/employees',
            builder: (c, s) => const StaffPlaceholderScreen(
              title: 'الموظفون',
              subtitle: 'قائمة الموظفين ستظهر هنا.',
              icon: Icons.group_outlined,
            ),
          ),
          GoRoute(
            path: '/staff/profile',
            builder: (c, s) => const StaffPlaceholderScreen(
              title: 'ملفي',
              subtitle: 'معلومات الحساب الشخصي ستظهر هنا.',
              icon: Icons.person_outline,
            ),
          ),
          GoRoute(
            path: '/staff/more',
            builder: (c, s) => const StaffPlaceholderScreen(
              title: 'المزيد',
              subtitle: 'إعدادات إضافية وخيارات متقدمة.',
              icon: Icons.more_horiz,
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/orders/:id',
        builder: (_, s) => OrderDetailsScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/movements/:id',
        builder: (_, s) =>
            MovementDetailsScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/invoices/:id',
        builder: (_, s) =>
            InvoiceScreen(invoiceId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/movement-images/:id',
        builder: (_, s) =>
            MovementImagesScreen(invoiceId: int.parse(s.pathParameters['id']!)),
      ),

      // Admin shell
      ShellRoute(
        builder: (c, s, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (c, s) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (c, s) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/admin/customer-debts',
            builder: (c, s) => const CustomerDebtsScreen(),
          ),
          GoRoute(
            path: '/admin/customer-debts/:codeCom',
            builder: (c, s) {
              final code = int.tryParse(s.pathParameters['codeCom'] ?? '') ?? 0;
              final name = s.uri.queryParameters['name'];
              return EmployeeCustomerHomeScreen(
                codeCom: code,
                customerName: name,
                transactionsRouteBase: '/admin/customer-debts',
              );
            },
          ),
          GoRoute(
            path: '/admin/customer-debts/:codeCom/transactions',
            builder: (c, s) {
              final code = int.tryParse(s.pathParameters['codeCom'] ?? '') ?? 0;
              final name = s.uri.queryParameters['name'];
              return EmployeeCustomerTransactionsScreen(
                codeCom: code,
                customerName: name,
              );
            },
          ),
          GoRoute(
            path: '/admin/cash',
            builder: (c, s) => const CashAccountsScreen(),
          ),
          GoRoute(
            path: '/admin/expenses',
            builder: (c, s) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/admin/orders-period',
            builder: (c, s) => const PeriodReportScreen(
              title: 'الطلبيات خلال فترة',
              type: AdminPeriodReportType.orders,
              totalLabel: 'مجموع الطلبيات',
            ),
          ),
          GoRoute(
            path: '/admin/personal-withdrawals',
            builder: (c, s) => const PeriodReportScreen(
              title: 'مسحوبات الشركات',
              type: AdminPeriodReportType.personalWithdrawals,
              totalLabel: 'مجموع المسحوبات',
            ),
          ),
          GoRoute(
            path: '/admin/customer-receipts',
            builder: (c, s) => const PeriodReportScreen(
              title: 'مقبوضات الزبائن',
              type: AdminPeriodReportType.customerReceipts,
              totalLabel: 'مجموع المقبوضات',
            ),
          ),
          GoRoute(
            path: '/admin/supplier-payments',
            builder: (c, s) => const PeriodReportScreen(
              title: 'تسديدات المجهزين',
              type: AdminPeriodReportType.supplierPayments,
              totalLabel: 'مجموع التسديدات',
            ),
          ),
          GoRoute(
            path: '/admin/production-details',
            builder: (c, s) => const PeriodReportScreen(
              title: 'تفاصيل الانتاج',
              type: AdminPeriodReportType.productionDetails,
              totalLabel: 'مجموع الانتاج',
              amountSuffix: 'م²',
            ),
          ),
        ],
      ),
    ],
  );
});

/// Bridge Riverpod auth state -> GoRouter refresh.
class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (c, s) => notifyListeners());
  }
}
