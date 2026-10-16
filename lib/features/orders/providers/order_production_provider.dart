import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/order_production.dart';
import '../data/repositories/order_production_repository.dart';

final orderProductionRepositoryProvider = Provider<OrderProductionRepository>(
  (_) => ApiOrderProductionRepository(),
);

/// Fetches the production details for a given movement/order id.
final orderProductionProvider =
    FutureProvider.family<List<OrderProductionItem>, String>((ref, orderId) {
      return ref.watch(orderProductionRepositoryProvider).fetch(orderId);
    });

/// Fetches completed movements for the logged-in customer.
final completedMovementsProvider = FutureProvider<List<OrderProductionItem>>((
  ref,
) {
  final user = ref.watch(authStateProvider).user;
  final codeCom = user?.userId ?? int.tryParse(user?.id ?? '');
  if (codeCom == null || codeCom <= 0) {
    throw const ServerFailure('تعذر تحديد رقم المستخدم');
  }
  return ref.watch(orderProductionRepositoryProvider).fetchDone(codeCom);
});

/// Fetches completed movements for employee account from `/api/order-production/all`.
final employeeCompletedMovementsProvider =
    FutureProvider<List<OrderProductionItem>>((ref) {
      return ref.watch(orderProductionRepositoryProvider).fetchAll();
    });
