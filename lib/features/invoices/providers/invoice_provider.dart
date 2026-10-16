import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/invoice.dart';
import '../data/repositories/invoice_repository.dart';

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (_) => ApiInvoiceRepository(),
);

final invoiceProvider = FutureProvider.family<Invoice, int>((ref, invoiceId) {
  return ref.watch(invoiceRepositoryProvider).fetch(invoiceId);
});
