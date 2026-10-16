import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/admin_metrics.dart';
import '../data/models/admin_reporting.dart';
import '../data/repositories/admin_repository.dart';
import '../presentation/widgets/admin_widgets.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Persists the selected dashboard period (اليوم / هذا الشهر / هذه السنة)
/// per user, so every admin screen opens with the same period the user chose.
class AdminPeriodNotifier extends Notifier<AdminPeriod> {
  @override
  AdminPeriod build() {
    final userId = ref.watch(
      authStateProvider.select(
        (s) => s.user?.userId ?? int.tryParse(s.user?.id ?? ''),
      ),
    );
    return AdminPeriodLabel.fromStorage(LocalStorage.getString(_key(userId)));
  }

  String _key(int? userId) =>
      '${LocalStorage.kAdminPeriodPrefix}${userId ?? 'guest'}';

  void setPeriod(AdminPeriod period) {
    final userId = ref.read(
      authStateProvider.select(
        (s) => s.user?.userId ?? int.tryParse(s.user?.id ?? ''),
      ),
    );
    state = period;
    LocalStorage.setString(_key(userId), period.storageKey);
  }
}

final adminPeriodProvider = NotifierProvider<AdminPeriodNotifier, AdminPeriod>(
  AdminPeriodNotifier.new,
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (_) => ApiAdminRepository(),
);

class AdminMetricsQuery {
  final DateTime from;
  final DateTime to;

  const AdminMetricsQuery({required this.from, required this.to});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminMetricsQuery && other.from == from && other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}

final adminMetricsProvider =
    FutureProvider.family<AdminMetrics, AdminMetricsQuery>((ref, query) {
      return ref
          .watch(adminRepositoryProvider)
          .fetchMetrics(from: query.from, to: query.to);
    });

final adminCustomerDebtsProvider =
    FutureProvider<List<AdminCustomerDebtSummary>>((ref) {
      return ref.watch(adminRepositoryProvider).fetchCustomerDebts();
    });

final adminCustomerDebtTotalsProvider = FutureProvider<AdminCustomerDebtTotals>(
  (ref) {
    return ref.watch(adminRepositoryProvider).fetchCustomerDebtTotals();
  },
);

class AdminExpensesQuery {
  final DateTime from;
  final DateTime to;

  const AdminExpensesQuery({required this.from, required this.to});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminExpensesQuery && other.from == from && other.to == to;
  }

  @override
  int get hashCode => Object.hash(from, to);
}

final adminExpensesReportProvider =
    FutureProvider.family<AdminExpensesReport, AdminExpensesQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminRepositoryProvider)
          .fetchExpensesReport(from: query.from, to: query.to);
    });

final adminCashAccountsProvider = FutureProvider<List<AdminCashAccount>>((ref) {
  return ref.watch(adminRepositoryProvider).fetchCashAccounts();
});

final adminPeriodReportProvider =
    FutureProvider.family<AdminPeriodReport, AdminPeriodReportQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(adminRepositoryProvider)
          .fetchPeriodReport(type: query.type, from: query.from, to: query.to);
    });

class DateRange {
  final DateTime? from;
  final DateTime? to;
  const DateRange({this.from, this.to});
}

final adminSelectedDateProvider = StateProvider<DateTime>(
  (_) => _dateOnly(DateTime.now()),
);

final reportRangeProvider = StateProvider<DateRange>((_) => const DateRange());

final topByOrdersProvider = FutureProvider<List<CustomerRanking>>((ref) async {
  final r = ref.watch(reportRangeProvider);
  final selectedDate = ref.watch(adminSelectedDateProvider);
  return ref
      .watch(adminRepositoryProvider)
      .topByOrders(from: r.from ?? selectedDate, to: r.to ?? selectedDate);
});

final topByDebtProvider = FutureProvider<List<CustomerRanking>>((ref) async {
  final r = ref.watch(reportRangeProvider);
  final selectedDate = ref.watch(adminSelectedDateProvider);
  return ref
      .watch(adminRepositoryProvider)
      .topByDebt(from: r.from ?? selectedDate, to: r.to ?? selectedDate);
});

final remanufactureProvider = FutureProvider<List<RemanufactureRow>>((
  ref,
) async {
  final r = ref.watch(reportRangeProvider);
  final selectedDate = ref.watch(adminSelectedDateProvider);
  return ref
      .watch(adminRepositoryProvider)
      .remanufactureReport(
        from: r.from ?? selectedDate,
        to: r.to ?? selectedDate,
      );
});
