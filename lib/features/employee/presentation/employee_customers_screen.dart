import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/models/customer.dart';
import '../providers/customers_provider.dart';
import 'widgets/employee_drawer.dart';

class EmployeeCustomersScreen extends ConsumerStatefulWidget {
  const EmployeeCustomersScreen({super.key});

  @override
  ConsumerState<EmployeeCustomersScreen> createState() =>
      _EmployeeCustomersScreenState();
}

class _EmployeeCustomersScreenState
    extends ConsumerState<EmployeeCustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(companyCustomersProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const EmployeeDrawer(),
      appBar: AppBar(title: const AppBarTitle('قائمة العملاء')),
      body: async.when(
        data: (rows) {
          final filtered = _filter(rows, _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو رقم العميل...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              if (rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'العدد: ${filtered.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: rows.isEmpty
                    ? const EmptyState(
                        icon: Icons.group_outlined,
                        message: 'لا توجد بيانات عملاء',
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(companyCustomersProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _CustomerTile(index: i, customer: filtered[i]),
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

  static List<CompanyCustomer> _filter(List<CompanyCustomer> rows, String q) {
    if (q.isEmpty) return rows;
    final lower = q.toLowerCase();
    return rows
        .where(
          (c) =>
              c.name.toLowerCase().contains(lower) ||
              c.codeCom.toString().contains(lower),
        )
        .toList();
  }
}

class _CustomerTile extends StatelessWidget {
  final int index;
  final CompanyCustomer customer;
  const _CustomerTile({required this.index, required this.customer});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          final name = Uri.encodeQueryComponent(customer.name);
          context.push('/employee/customers/${customer.codeCom}?name=$name');
        },
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text('${index + 1}'),
        ),
        title: Text(
          customer.name.isEmpty ? '—' : customer.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('رقم العميل: ${customer.codeCom}'),
        trailing: Icon(Icons.chevron_left, color: colors.onSurfaceVariant),
      ),
    );
  }
}
