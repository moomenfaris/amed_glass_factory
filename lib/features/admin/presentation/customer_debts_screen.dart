import 'dart:math' as math;

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

class CustomerDebtsScreen extends ConsumerWidget {
  const CustomerDebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCustomerDebtsProvider);
    final totalsAsync = ref.watch(adminCustomerDebtTotalsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const AppBarTitle('الديون')),
      body: async.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              message: 'لا توجد بيانات ديون',
            );
          }

          final totalDebt = rows.fold<double>(0, (s, r) => s + r.totalDebt);
          final totalRemaining = rows.fold<double>(
            0,
            (s, r) => s + r.remainingDebt,
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminCustomerDebtsProvider);
              ref.invalidate(adminCustomerDebtTotalsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                totalsAsync.when(
                  data: (totals) => _DebtsPieSummary(
                    totals: totals,
                    customerCount: rows.length,
                  ),
                  loading: () => const SizedBox(
                    height: 230,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => _DebtsPieSummary(
                    totals: AdminCustomerDebtTotals(
                      totalDebt: totalDebt,
                      executedDebt: totalDebt - totalRemaining,
                    ),
                    customerCount: rows.length,
                  ),
                ),
                const SizedBox(height: 16),
                const AdminSectionHeader(title: 'تفاصيل الديون'),
                const SizedBox(height: 10),
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: AdminDataTable(
                    headers: const [
                      'اسم الزبون',
                      'المسلم',
                      'الاجمالي',
                      'اخر تسديد',
                    ],
                    flex: const [5, 3, 3, 4],
                    rows: [
                      for (final r in rows)
                        [
                          GestureDetector(
                            onTap: () {
                              final name = Uri.encodeQueryComponent(
                                r.customerName,
                              );
                              context.push(
                                '/admin/customer-debts/${r.codeCom}?name=$name',
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                adminCell(r.customerName, bold: true),
                                const SizedBox(height: 2),
                                Text(
                                  r.lastSettlementDate == null
                                      ? 'لا يوجد تاريخ تسديد'
                                      : 'اخر تاريخ: ${Formatters.date(r.lastSettlementDate!)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          adminCell(
                            Formatters.currency(r.settledAmount),
                            color: AdminPalette.green,
                          ),
                          adminCell(
                            Formatters.currency(r.totalDebt),
                            bold: true,
                            color: AdminPalette.red,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              adminCell(
                                Formatters.currency(
                                  r.lastSettlementAmount ?? 0,
                                ),
                                bold: true,
                                color: AdminPalette.blue,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.lastSettlementDate == null
                                    ? '-'
                                    : Formatters.date(r.lastSettlementDate!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

class _DebtsPieSummary extends StatelessWidget {
  final AdminCustomerDebtTotals totals;
  final int customerCount;

  const _DebtsPieSummary({required this.totals, required this.customerCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminPalette.blueSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminPalette.blue.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع الديون',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _DebtPieChart(
            totalDebt: totals.totalDebt,
            executedDebt: totals.executedDebt,
          ),
          const SizedBox(height: 12),
          _row(
            context,
            'اجمالي المديونية',
            Formatters.currency(totals.totalDebt),
          ),
          const Divider(height: 22, color: Color(0x222563EB)),
          _row(
            context,
            'المديونية المنفذة',
            Formatters.currency(totals.executedDebt),
          ),
          const Divider(height: 22, color: Color(0x222563EB)),
          _row(
            context,
            'تحت التنفيذ',
            Formatters.currency(totals.remainingDebt),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 16,
                  color: AdminPalette.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  'عدد المدينين  $customerCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AdminPalette.blue,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _DebtPieChart extends StatelessWidget {
  final double totalDebt;
  final double executedDebt;

  const _DebtPieChart({required this.totalDebt, required this.executedDebt});

  @override
  Widget build(BuildContext context) {
    final remaining = (totalDebt - executedDebt).clamp(0, double.infinity);
    final safeTotal = totalDebt <= 0 ? 1.0 : totalDebt;

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DebtPiePainter(
              executedFraction: (executedDebt / safeTotal).clamp(0, 1),
            ),
            child: Center(
              child: Text(
                '${((executedDebt / safeTotal) * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              _legend(
                context: context,
                label: 'منفذ',
                color: AdminPalette.green,
                value: Formatters.currency(executedDebt),
              ),
              const SizedBox(height: 8),
              _legend(
                context: context,
                label: 'تحت التنفيذ',
                color: AdminPalette.red,
                value: Formatters.currency(remaining),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend({
    required BuildContext context,
    required String label,
    required Color color,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DebtPiePainter extends CustomPainter {
  final double executedFraction;

  const _DebtPiePainter({required this.executedFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()..color = AdminPalette.red;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, true, bg);

    final fg = Paint()..color = AdminPalette.green;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * executedFraction,
      true,
      fg,
    );

    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.38, dot);
  }

  @override
  bool shouldRepaint(covariant _DebtPiePainter oldDelegate) {
    return oldDelegate.executedFraction != executedFraction;
  }
}
