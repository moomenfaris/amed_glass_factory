import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/models/account_summary.dart';
import '../data/models/movement_total_item.dart';
import '../data/repositories/account_repository.dart';

String _normalizeArabic(String input) {
  return input
      .trim()
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا');
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final user = ref.watch(authStateProvider).user;
  final codeCom = user?.userId ?? int.tryParse(user?.id ?? '');
  if (codeCom == null || codeCom <= 0) {
    return MockAccountRepository();
  }

  return ApiAccountRepository(codeCom: codeCom, dateTo: DateTime.now());
});

final accountSummaryProvider = FutureProvider<AccountSummary>((ref) {
  return ref.watch(accountRepositoryProvider).fetchSummary();
});

/// Account summary for an arbitrary customer (used by admin/employee flows).
final customerAccountSummaryProvider =
    FutureProvider.family<AccountSummary, int>((ref, codeCom) {
      final repo = ApiAccountRepository(
        codeCom: codeCom,
        dateTo: DateTime.now(),
      );
      return repo.fetchSummary();
    });

final movementTotalsProvider = FutureProvider<List<MovementTotalItem>>((
  ref,
) async {
  final rows = await ref.watch(accountRepositoryProvider).fetchTotalsRows();

  return rows.where((row) {
    final statement = _normalizeArabic(row.statement);
    return statement != 'اجمالي المديونية' && statement != 'المديونية المنفذة';
  }).toList();
});

/// Movement totals for an arbitrary customer (used by employee account).
final customerMovementTotalsProvider =
    FutureProvider.family<List<MovementTotalItem>, int>((ref, codeCom) async {
      final repo = ApiAccountRepository(
        codeCom: codeCom,
        dateTo: DateTime.now(),
      );
      final rows = await repo.fetchTotalsRows();
      return rows.where((row) {
        final statement = _normalizeArabic(row.statement);
        return statement != 'اجمالي المديونية' &&
            statement != 'المديونية المنفذة';
      }).toList();
    });
