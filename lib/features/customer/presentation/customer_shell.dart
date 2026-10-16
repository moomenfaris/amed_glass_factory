import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/location_update_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class CustomerShell extends ConsumerStatefulWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  ConsumerState<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends ConsumerState<CustomerShell> {
  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, 'الرئيسية'),
    (
      '/transactions',
      Icons.receipt_long_outlined,
      Icons.receipt_long,
      'الحركات',
    ),
    (
      '/completed-movements',
      Icons.task_alt_outlined,
      Icons.task_alt,
      'المكتملة',
    ),
    ('/profile', Icons.person_outline, Icons.person, 'حسابي'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authStateProvider).user?.id;
    ref.read(locationUpdateProvider.notifier).run(userId);
  }

  void _showLocationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خدمة الموقع معطلة'),
        content: const Text(
          'يجب تفعيل خدمة الموقع حتى يتمكن التطبيق من تسجيل بياناتك بشكل صحيح.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('تفعيل الموقع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LocationUpdateStatus>(locationUpdateProvider, (prev, next) {
      if (next == LocationUpdateStatus.locationDisabled) {
        _showLocationDialog();
      }
    });

    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _indexFor(loc);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A192F),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) =>
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (var i = 0; i < _tabs.length; i++)
            NavigationDestination(
              icon: Icon(_tabs[i].$2, color: Colors.white),
              selectedIcon: Icon(_tabs[i].$3, color: Colors.white),
              label: _tabs[i].$4,
            ),
        ],
      ),
    );
  }
}
