import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/customer.dart';
import '../data/repositories/customers_repository.dart';

final customersRepositoryProvider = Provider<CustomersRepository>(
  (_) => ApiCustomersRepository(),
);

final companyCustomersProvider = FutureProvider<List<CompanyCustomer>>((ref) {
  return ref.watch(customersRepositoryProvider).fetchAll();
});
