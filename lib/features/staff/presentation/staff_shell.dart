import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StaffShell extends ConsumerWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  static const _tabs = [
    ('/staff/home', Icons.home_outlined, Icons.home, 'الرئيسية'),
    ('/staff/profile', Icons.person_outline, Icons.person, 'الملف الشخصي'),
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
        backgroundColor: const Color(0xFF111F31),
        indicatorColor: const Color(0x29FFFFFF),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : const Color(0xB3FFFFFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2, color: const Color(0xB3FFFFFF)),
              selectedIcon: Icon(tab.$3, color: Colors.white),
              label: tab.$4,
            ),
        ],
      ),
    );
  }
}
