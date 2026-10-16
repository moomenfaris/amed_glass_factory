import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/providers/auth_provider.dart';

class EmployeeDrawer extends ConsumerWidget {
  const EmployeeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final loc = GoRouterState.of(context).matchedLocation;
    final colors = Theme.of(context).colorScheme;

    Widget navTile({
      required String route,
      required String title,
      required IconData icon,
    }) {
      final selected = loc.startsWith(route);
      return ListTile(
        selected: selected,
        selectedTileColor: colors.primaryContainer,
        leading: Icon(
          icon,
          color: selected ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? colors.primary : colors.onSurface,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (!selected) context.go(route);
        },
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'حساب الموظف',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.fullName ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  navTile(
                    route: '/employee/completed-movements',
                    title: 'مراحل الانتاج',
                    icon: Icons.task_alt_outlined,
                  ),
                  navTile(
                    route: '/employee/customers',
                    title: 'قائمة العملاء',
                    icon: Icons.group_outlined,
                  ),
                  navTile(
                    route: '/employee/warehouse',
                    title: 'المخزن',
                    icon: Icons.inventory_2_outlined,
                  ),
                  navTile(
                    route: '/employee/profile',
                    title: 'حسابي',
                    icon: Icons.person_outline,
                  ),
                ],
              ),
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
}
