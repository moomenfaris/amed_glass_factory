import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/models/employee_warehouse_item.dart';
import '../providers/warehouse_provider.dart';
import 'widgets/employee_drawer.dart';

class EmployeeWarehouseScreen extends ConsumerStatefulWidget {
  const EmployeeWarehouseScreen({super.key});

  @override
  ConsumerState<EmployeeWarehouseScreen> createState() =>
      _EmployeeWarehouseScreenState();
}

class _EmployeeWarehouseScreenState
    extends ConsumerState<EmployeeWarehouseScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(employeeWarehouseProvider);

    return Scaffold(
      drawer: const EmployeeDrawer(),
      appBar: AppBar(title: const AppBarTitle('المخزن')),
      body: async.when(
        data: (rows) {
          final filtered = _filter(rows, _query);
          final totalValue = filtered.fold<double>(0, (s, e) => s + e.total);
          final totalMeters = filtered.fold<double>(0, (s, e) => s + e.meters);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث بالكود أو اسم المادة...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        label: 'عدد المواد',
                        value: '${filtered.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryChip(
                        label: 'مجموع الامتار',
                        value: '${totalMeters.toStringAsFixed(2)} م²',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryChip(
                        label: 'القيمة',
                        value: Formatters.currency(totalValue),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        message: 'لا توجد بيانات مخزن',
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(employeeWarehouseProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _WarehouseTile(item: filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
      ),
    );
  }

  List<EmployeeWarehouseItem> _filter(
    List<EmployeeWarehouseItem> rows,
    String q,
  ) {
    if (q.isEmpty) return rows;
    final lower = q.toLowerCase();
    return rows
        .where(
          (e) =>
              e.code.toLowerCase().contains(lower) ||
              e.materialName.toLowerCase().contains(lower),
        )
        .toList();
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseTile extends StatelessWidget {
  final EmployeeWarehouseItem item;

  const _WarehouseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.materialName.isEmpty ? '—' : item.materialName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'كود ${item.code}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _Field(
                  label: 'الامتار',
                  value: '${item.meters.toStringAsFixed(2)} م²',
                ),
                _Field(label: 'الالواح', value: '${item.sheets}'),
                _Field(
                  label: 'سعر الكلفة',
                  value: Formatters.currency(item.costPrice),
                ),
                _Field(
                  label: 'المقاس',
                  value:
                      '${item.length.toStringAsFixed(2)} × ${item.width.toStringAsFixed(2)}',
                ),
                _Field(
                  label: 'الاجمالي',
                  value: Formatters.currency(item.total),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: colors.onSurface, fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
