import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_provider.dart';
import 'widgets/admin_drawer.dart';
import 'widgets/admin_widgets.dart';

class CashAccountsScreen extends ConsumerWidget {
  const CashAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCashAccountsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AdminDrawer(),
      appBar: AppBar(title: const AppBarTitle('النقد')),
      body: async.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'لا توجد حسابات نقد',
            );
          }

          final totalDollar = rows
              .where((r) => r.currency.trim() == 'دولار')
              .fold<double>(0, (sum, row) => sum + row.amount);
          final totalDinar = rows
              .where((r) => r.currency.trim() == 'دينار')
              .fold<double>(0, (sum, row) => sum + row.amount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminCashAccountsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                AdminTotalBanner(
                  label: 'اجمالي النقد',
                  value:
                      '${Formatters.currency(totalDollar)} دولار | ${Formatters.numberGrouped(totalDinar)} دينار',
                  color: AdminPalette.green,
                  background: AdminPalette.greenSoft,
                ),
                const SizedBox(height: 16),
                const AdminSectionHeader(title: 'الصناديق'),
                const SizedBox(height: 10),
                AdminCard(
                  padding: EdgeInsets.zero,
                  child: AdminDataTable(
                    headers: const ['الوصف', 'المبلغ'],
                    flex: const [6, 4],
                    rows: [
                      for (final row in rows)
                        [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AdminPalette.greenSoft,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                  color: AdminPalette.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: adminCell(row.name, bold: true)),
                            ],
                          ),
                          adminCell(
                            _formatCashAmount(row.amount, row.currency),
                            bold: true,
                            color: row.currency.trim() == 'دولار'
                                ? AdminPalette.green
                                : AdminPalette.blue,
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

  String _formatCashAmount(double value, String currency) {
    if (currency.trim() == 'دينار') {
      return '${Formatters.numberGrouped(value)} دينار';
    }
    if (currency.trim() == 'دولار') {
      return '${Formatters.currency(value)} دولار';
    }
    return Formatters.numberGrouped(value);
  }
}
