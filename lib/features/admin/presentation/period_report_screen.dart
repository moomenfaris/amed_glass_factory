import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/models/admin_reporting.dart';
import '../providers/admin_provider.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/admin_widgets.dart';

class PeriodReportScreen extends ConsumerStatefulWidget {
  final String title;
  final AdminPeriodReportType type;
  final String totalLabel;
  final String amountSuffix;

  const PeriodReportScreen({
    super.key,
    required this.title,
    required this.type,
    required this.totalLabel,
    this.amountSuffix = '',
  });

  @override
  ConsumerState<PeriodReportScreen> createState() => _PeriodReportScreenState();
}

class _PeriodReportScreenState extends ConsumerState<PeriodReportScreen> {
  DateTime? _customFrom;
  DateTime? _customTo;

  DateTime get _from {
    if (_customFrom != null) return _customFrom!;
    final selectedDate = ref.read(adminSelectedDateProvider);
    final now = selectedDate;
    return switch (ref.read(adminPeriodProvider)) {
      AdminPeriod.today => DateTime(now.year, now.month, now.day),
      AdminPeriod.month => DateTime(now.year, now.month, 1),
      AdminPeriod.year => DateTime(now.year, 1, 1),
    };
  }

  DateTime get _to {
    if (_customTo != null) return _customTo!;
    final selectedDate = ref.read(adminSelectedDateProvider);
    final now = selectedDate;
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isMeters => widget.amountSuffix.isNotEmpty;
  bool get _isProductionDetails =>
      widget.type == AdminPeriodReportType.productionDetails;
  bool get _isSupplierPayments =>
      widget.type == AdminPeriodReportType.supplierPayments;
  bool get _isOrders => widget.type == AdminPeriodReportType.orders;

  Future<void> _pickRange() async {
    final selectedDate = ref.read(adminSelectedDateProvider);
    final now = selectedDate;
    var initialStart = _from;
    var initialEnd = _to;
    if (initialStart.isAfter(now)) initialStart = now;
    if (initialEnd.isAfter(now)) initialEnd = now;
    if (initialStart.isAfter(initialEnd)) initialStart = initialEnd;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) return;
    setState(() {
      _customFrom = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _customTo = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(adminSelectedDateProvider);
    final period = ref.watch(adminPeriodProvider);
    final query = AdminPeriodReportQuery(
      type: widget.type,
      from: _from,
      to: _to,
    );
    final async = ref.watch(adminPeriodReportProvider(query));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: AppBarTitle(widget.title),
        actions: [
          IconButton(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range_rounded),
          ),
        ],
      ),
      body: async.when(
        data: (report) {
          final chartData = _buildChartData(report);
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(adminPeriodReportProvider(query)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                AdminPeriodChips(
                  value: period,
                  onChanged: (p) {
                    ref.read(adminPeriodProvider.notifier).setPeriod(p);
                    setState(() {
                      _customFrom = null;
                      _customTo = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                AdminTotalBanner(
                  label: widget.totalLabel,
                  value: _formatAmount(report.total),
                ),
                if (_isProductionDetails &&
                    report.headerEntries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const AdminSectionHeader(title: 'الملخص حسب نوع الطلبية'),
                  const SizedBox(height: 10),
                  AdminCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 14,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < report.headerEntries.length; i++)
                          _HeaderEntryRow(
                            entry: report.headerEntries[i],
                            amountText: _formatAmount(
                              report.headerEntries[i].amount,
                            ),
                            showDivider: i != report.headerEntries.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
                if (chartData.values.length > 1 &&
                    widget.type != AdminPeriodReportType.orders &&
                    widget.type != AdminPeriodReportType.customerReceipts &&
                    !_isSupplierPayments &&
                    widget.type !=
                        AdminPeriodReportType.personalWithdrawals) ...[
                  const SizedBox(height: 16),
                  AdminCard(
                    child: AdminBarChart(
                      values: chartData.values,
                      labels: chartData.labels,
                      color: _isMeters
                          ? AdminPalette.purple
                          : AdminPalette.blue,
                      showValueLabels: _isProductionDetails,
                      valueUnit: _isMeters ? widget.amountSuffix : '',
                      valueDecimals: _isMeters ? 1 : 0,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const AdminSectionHeader(title: 'التفاصيل'),
                const SizedBox(height: 10),
                if (report.entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'لا توجد بيانات ضمن هذه الفترة',
                    ),
                  )
                else if (_isSupplierPayments)
                  Column(
                    children: [
                      for (var i = 0; i < report.entries.length; i++)
                        _EntryRow(
                          entry: report.entries[i],
                          amountText: _formatAmount(report.entries[i].amount),
                          showDivider: i != report.entries.length - 1,
                          showDate: !_isProductionDetails,
                          onTap: _invoiceIdFromEntry(report.entries[i]) == null
                              ? null
                              : () => context.push(
                                  '/invoices/${_invoiceIdFromEntry(report.entries[i])}',
                                ),
                        ),
                    ],
                  )
                else
                  AdminCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 14,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < report.entries.length; i++)
                          _EntryRow(
                            entry: report.entries[i],
                            amountText: _formatAmount(report.entries[i].amount),
                            showDivider: i != report.entries.length - 1,
                            showDate: !_isProductionDetails,
                            onTap:
                                _invoiceIdFromEntry(report.entries[i]) == null
                                ? null
                                : () => context.push(
                                    '/invoices/${_invoiceIdFromEntry(report.entries[i])}',
                                  ),
                          ),
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

  String _formatAmount(double value) {
    if (widget.amountSuffix.isEmpty) return Formatters.currency(value);
    return '${value.toStringAsFixed(1)} ${widget.amountSuffix}';
  }

  ({List<double> values, List<String> labels}) _buildChartData(
    AdminPeriodReport report,
  ) {
    final useMonthlyTotals =
        widget.type == AdminPeriodReportType.personalWithdrawals &&
        ref.read(adminPeriodProvider) == AdminPeriod.year;

    if (!useMonthlyTotals) {
      if (_isProductionDetails) {
        return (
          values: report.entries.map((e) => e.amount).toList(),
          labels: report.entries.map((e) => e.title).toList(),
        );
      }
      return (
        values: report.entries.map((e) => e.amount).toList(),
        labels: report.entries
            .map((e) => '${e.date.day}/${e.date.month}')
            .toList(),
      );
    }

    final monthly = <int, double>{};
    for (final entry in report.entries) {
      final month = entry.date.month;
      monthly[month] = (monthly[month] ?? 0) + entry.amount;
    }

    final months = monthly.keys.toList()..sort();
    return (
      values: months.map((m) => monthly[m] ?? 0).toList(),
      labels: months.map((m) => 'ش$m').toList(),
    );
  }

  String? _invoiceIdFromEntry(AdminPeriodReportEntry entry) {
    if (!_isOrders) return null;

    final text = '${entry.title} ${entry.subtitle ?? ''}';
    final hashMatch = RegExp(r'#\s*(\d+)').firstMatch(text);
    if (hashMatch != null) return hashMatch.group(1);

    final anyDigits = RegExp(r'(\d+)').firstMatch(text);
    return anyDigits?.group(1);
  }
}

class _EntryRow extends StatelessWidget {
  final AdminPeriodReportEntry entry;
  final String amountText;
  final bool showDivider;
  final bool showDate;
  final VoidCallback? onTap;

  const _EntryRow({
    required this.entry,
    required this.amountText,
    required this.showDivider,
    this.showDate = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: showDivider ? AdminPalette.line : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AdminPalette.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 20,
                color: AdminPalette.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if ((entry.subtitle != null && entry.subtitle!.isNotEmpty) ||
                      showDate)
                    Text(
                      entry.subtitle == null || entry.subtitle!.isEmpty
                          ? (showDate ? Formatters.date(entry.date) : '')
                          : (showDate
                                ? '${entry.subtitle} • ${Formatters.date(entry.date)}'
                                : entry.subtitle!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AdminPalette.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderEntryRow extends StatelessWidget {
  final AdminPeriodHeaderEntry entry;
  final String amountText;
  final bool showDivider;

  const _HeaderEntryRow({
    required this.entry,
    required this.amountText,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: showDivider ? AdminPalette.line : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AdminPalette.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.category_rounded,
              size: 20,
              color: AdminPalette.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AdminPalette.blue,
            ),
          ),
        ],
      ),
    );
  }
}
