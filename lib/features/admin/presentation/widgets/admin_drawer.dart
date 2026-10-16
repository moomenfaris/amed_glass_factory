import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/font_scale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/widgets/font_scale_sheet.dart';
import '../../../../core/widgets/theme_mode_sheet.dart';
import '../../../auth/providers/auth_provider.dart';

class AdminMenuItem {
  final String route;
  final String title;
  final IconData icon;

  const AdminMenuItem({
    required this.route,
    required this.title,
    required this.icon,
  });
}

const List<AdminMenuItem> adminMenuItems = [
  AdminMenuItem(
    route: '/admin',
    title: 'الرئيسية',
    icon: Icons.dashboard_outlined,
  ),
  AdminMenuItem(
    route: '/admin/customer-debts',
    title: 'الديون',
    icon: Icons.account_tree_outlined,
  ),
  AdminMenuItem(
    route: '/admin/cash',
    title: 'النقد',
    icon: Icons.payments_outlined,
  ),
  AdminMenuItem(
    route: '/admin/expenses',
    title: 'المصروفات',
    icon: Icons.receipt_long_outlined,
  ),
  AdminMenuItem(
    route: '/admin/orders-period',
    title: 'الطلبيات خلال فترة',
    icon: Icons.shopping_bag_outlined,
  ),
  AdminMenuItem(
    route: '/admin/personal-withdrawals',
    title: 'مسحوبات الشركات',
    icon: Icons.person_remove_alt_1_outlined,
  ),
  AdminMenuItem(
    route: '/admin/customer-receipts',
    title: 'مقبوضات الزبائن',
    icon: Icons.receipt_long_outlined,
  ),
  AdminMenuItem(
    route: '/admin/supplier-payments',
    title: 'تسديدات المجهزين',
    icon: Icons.local_shipping_outlined,
  ),
  AdminMenuItem(
    route: '/admin/production-details',
    title: 'تفاصيل الانتاج',
    icon: Icons.precision_manufacturing_outlined,
  ),
  AdminMenuItem(
    route: '/admin/profile',
    title: 'حسابي',
    icon: Icons.person_outline,
  ),
];

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final fontScale = ref.watch(appFontScaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'قائمة الإدارة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: adminMenuItems.length,
                itemBuilder: (context, i) {
                  final item = adminMenuItems[i];
                  final selected = _matchesRoute(loc, item.route);

                  return ListTile(
                    selected: selected,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    leading: Icon(
                      item.icon,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      if (!selected) context.go(item.route);
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.dark_mode_outlined,
                color: Color(0xFF1D4ED8),
              ),
              title: Text(
                'مظهر التطبيق',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              trailing: Text(
                themeMode == ThemeMode.dark ? 'داكن' : 'فاتح',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await showThemeModeSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_size, color: Color(0xFF1D4ED8)),
              title: Text(
                'حجم الخط',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              trailing: Text(
                '${(fontScale * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await showFontScaleSheet(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFB42318)),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB42318),
                ),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authStateProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  static bool _matchesRoute(String current, String itemRoute) {
    if (itemRoute == '/admin') {
      return current == '/admin';
    }
    if (current == itemRoute) return true;
    return current.startsWith('$itemRoute/');
  }
}
