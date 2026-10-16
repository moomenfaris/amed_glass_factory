class AdminMetrics {
  final double currentCash;
  final double currentCashDollar;
  final double currentCashDinar;
  final double todayMeters;
  final double todayOrdersValue;
  final double deliveredOrdersValue;
  final double purchasesToday;
  final double currentInventoryValue;
  final double expensesToday;
  final double revenuesToday;
  final double productionDetailsTotal;
  final double productionDetailsDouble;
  final double productionDetailsSingle;
  final double customerDebtsTotal;
  final double customerDebtsExecuted;

  const AdminMetrics({
    required this.currentCash,
    required this.currentCashDollar,
    required this.currentCashDinar,
    required this.todayMeters,
    required this.todayOrdersValue,
    required this.deliveredOrdersValue,
    required this.purchasesToday,
    required this.currentInventoryValue,
    required this.expensesToday,
    required this.revenuesToday,
    required this.productionDetailsTotal,
    required this.productionDetailsDouble,
    required this.productionDetailsSingle,
    required this.customerDebtsTotal,
    required this.customerDebtsExecuted,
  });
}

class CustomerRanking {
  final String customerId;
  final String name;
  final double value;
  const CustomerRanking({
    required this.customerId,
    required this.name,
    required this.value,
  });
}

class RemanufactureRow {
  final String orderId;
  final String customerName;
  final DateTime date;
  final String reason;
  final double meters;
  const RemanufactureRow({
    required this.orderId,
    required this.customerName,
    required this.date,
    required this.reason,
    required this.meters,
  });
}
