import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/app_card.dart';
import '../../customer/presentation/widgets/balance_card.dart';
import '../../customer/presentation/widgets/transaction_tile.dart';
import '../../customer/providers/account_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import 'widgets/employee_drawer.dart';

class EmployeeCustomerHomeScreen extends ConsumerWidget {
  final int codeCom;
  final String? customerName;
  final String transactionsRouteBase;

  const EmployeeCustomerHomeScreen({
    super.key,
    required this.codeCom,
    this.customerName,
    required this.transactionsRouteBase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(customerAccountSummaryProvider(codeCom));
    final txAsync = ref.watch(customerTransactionsProvider(codeCom));
    final title = (customerName ?? '').trim();

    return Scaffold(
      drawer: const EmployeeDrawer(),
      appBar: AppBar(title: AppBarTitle(title.isEmpty ? 'حساب العميل' : title)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerAccountSummaryProvider(codeCom));
          ref.invalidate(customerTransactionsProvider(codeCom));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Text(
                  'مرحباً، $title',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            summaryAsync.when(
              data: (s) => BalanceCard(
                balance: s.totalIndebtedness,
                debt: s.executedIndebtedness,
              ),
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطأ: ${userErrorMessage(e)}'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'آخر الحركات',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                TextButton(
                  onPressed: () {
                    final name = Uri.encodeQueryComponent(title);
                    context.push(
                      '$transactionsRouteBase/$codeCom/transactions?name=$name',
                    );
                  },
                  child: const Text('عرض الكل'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            txAsync.when(
              data: (list) {
                final last5 = list.take(5).toList();
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < last5.length; i++) ...[
                        TransactionTile(
                          tx: last5[i],
                          onDetailsTap:
                              last5[i].movementNumber != null &&
                                  last5[i].description.trim() ==
                                      'طلبية تحت التنفيذ'
                              ? () => context.push(
                                  '/movements/${last5[i].movementNumber}',
                                )
                              : null,
                          onInvoiceTap: last5[i].movementNumber != null
                              ? () => context.push(
                                  '/invoices/${last5[i].movementNumber}',
                                )
                              : null,
                          onImagesTap: last5[i].movementNumber != null
                              ? () => context.push(
                                  '/movement-images/${last5[i].movementNumber}',
                                )
                              : null,
                        ),
                        if (i != last5.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                      if (last5.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('لا توجد حركات'),
                        ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطأ: ${userErrorMessage(e)}'),
            ),
          ],
        ),
      ),
    );
  }
}
