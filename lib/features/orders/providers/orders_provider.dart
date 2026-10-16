import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/order.dart';
import '../data/repositories/orders_repository.dart';

final ordersRepositoryProvider =
    Provider<OrdersRepository>((_) => MockOrdersRepository());

final ordersProvider = FutureProvider<List<Order>>((ref) {
  return ref.watch(ordersRepositoryProvider).fetchOrders();
});

final orderByIdProvider =
    FutureProvider.family<Order, String>((ref, id) async {
  return ref.watch(ordersRepositoryProvider).fetchById(id);
});
