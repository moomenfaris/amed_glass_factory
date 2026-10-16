import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EmployeeShell extends ConsumerWidget {
  final Widget child;
  const EmployeeShell({super.key, required this.child});

  static const _tabs = [
    (
      '/employee/completed-movements',
      Icons.task_alt_outlined,
      Icons.task_alt,
      'مراحل الانتاج',
    ),
    ('/employee/customers', Icons.group_outlined, Icons.group, 'قائمة العملاء'),
    (
      '/employee/warehouse',
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      'المخزن',
    ),
    ('/employee/profile', Icons.person_outline, Icons.person, 'حسابي'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A192F),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.$2, color: Colors.white),
              selectedIcon: Icon(t.$3, color: Colors.white),
              label: t.$4,
            ),
        ],
      ),
    );
  }
}
