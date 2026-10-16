import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/error/error_message.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/staff_salary_provider.dart';

class StaffPlusHoursScreen extends ConsumerWidget {
  final int employeeId;
  final DateTime at;

  const StaffPlusHoursScreen({
    super.key,
    required this.employeeId,
    required this.at,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = StaffSalaryQuery(employeeId: employeeId, at: at);
    final async = ref.watch(staffPlusHoursDetailsProvider(query));
    final dateLabel = DateFormat('yyyy/MM/dd').format(at);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const AppBarTitle('الساعات الإضافية'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(staffPlusHoursDetailsProvider(query)),
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
        data: (details) {
          if (details.days.isEmpty) {
            return const EmptyState(
              icon: Icons.schedule_outlined,
              message: 'لا توجد ساعات إضافية ضمن الفترة المحددة',
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(staffPlusHoursDetailsProvider(query)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _SummaryCard(
                  totalHours: details.totalHours,
                  dateLabel: dateLabel,
                ),
                const SizedBox(height: 12),
                const Text(
                  'تفاصيل الأيام',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final day in details.days) ...[
                  _DayRow(day: day.day, hours: day.hours),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double totalHours;
  final String dateLabel;

  const _SummaryCard({required this.totalHours, required this.dateLabel});

  String _fmt(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تاريخ التقرير: $dateLabel',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'إجمالي الساعات الإضافية',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_fmt(totalHours)} ساعة',
            style: const TextStyle(
              color: Color(0xFF1A5FD0),
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  final double hours;

  const _DayRow({required this.day, required this.hours});

  String _fmt(double value) {
    if ((value - value.roundToDouble()).abs() < 0.0001) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: const TextStyle(
                color: Color(0xFF1A5FD0),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'اليوم',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_fmt(hours)} ساعة',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
