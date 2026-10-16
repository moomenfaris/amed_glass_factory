import '../../features/admin/data/models/admin_metrics.dart';
import '../../features/admin/data/models/admin_reporting.dart';
import '../../features/customer/data/models/account_summary.dart';
import '../../features/orders/data/models/order.dart';
import '../../features/transactions/data/models/transaction.dart';

/// Central mock dataset used by all mock services. Replace with real REST data.
class MockData {
  MockData._();

  static DateTime _d(int daysAgo, [int h = 10, int m = 0]) => DateTime.now()
      .subtract(Duration(days: daysAgo))
      .copyWith(hour: h, minute: m, second: 0, millisecond: 0, microsecond: 0);

  static final List<Order> orders = [
    Order(
      id: 'ORD-2041',
      date: _d(0, 9, 15),
      productType: 'زجاج مزدوج',
      dimensions: '120 × 80 سم',
      totalMeters: 9.6,
      pricePerMeter: 45000,
      status: OrderStatus.inProduction,
      currentStage: ProductionStage.oven,
    ),
    Order(
      id: 'ORD-2038',
      date: _d(1, 12, 30),
      productType: 'زجاج ملون',
      dimensions: '100 × 60 سم',
      totalMeters: 6.0,
      pricePerMeter: 35000,
      status: OrderStatus.inProduction,
      currentStage: ProductionStage.coloring,
    ),
    Order(
      id: 'ORD-2031',
      date: _d(3, 11, 0),
      productType: 'زجاج لامينيت',
      dimensions: '200 × 90 سم',
      totalMeters: 18.0,
      pricePerMeter: 60000,
      status: OrderStatus.ready,
      currentStage: ProductionStage.readyForDelivery,
    ),
    Order(
      id: 'ORD-2025',
      date: _d(6, 14, 10),
      productType: 'زجاج ساندبلاست',
      dimensions: '150 × 70 سم',
      totalMeters: 10.5,
      pricePerMeter: 50000,
      status: OrderStatus.delivered,
      currentStage: ProductionStage.readyForDelivery,
    ),
    Order(
      id: 'ORD-2019',
      date: _d(9, 9, 45),
      productType: 'زجاج عادي',
      dimensions: '90 × 60 سم',
      totalMeters: 5.4,
      pricePerMeter: 30000,
      status: OrderStatus.delivered,
      currentStage: ProductionStage.readyForDelivery,
    ),
  ];

  static final List<AccountTransaction> transactions = [
    AccountTransaction(
      id: 'T-9001',
      date: _d(0, 9, 16),
      orderId: 'ORD-2041',
      amount: 432000,
      status: 'مفتوح',
      type: TransactionType.order,
      description: 'طلب جديد ORD-2041',
    ),
    AccountTransaction(
      id: 'T-9000',
      date: _d(1, 12, 35),
      orderId: 'ORD-2038',
      amount: 210000,
      status: 'مفتوح',
      type: TransactionType.invoice,
      description: 'فاتورة الطلب ORD-2038',
    ),
    AccountTransaction(
      id: 'T-8996',
      date: _d(2, 17, 0),
      amount: -250000,
      status: 'مكتمل',
      type: TransactionType.payment,
      description: 'دفعة نقدية',
    ),
    AccountTransaction(
      id: 'T-8990',
      date: _d(3, 11, 10),
      orderId: 'ORD-2031',
      amount: 1080000,
      status: 'مكتمل',
      type: TransactionType.invoice,
      description: 'فاتورة الطلب ORD-2031',
    ),
    AccountTransaction(
      id: 'T-8980',
      date: _d(5, 10, 5),
      amount: 75000,
      status: 'مكتمل',
      type: TransactionType.accountingEntry,
      description: 'قيد محاسبي - تسوية',
    ),
    AccountTransaction(
      id: 'T-8970',
      date: _d(6, 14, 12),
      orderId: 'ORD-2025',
      amount: 525000,
      status: 'مكتمل',
      type: TransactionType.invoice,
      description: 'فاتورة الطلب ORD-2025',
    ),
    AccountTransaction(
      id: 'T-8960',
      date: _d(7, 18, 0),
      amount: -500000,
      status: 'مكتمل',
      type: TransactionType.payment,
      description: 'تحويل بنكي',
    ),
  ];

  static AccountSummary accountSummary() {
    final balance = transactions.fold<double>(0, (s, t) => s + t.amount);
    final debt = transactions
        .where((t) => t.amount > 0 && t.status == 'مفتوح')
        .fold<double>(0, (s, t) => s + t.amount);
    return AccountSummary(
      totalIndebtedness: balance,
      executedIndebtedness: debt,
    );
  }

  // ------- Admin mocks -------
  static AdminMetrics adminMetrics() => const AdminMetrics(
    currentCash: 12500000,
    currentCashDollar: 91908.11,
    currentCashDinar: 161345304,
    todayMeters: 56.4,
    todayOrdersValue: 2840000,
    deliveredOrdersValue: 1520000,
    purchasesToday: 640000,
    currentInventoryValue: 18700000,
    expensesToday: 320000,
    revenuesToday: 2120000,
    productionDetailsTotal: 2288.9,
    productionDetailsDouble: 979.4,
    productionDetailsSingle: 1309.5,
    customerDebtsTotal: 7480000,
    customerDebtsExecuted: 5200000,
  );

  static List<CustomerRanking> topByOrders() => const [
    CustomerRanking(customerId: 'C-1001', name: 'أحمد محمد', value: 5200000),
    CustomerRanking(customerId: 'C-1004', name: 'شركة النور', value: 4100000),
    CustomerRanking(customerId: 'C-1008', name: 'مؤسسة الزجاج', value: 3650000),
    CustomerRanking(customerId: 'C-1012', name: 'كريم سامي', value: 2800000),
    CustomerRanking(customerId: 'C-1019', name: 'حسين علي', value: 2100000),
  ];

  static List<CustomerRanking> topByDebt() => const [
    CustomerRanking(customerId: 'C-1004', name: 'شركة النور', value: 2200000),
    CustomerRanking(customerId: 'C-1001', name: 'أحمد محمد', value: 1450000),
    CustomerRanking(customerId: 'C-1019', name: 'حسين علي', value: 1100000),
    CustomerRanking(customerId: 'C-1008', name: 'مؤسسة الزجاج', value: 950000),
    CustomerRanking(customerId: 'C-1012', name: 'كريم سامي', value: 780000),
  ];

  static List<RemanufactureRow> remanufactureRows() => [
    RemanufactureRow(
      orderId: 'ORD-2031',
      customerName: 'أحمد محمد',
      date: _d(3),
      reason: 'كسر أثناء النقل',
      meters: 2.4,
    ),
    RemanufactureRow(
      orderId: 'ORD-2019',
      customerName: 'كريم سامي',
      date: _d(8),
      reason: 'خطأ بالقياس',
      meters: 1.2,
    ),
    RemanufactureRow(
      orderId: 'ORD-2007',
      customerName: 'شركة النور',
      date: _d(12),
      reason: 'لون غير مطابق',
      meters: 3.0,
    ),
  ];

  static List<AdminCustomerDebtSummary> adminCustomerDebts() => const [
    AdminCustomerDebtSummary(
      codeCom: 1004,
      customerName: 'شركة النور',
      totalDebt: 2200000,
      settledAmount: 980000,
    ),
    AdminCustomerDebtSummary(
      codeCom: 1001,
      customerName: 'أحمد محمد',
      totalDebt: 1450000,
      settledAmount: 610000,
    ),
    AdminCustomerDebtSummary(
      codeCom: 1019,
      customerName: 'حسين علي',
      totalDebt: 1100000,
      settledAmount: 370000,
    ),
    AdminCustomerDebtSummary(
      codeCom: 1008,
      customerName: 'مؤسسة الزجاج',
      totalDebt: 950000,
      settledAmount: 420000,
    ),
    AdminCustomerDebtSummary(
      codeCom: 1012,
      customerName: 'كريم سامي',
      totalDebt: 780000,
      settledAmount: 300000,
    ),
  ];

  static List<AdminCashAccount> adminCashAccounts() => const [
    AdminCashAccount(name: 'الصندوق', amount: 5400000, currency: 'دينار'),
    AdminCashAccount(name: 'الصيرفة', amount: 3200000, currency: 'دينار'),
    AdminCashAccount(name: 'البنك', amount: 3900000, currency: 'دينار'),
  ];

  static AdminPeriodReport adminPeriodReport({
    required AdminPeriodReportType type,
    required DateTime from,
    required DateTime to,
  }) {
    final rows = switch (type) {
      AdminPeriodReportType.orders => [
        AdminPeriodReportEntry(
          date: _d(0, 9, 10),
          title: 'طلبية #2041',
          subtitle: 'شركة النور',
          amount: 760000,
        ),
        AdminPeriodReportEntry(
          date: _d(2, 10, 40),
          title: 'طلبية #2038',
          subtitle: 'أحمد محمد',
          amount: 540000,
        ),
        AdminPeriodReportEntry(
          date: _d(6, 11, 20),
          title: 'طلبية #2029',
          subtitle: 'مؤسسة الزجاج',
          amount: 690000,
        ),
      ],
      AdminPeriodReportType.personalWithdrawals => [
        AdminPeriodReportEntry(
          date: _d(1, 8, 40),
          title: 'سحب شخصي',
          subtitle: 'إدارة',
          amount: 300000,
        ),
        AdminPeriodReportEntry(
          date: _d(9, 13, 0),
          title: 'سحب شخصي',
          subtitle: 'إدارة',
          amount: 250000,
        ),
      ],
      AdminPeriodReportType.customerReceipts => [
        AdminPeriodReportEntry(
          date: _d(0, 12, 5),
          title: 'سند قبض #4501',
          subtitle: 'أحمد محمد',
          amount: 420000,
        ),
        AdminPeriodReportEntry(
          date: _d(3, 10, 30),
          title: 'سند قبض #4480',
          subtitle: 'شركة النور',
          amount: 510000,
        ),
        AdminPeriodReportEntry(
          date: _d(5, 9, 0),
          title: 'سند قبض #4462',
          subtitle: 'حسين علي',
          amount: 280000,
        ),
      ],
      AdminPeriodReportType.supplierPayments => [
        AdminPeriodReportEntry(
          date: _d(2, 14, 0),
          title: 'تسديد مجهز',
          subtitle: 'شركة المواد الاولية',
          amount: 470000,
        ),
        AdminPeriodReportEntry(
          date: _d(7, 9, 40),
          title: 'تسديد مجهز',
          subtitle: 'مجهز العبوات',
          amount: 360000,
        ),
      ],
      AdminPeriodReportType.productionDetails => [
        AdminPeriodReportEntry(
          date: _d(0, 15, 20),
          title: 'خط انتاج القاطع',
          subtitle: 'طلبية #2041',
          amount: 11.8,
        ),
        AdminPeriodReportEntry(
          date: _d(1, 10, 10),
          title: 'خط انتاج الفرن',
          subtitle: 'طلبية #2038',
          amount: 8.2,
        ),
        AdminPeriodReportEntry(
          date: _d(4, 11, 30),
          title: 'خط انتاج السليكون',
          subtitle: 'طلبية #2029',
          amount: 6.5,
        ),
      ],
    };

    final filtered = rows
        .where((row) => !row.date.isBefore(from) && !row.date.isAfter(to))
        .toList();
    final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);
    return AdminPeriodReport(total: total, entries: filtered);
  }
}
