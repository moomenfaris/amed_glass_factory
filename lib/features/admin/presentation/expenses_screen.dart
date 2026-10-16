import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/admin_widgets.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  bool _showAll = false;

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

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(adminSelectedDateProvider);
    final period = ref.watch(adminPeriodProvider);
    return _ExpensesScope(
      period: period,
      showAll: _showAll,
      from: _from(selectedDate, period),
      to: _to(selectedDate),
      onPeriodChanged: (p) =>
          ref.read(adminPeriodProvider.notifier).setPeriod(p),
      onToggleShowAll: () => setState(() => _showAll = !_showAll),
    );
  }
}

class _ExpensesScope extends ConsumerWidget {
  final AdminPeriod period;
  final bool showAll;
  final DateTime from;
  final DateTime to;
  final ValueChanged<AdminPeriod> onPeriodChanged;
  final VoidCallback onToggleShowAll;

  const _ExpensesScope({
    required this.period,
    required this.showAll,
    required this.from,
    required this.to,
    required this.onPeriodChanged,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = AdminExpensesQuery(from: from, to: to);
    final async = ref.watch(adminExpensesReportProvider(query));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const AppBarTitle('المصروفات')),
      body: async.when(
        data: (report) {
          if (report.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(adminExpensesReportProvider(query)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  AdminPeriodChips(value: period, onChanged: onPeriodChanged),
                  const SizedBox(height: 14),
                  AdminTotalBanner(
                    label: 'اجمالي المصروفات',
                    value: Formatters.currency(report.total),
                  ),
                  const SizedBox(height: 24),
                  const EmptyState(
                    icon: Icons.payments_outlined,
                    message: 'لا توجد مصروفات ضمن هذه الفترة',
                  ),
                ],
              ),
            );
          }

          final topItems = report.items.length > 5
              ? report.items.sublist(0, 5)
              : report.items;
          final visibleItems = showAll ? report.items : topItems;
          final total = report.total <= 0
              ? report.items.fold<double>(0, (s, e) => s + e.amount)
              : report.total;

          final segments = <AdminDonutSegment>[
            for (var i = 0; i < topItems.length; i++)
              AdminDonutSegment(
                label: topItems[i].title,
                value: topItems[i].amount,
                color: AdminPalette.chart[i % AdminPalette.chart.length],
              ),
          ];

          final maxAmount = topItems
              .map((e) => e.amount)
              .fold<double>(0, (m, v) => v > m ? v : m);

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminExpensesReportProvider(query)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                AdminPeriodChips(value: period, onChanged: onPeriodChanged),
                const SizedBox(height: 14),
                AdminCard(
                  child: Column(
                    children: [
                      AdminTotalBanner(
                        label: 'اجمالي المصروفات',
                        value: Formatters.currency(total),
                      ),
                      const SizedBox(height: 16),
                      AdminDonutChart(
                        segments: segments,
                        centerLabel: Formatters.currency(total),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            showAll ? 'كل المصروفات' : 'أعلى المصروفات',
                            style: TextStyle(
                              color: AdminPalette.blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onToggleShowAll,
                            child: Text(
                              showAll ? 'عرض أقل' : 'عرض الكل',
                              style: const TextStyle(
                                color: AdminPalette.blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < visibleItems.length; i++) ...[
                        AdminProgressRow(
                          label: visibleItems[i].title,
                          value: Formatters.currency(visibleItems[i].amount),
                          fraction: maxAmount <= 0
                              ? 0
                              : visibleItems[i].amount / maxAmount,
                          color:
                              AdminPalette.chart[i % AdminPalette.chart.length],
                        ),
                        if (showAll && visibleItems[i].details.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                visibleItems[i].details,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
      ),
    );
  }
}
