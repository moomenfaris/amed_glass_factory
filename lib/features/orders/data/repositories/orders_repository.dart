import '../../../../core/mock/mock_data.dart';
import '../models/order.dart';

/// Repository pattern. In production swap implementation with a REST one.
abstract class OrdersRepository {
  Future<List<Order>> fetchOrders();
  Future<Order> fetchById(String id);
}

class MockOrdersRepository implements OrdersRepository {
  @override
  Future<List<Order>> fetchOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return List.unmodifiable(MockData.orders);
  }

  @override
  Future<Order> fetchById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.orders.firstWhere((o) => o.id == id);
  }
}
