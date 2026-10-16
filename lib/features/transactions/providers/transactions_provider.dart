import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transactions_repository.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final user = ref.watch(authStateProvider).user;
  final codeCom = user?.userId ?? int.tryParse(user?.id ?? '');
  if (codeCom == null || codeCom <= 0) {
    return MockTransactionsRepository();
  }
  return ApiTransactionsRepository(codeCom: codeCom, dateTo: DateTime.now());
});

final transactionsProvider = FutureProvider<List<AccountTransaction>>((
  ref,
) async {
  return ref.watch(transactionsRepositoryProvider).fetchAll();
});

/// Selected statement (البيان) filter for transactions screen. `null` = all.
final transactionsFilterProvider = StateProvider<String?>((_) => null);

final filteredTransactionsProvider =
    Provider<AsyncValue<List<AccountTransaction>>>((ref) {
      final filter = ref.watch(transactionsFilterProvider);
      final async = ref.watch(transactionsProvider);
      return async.whenData(
        (list) => filter == null
            ? list
            : list.where((t) => t.description == filter).toList(),
      );
    });

/// Fetches transactions for an arbitrary customer (used by employee account).
final customerTransactionsProvider =
    FutureProvider.family<List<AccountTransaction>, int>((ref, codeCom) {
      final repo = ApiTransactionsRepository(
        codeCom: codeCom,
        dateTo: DateTime.now(),
      );
      return repo.fetchAll();
    });
