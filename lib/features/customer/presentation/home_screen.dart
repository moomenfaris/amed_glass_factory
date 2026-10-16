import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/services/home_entry_metadata_service.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/app_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../providers/account_provider.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final HomeEntryMetadataService _homeEntryMetadataService =
      HomeEntryMetadataService();
  int? _lastSentForUserId;
  ProviderSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendHomeEntryMetadataIfNeeded();
      ref
          .read(authStateProvider.notifier)
          .refreshUserState(force: true, apiType: 'company');
    });
    _authSubscription = ref.listenManual<AuthState>(authStateProvider, (
      _,
      next,
    ) {
      final userId = next.user?.userId ?? int.tryParse(next.user?.id ?? '');
      if (userId != null && userId > 0 && _lastSentForUserId != userId) {
        _sendHomeEntryMetadataIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  Future<void> _sendHomeEntryMetadataIfNeeded() async {
    final auth = ref.read(authStateProvider);
    final user = auth.user;
    final userId = user?.userId ?? int.tryParse(user?.id ?? '');
    if (userId == null || userId <= 0 || _lastSentForUserId == userId) return;

    try {
      final payload = await _homeEntryMetadataService.sendForUserOnHomeEnter(
        user: user,
        authToken: auth.token,
      );
      if (payload == null) return;
      _lastSentForUserId = userId;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال المعلومات: ${userErrorMessage(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final summaryAsync = ref.watch(accountSummaryProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const AppBarTitle('كشف الحساب')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(accountSummaryProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Text(
                  'مرحباً، ${user.fullName}',
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
                  onPressed: () => context.go('/transactions'),
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
                          onTap: last5[i].orderId != null
                              ? () =>
                                    context.push('/orders/${last5[i].orderId}')
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
