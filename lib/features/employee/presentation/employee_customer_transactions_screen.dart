import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../customer/data/models/movement_total_item.dart';
import '../../customer/presentation/widgets/transaction_tile.dart';
import '../../customer/providers/account_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import 'widgets/employee_drawer.dart';

class EmployeeCustomerTransactionsScreen extends ConsumerStatefulWidget {
  final int codeCom;
  final String? customerName;

  const EmployeeCustomerTransactionsScreen({
    super.key,
    required this.codeCom,
    this.customerName,
  });

  @override
  ConsumerState<EmployeeCustomerTransactionsScreen> createState() =>
      _EmployeeCustomerTransactionsScreenState();
}

class _EmployeeCustomerTransactionsScreenState
    extends ConsumerState<EmployeeCustomerTransactionsScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(customerTransactionsProvider(widget.codeCom));
    final totalsAsync = ref.watch(
      customerMovementTotalsProvider(widget.codeCom),
    );

    final availableStatements = txAsync.maybeWhen(
      data: (list) {
        final seen = <String>{};
        final result = <String>[];
        for (final item in list) {
          final s = item.description.trim();
          if (s.isNotEmpty && seen.add(s)) result.add(s);
        }
        return result;
      },
      orElse: () => const <String>[],
    );

    final filteredAsync = txAsync.whenData(
      (list) => _filter == null
          ? list
          : list.where((t) => t.description == _filter).toList(),
    );

    final title = (widget.customerName ?? '').trim();

    return Scaffold(
      drawer: const EmployeeDrawer(),
      appBar: AppBar(
        title: AppBarTitle(title.isEmpty ? 'حركات العميل' : title),
      ),
      body: filteredAsync.when(
        data: (list) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerMovementTotalsProvider(widget.codeCom));
              ref.invalidate(customerTransactionsProvider(widget.codeCom));
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: totalsAsync.when(
                    data: (rows) {
                      if (rows.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 200,
                            child: _SummaryCard(item: rows[i]),
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _SegTab(
                            label: 'الكل',
                            selected: _filter == null,
                            onTap: () => setState(() => _filter = null),
                          ),
                          for (final st in availableStatements)
                            _SegTab(
                              label: st,
                              selected: _filter == st,
                              onTap: () => setState(() => _filter = st),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (list.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'لا توجد حركات',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final tx = list[i];
                        final showCurrentBalance =
                            _filter == null || _filter!.contains('تحت التنفيذ');
                        final canOpenDetails =
                            tx.movementNumber != null &&
                            tx.description.trim() == 'طلبية تحت التنفيذ';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            onTap: canOpenDetails
                                ? () => context.push(
                                    '/movements/${tx.movementNumber}',
                                  )
                                : null,
                            child: TransactionTile(
                              tx: tx,
                              showCurrentBalance: showCurrentBalance,
                              onDetailsTap: canOpenDetails
                                  ? () => context.push(
                                      '/movements/${tx.movementNumber}',
                                    )
                                  : null,
                              onInvoiceTap: tx.movementNumber != null
                                  ? () => context.push(
                                      '/invoices/${tx.movementNumber}',
                                    )
                                  : null,
                              onImagesTap: tx.movementNumber != null
                                  ? () => context.push(
                                      '/movement-images/${tx.movementNumber}',
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
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

class _SegTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SegTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? primary : muted,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MovementTotalItem item;
  const _SummaryCard({required this.item});

  ({Color color, IconData icon, String unit}) _style() {
    final s = item.statement;
    if (s.contains('سند') || s.contains('قيد')) {
      return (
        color: const Color(0xFF16A34A),
        icon: Icons.receipt_long_outlined,
        unit: 'سند قيد',
      );
    }
    if (s.contains('فاتورة') || s.contains('بيع')) {
      return (
        color: const Color(0xFFEA8C00),
        icon: Icons.description_outlined,
        unit: 'فاتورة',
      );
    }
    if (s.contains('قبض') || s.contains('دفع')) {
      return (
        color: const Color(0xFF16A34A),
        icon: Icons.payments_outlined,
        unit: 'دفعة',
      );
    }
    return (
      color: const Color(0xFF2563EB),
      icon: Icons.description_outlined,
      unit: 'طلبية',
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = _style();
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: st.color.withValues(alpha: 0.22)),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(st.icon, color: st.color, size: 17),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  item.statement,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: st.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${item.count}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: st.color,
              ),
            ),
          ),
          Center(
            child: Text(st.unit, style: TextStyle(fontSize: 12, color: muted)),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${item.net.isNegative ? '−' : ''}${Formatters.currency(item.net.abs())}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: st.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
