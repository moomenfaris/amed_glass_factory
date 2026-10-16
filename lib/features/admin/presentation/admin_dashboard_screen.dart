import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/services/home_entry_metadata_service.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/admin_metrics.dart';
import '../providers/admin_provider.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final HomeEntryMetadataService _homeEntryMetadataService =
      HomeEntryMetadataService();
  int? _lastSentForUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendAdminMetadataOnHomeEnter();
    });
  }

  Future<void> _sendAdminMetadataOnHomeEnter() async {
    final auth = ref.read(authStateProvider);
    final user = auth.user;
    if (user == null || user.role != 'admin') return;

    final userId = user.userId ?? int.tryParse(user.id);
    if (userId == null || userId <= 0 || _lastSentForUserId == userId) return;

    try {
      final payload = await _homeEntryMetadataService.sendForUserOnHomeEnter(
        user: user,
        authToken: auth.token,
      );
      if (payload == null) return;

      _lastSentForUserId = userId;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إرسال معلومات الأدمن: ${userErrorMessage(e)}'),
        ),
      );
    }
  }

  DateTime _from(DateTime selectedDate, AdminPeriod period) {
    final now = selectedDate;
    return switch (period) {
      AdminPeriod.today => DateTime(now.year, now.month, now.day),
      AdminPeriod.month => DateTime(now.year, now.month, 1),
      AdminPeriod.year => DateTime(now.year, 1, 1),
    };
  }

  DateTime _to(DateTime selectedDate) {
    final now = selectedDate;
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickSelectedDate() async {
    final selectedDate = ref.read(adminSelectedDateProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null) return;
    ref.read(adminSelectedDateProvider.notifier).state = DateTime(
      picked.year,
      picked.month,
      picked.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(adminSelectedDateProvider);
    final period = ref.watch(adminPeriodProvider);
    final query = AdminMetricsQuery(
      from: _from(selectedDate, period),
      to: _to(selectedDate),
    );
    final metricsAsync = ref.watch(adminMetricsProvider(query));
    final fullName = ref.watch(authStateProvider).user?.fullName ?? 'الإدارة';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const AppBarTitle('الرئيسية'),
        actions: [
          IconButton(
            onPressed: _pickSelectedDate,
            tooltip: Formatters.longDate(selectedDate),
            icon: const Icon(Icons.calendar_today_rounded),
          ),
        ],
      ),
      body: metricsAsync.when(
        data: (m) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminMetricsProvider(query)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(fullName: fullName),
              const SizedBox(height: 12),
              _SelectedDateBanner(
                selectedDate: selectedDate,
                onTap: _pickSelectedDate,
              ),
              const SizedBox(height: 14),
              AdminPeriodChips(
                value: period,
                onChanged: (p) =>
                    ref.read(adminPeriodProvider.notifier).setPeriod(p),
              ),
              const SizedBox(height: 16),
              _MetricsGrid(metrics: m),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String fullName;
  const _Header({required this.fullName});

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صباح الخير',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectedDateBanner extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const _SelectedDateBanner({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFFEAF1FF), Color(0xFFDCE8FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: AdminPalette.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AdminPalette.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التاريخ المحدد',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.longDate(selectedDate),
                      style: TextStyle(
                        color: AdminPalette.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_calendar_rounded, color: AdminPalette.blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final AdminMetrics metrics;
  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = <_MetricData>[
      _MetricData(
        label: 'الطلبات',
        value: Formatters.currency(metrics.todayOrdersValue),
        secondaryValue: '${metrics.todayMeters.toStringAsFixed(1)} م²',
        icon: Icons.shopping_bag_outlined,
        color: AdminPalette.blue,
        route: '/admin/orders-period',
      ),
      _MetricData(
        label: 'المصروفات',
        value: Formatters.currency(metrics.expensesToday),
        icon: Icons.account_balance_wallet_outlined,
        color: AdminPalette.orange,
        route: '/admin/expenses',
      ),
      _MetricData(
        label: 'المقبوضات',
        value: Formatters.currency(metrics.revenuesToday),
        icon: Icons.south_west_rounded,
        color: AdminPalette.green,
        route: '/admin/customer-receipts',
      ),
      _MetricData(
        label: 'التسديدات',
        value: Formatters.currency(metrics.deliveredOrdersValue),
        icon: Icons.receipt_long_rounded,
        color: AdminPalette.orange,
        route: '/admin/supplier-payments',
      ),
      _MetricData(
        label: 'تفاصيل الانتاج',
        value:
            'Double: ${metrics.productionDetailsDouble.toStringAsFixed(1)} م²',
        secondaryValue:
            'Single: ${metrics.productionDetailsSingle.toStringAsFixed(1)} م²',
        icon: Icons.precision_manufacturing_outlined,
        color: AdminPalette.blue,
        route: '/admin/production-details',
      ),
      _MetricData(
        label: 'الديون',
        value: Formatters.currency(metrics.customerDebtsTotal),
        secondaryValue:
            'المنفذة: ${Formatters.currency(metrics.customerDebtsExecuted)}',
        icon: Icons.people_alt_outlined,
        color: AdminPalette.red,
        route: '/admin/customer-debts',
      ),
      _MetricData(
        label: 'النقد',
        value: '${Formatters.currency(metrics.currentCashDollar)} دولار',
        secondaryValue:
            'دينار: ${Formatters.numberGrouped(metrics.currentCashDinar)}',
        icon: Icons.payments_outlined,
        color: AdminPalette.green,
        secondaryColor: AdminPalette.blue,
        equalValueAndSecondaryFont: true,
        route: '/admin/cash',
      ),
      _MetricData(
        label: 'مسحوبات الشركاء',
        value: Formatters.currency(metrics.purchasesToday),
        icon: Icons.group_remove_outlined,
        color: AdminPalette.purple,
        route: '/admin/personal-withdrawals',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.32,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return AdminMetricCard(
          label: item.label,
          value: item.value,
          secondaryValue: item.secondaryValue,
          icon: item.icon,
          color: item.color,
          secondaryColor: item.secondaryColor,
          equalValueAndSecondaryFont: item.equalValueAndSecondaryFont,
          onTap: () => context.push(item.route),
        );
      },
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final Color color;
  final Color? secondaryColor;
  final bool equalValueAndSecondaryFont;
  final String route;
  const _MetricData({
    required this.label,
    required this.value,
    this.secondaryValue,
    required this.icon,
    required this.color,
    this.secondaryColor,
    this.equalValueAndSecondaryFont = false,
    required this.route,
  });
}
