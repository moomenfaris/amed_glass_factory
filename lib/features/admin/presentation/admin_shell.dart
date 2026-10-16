import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/location_update_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/admin_widgets.dart';

class _AdminTab {
  final String route;
  final String label;
  final IconData icon;
  const _AdminTab(this.route, this.label, this.icon);
}

const List<_AdminTab> _adminTabs = [
  _AdminTab('/admin', 'الرئيسية', Icons.home_rounded),
  _AdminTab('/admin/orders-period', 'الطلبات', Icons.shopping_bag_rounded),
  _AdminTab('/admin/expenses', 'المصروفات', Icons.receipt_long_rounded),
  _AdminTab('/admin/customer-debts', 'الديون', Icons.people_alt_rounded),
];

/// Remaining destinations surfaced through the "المزيد" sheet.
const List<_AdminTab> _moreTabs = [
  _AdminTab(
    '/admin/supplier-payments',
    'تسديدات المجهزين',
    Icons.local_shipping_outlined,
  ),
  _AdminTab(
    '/admin/customer-receipts',
    'مقبوضات الزبائن',
    Icons.receipt_long_outlined,
  ),
  _AdminTab(
    '/admin/personal-withdrawals',
    'مسحوبات الشركات',
    Icons.person_remove_alt_1_outlined,
  ),
  _AdminTab(
    '/admin/production-details',
    'تفاصيل الانتاج',
    Icons.precision_manufacturing_outlined,
  ),
];

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
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

  int _currentIndex(String location) {
    for (var i = 0; i < _adminTabs.length; i++) {
      if (location == _adminTabs[i].route) return i;
    }
    return -1;
  }

  void _showMoreSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AdminPalette.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'المزيد',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            for (final tab in _moreTabs)
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminPalette.blueSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(tab.icon, color: AdminPalette.blue, size: 20),
                ),
                title: Text(
                  tab.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.push(tab.route);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
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

    final location = GoRouterState.of(context).uri.path;
    final index = _currentIndex(location);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: widget.child,
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: index,
        onSelected: (i) {
          if (i == _adminTabs.length) {
            _showMoreSheet();
            return;
          }
          final route = _adminTabs[i].route;
          if (location != route) context.go(route);
        },
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _AdminBottomNav({required this.currentIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.appBarBlue,
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _adminTabs.length; i++)
                _item(i, _adminTabs[i].icon, _adminTabs[i].label),
              _item(_adminTabs.length, Icons.grid_view_rounded, 'المزيد'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final selected = index == currentIndex;
    final color = selected ? Colors.white : const Color(0xB3FFFFFF);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
