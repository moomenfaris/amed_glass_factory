import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/admin_metrics.dart';
import '../providers/admin_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(adminSelectedDateProvider);
    final now = selectedDate;
    final current = ref.read(reportRangeProvider);
    DateTimeRange? initial;
    if (current.from != null && current.to != null) {
      var start = current.from!;
      var end = current.to!;
      if (start.isAfter(now)) start = now;
      if (end.isAfter(now)) end = now;
      if (start.isAfter(end)) start = end;
      initial = DateTimeRange(start: start, end: end);
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) {
      ref.read(reportRangeProvider.notifier).state = DateRange(
        from: picked.start,
        to: picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(adminSelectedDateProvider);
    final range = ref.watch(reportRangeProvider);
    final remanufacture = ref.watch(remanufactureProvider);
    final topOrders = ref.watch(topByOrdersProvider);
    final topDebt = ref.watch(topByDebtProvider);

    String rangeLabel() {
      if (range.from == null) return Formatters.date(selectedDate);
      return '${Formatters.date(range.from!)} → ${Formatters.date(range.to!)}';
    }

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            onTap: () => _pickRange(context, ref),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الفترة',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rangeLabel(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (range.from != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        ref.read(reportRangeProvider.notifier).state =
                            const DateRange(),
                  ),
                const Icon(Icons.chevron_left),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'تقرير إعادة التصنيع'),
          remanufacture.when(
            data: (rows) => AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    _RemanRow(row: rows[i]),
                    if (i != rows.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد بيانات'),
                    ),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('خطأ: ${userErrorMessage(e)}'),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'أكثر 5 عملاء بالطلبات'),
          _RankingCard(async: topOrders, suffix: ''),
          const SizedBox(height: 20),
          _SectionHeader(title: 'أكثر 5 عملاء بالديون'),
          _RankingCard(async: topDebt, suffix: ''),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, right: 4),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}

class _RankingCard extends StatelessWidget {
  final AsyncValue<List<CustomerRanking>> async;
  final String suffix;
  const _RankingCard({required this.async, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return async.when(
      data: (rows) => AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  rows[i].name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(rows[i].customerId),
                trailing: Text(
                  '${Formatters.currency(rows[i].value)}$suffix',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (i != rows.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('خطأ: ${userErrorMessage(e)}'),
    );
  }
}

class _RemanRow extends StatelessWidget {
  final RemanufactureRow row;
  const _RemanRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.replay, color: AppTheme.warning, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.orderId} • ${row.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${row.reason} • ${Formatters.date(row.date)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '${row.meters.toStringAsFixed(1)} م²',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
