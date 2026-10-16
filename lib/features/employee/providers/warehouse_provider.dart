import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/employee_warehouse_item.dart';
import '../data/repositories/employee_warehouse_repository.dart';

final employeeWarehouseRepositoryProvider =
    Provider<EmployeeWarehouseRepository>(
      (_) => ApiEmployeeWarehouseRepository(),
    );

final employeeWarehouseProvider = FutureProvider<List<EmployeeWarehouseItem>>((
  ref,
) {
  return ref.watch(employeeWarehouseRepositoryProvider).fetchStock();
});
