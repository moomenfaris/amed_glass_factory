enum AdminPeriodReportType {
  orders,
  personalWithdrawals,
  customerReceipts,
  supplierPayments,
  productionDetails,
}

class AdminCustomerDebtSummary {
  final int codeCom;
  final String customerName;
  final double totalDebt;
  final double settledAmount;
  final DateTime? lastSettlementDate;
  final double? lastSettlementAmount;

  const AdminCustomerDebtSummary({
    required this.codeCom,
    required this.customerName,
    required this.totalDebt,
    required this.settledAmount,
    this.lastSettlementDate,
    this.lastSettlementAmount,
  });

  double get remainingDebt => totalDebt - settledAmount;
}

class AdminCustomerDebtTotals {
  final double totalDebt;
  final double executedDebt;

  const AdminCustomerDebtTotals({
    required this.totalDebt,
    required this.executedDebt,
  });

  double get remainingDebt => totalDebt - executedDebt;
}

class AdminExpenseItem {
  final String title;
  final double amount;
  final String details;

  const AdminExpenseItem({
    required this.title,
    required this.amount,
    this.details = '',
  });
}

class AdminExpensesReport {
  final double total;
  final List<AdminExpenseItem> items;

  const AdminExpensesReport({required this.total, required this.items});
}

class AdminCashAccount {
  final String name;
  final double amount;
  final String currency;

  const AdminCashAccount({
    required this.name,
    required this.amount,
    this.currency = '',
  });
}

class AdminPeriodReportEntry {
  final DateTime date;
  final String title;
  final String? subtitle;
  final double amount;

  const AdminPeriodReportEntry({
    required this.date,
    required this.title,
    this.subtitle,
    required this.amount,
  });
}

class AdminPeriodHeaderEntry {
  final String title;
  final double amount;

  const AdminPeriodHeaderEntry({required this.title, required this.amount});
}

class AdminPeriodReport {
  final double total;
  final List<AdminPeriodReportEntry> entries;
  final List<AdminPeriodHeaderEntry> headerEntries;

  const AdminPeriodReport({
    required this.total,
    required this.entries,
    this.headerEntries = const [],
  });
}

class AdminPeriodReportQuery {
  final AdminPeriodReportType type;
  final DateTime from;
  final DateTime to;

  const AdminPeriodReportQuery({
    required this.type,
    required this.from,
    required this.to,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminPeriodReportQuery &&
        other.type == type &&
        other.from == from &&
        other.to == to;
  }

  @override
  int get hashCode => Object.hash(type, from, to);
}
