import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_data.dart';
import '../models/admin_metrics.dart';
import '../models/admin_reporting.dart';

abstract class AdminRepository {
  Future<AdminMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
  });
  Future<List<AdminCustomerDebtSummary>> fetchCustomerDebts();
  Future<AdminCustomerDebtTotals> fetchCustomerDebtTotals();
  Future<AdminExpensesReport> fetchExpensesReport({
    required DateTime from,
    required DateTime to,
  });
  Future<List<AdminCashAccount>> fetchCashAccounts();
  Future<AdminPeriodReport> fetchPeriodReport({
    required AdminPeriodReportType type,
    required DateTime from,
    required DateTime to,
  });
  Future<List<CustomerRanking>> topByOrders({DateTime? from, DateTime? to});
  Future<List<CustomerRanking>> topByDebt({DateTime? from, DateTime? to});
  Future<List<RemanufactureRow>> remanufactureReport({
    DateTime? from,
    DateTime? to,
  });
}

class MockAdminRepository implements AdminRepository {
  @override
  Future<AdminMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockData.adminMetrics();
  }

  @override
  Future<List<AdminCustomerDebtSummary>> fetchCustomerDebts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.adminCustomerDebts();
  }

  @override
  Future<AdminCustomerDebtTotals> fetchCustomerDebtTotals() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final rows = MockData.adminCustomerDebts();
    final total = rows.fold<double>(0, (sum, row) => sum + row.totalDebt);
    final executed = rows.fold<double>(
      0,
      (sum, row) => sum + row.settledAmount,
    );
    return AdminCustomerDebtTotals(totalDebt: total, executedDebt: executed);
  }

  @override
  Future<AdminExpensesReport> fetchExpensesReport({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    const items = <AdminExpenseItem>[
      AdminExpenseItem(title: 'رواتب الموظفين', amount: 625000),
      AdminExpenseItem(title: 'وقود', amount: 250000),
      AdminExpenseItem(title: 'كهرباء', amount: 187500),
      AdminExpenseItem(title: 'صيانة', amount: 125000),
      AdminExpenseItem(title: 'أخرى', amount: 125000),
    ];
    final total = items.fold<double>(0, (s, e) => s + e.amount);
    return AdminExpensesReport(total: total, items: items);
  }

  @override
  Future<List<AdminCashAccount>> fetchCashAccounts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.adminCashAccounts();
  }

  @override
  Future<AdminPeriodReport> fetchPeriodReport({
    required AdminPeriodReportType type,
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.adminPeriodReport(type: type, from: from, to: to);
  }

  @override
  Future<List<CustomerRanking>> topByOrders({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.topByOrders();
  }

  @override
  Future<List<CustomerRanking>> topByDebt({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockData.topByDebt();
  }

  @override
  Future<List<RemanufactureRow>> remanufactureReport({
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final rows = MockData.remanufactureRows();
    if (from == null && to == null) return rows;
    return rows.where((r) {
      final afterFrom = from == null || !r.date.isBefore(from);
      final beforeTo = to == null || !r.date.isAfter(to);
      return afterFrom && beforeTo;
    }).toList();
  }
}

class ApiAdminRepository extends MockAdminRepository {
  static const String _baseUrl = 'https://amed.ideavsion.online:448';
  static const String _apiKey = '9a893844-18c3-4f62-acf0-89944e1093d6';

  final Dio _dio;

  ApiAdminRepository({Dio? dio})
    : _dio =
          dio ??
          (Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'x-api-key': _apiKey,
                'Content-Type': 'application/json',
              },
              responseType: ResponseType.json,
            ),
          )..interceptors.addAll(_defaultInterceptors()));

  static List<Interceptor> _defaultInterceptors() {
    if (!kDebugMode) return const [];
    return [
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
      ),
    ];
  }

  static double _asDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  static int _asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}'.trim()) ?? 0;
  }

  static DateTime? _asDate(Object? v) {
    final text = '${v ?? ''}'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return DateTime.tryParse(text);
  }

  static Object? _pick(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return json[key];
    }
    return null;
  }

  static String _asString(Object? v) => '${v ?? ''}'.trim();

  static String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Future<AdminMetrics> fetchMetrics({
    required DateTime from,
    required DateTime to,
  }) async {
    // Keep existing dashboard sources and override requested metrics
    // from API endpoints used by the admin home page.
    final fallback = MockData.adminMetrics();
    final expensesPayload = {
      'dateFrom': _fmtDate(from),
      'dateTo': _fmtDate(to),
    };
    final ordersPayload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};
    final debtsPayload = {'date1': '2026-07-05', 'date2': '2026-07-05'};
    final receiptsPayload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};
    final cashPayload = {'date1': '2026-07-05', 'date2': '2026-07-05'};
    final withdrawalsPayload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};
    final supplierPaymentsPayload = {
      'date1': _fmtDate(from),
      'date2': _fmtDate(to),
    };
    final productionDetailsPayload = {
      'dateFrom': _fmtDate(from),
      'dateTo': _fmtDate(to),
    };

    try {
      final expensesRes = await _dio.post(
        '/api/Expenses/Totals',
        data: expensesPayload,
      );
      final ordersRes = await _dio.post(
        '/api/Orders/Total',
        data: ordersPayload,
      );
      final debtsRes = await _dio.post(
        '/api/CustomerDebt/GetTotals',
        data: debtsPayload,
      );
      final receiptsRes = await _dio.post(
        '/api/Receipt/Total',
        data: receiptsPayload,
      );
      final cashRes = await _dio.post(
        '/api/CashBoxes/Totals',
        data: cashPayload,
      );
      final withdrawalsRes = await _dio.post(
        '/api/AccountMovement/Total',
        data: withdrawalsPayload,
      );
      final supplierPaymentsRes = await _dio.post(
        '/api/SupplierPayment/Total',
        data: supplierPaymentsPayload,
      );
      final productionDetailsRes = await _dio.post(
        '/api/order-production/Details',
        data: productionDetailsPayload,
      );

      final expensesBodyRaw = expensesRes.data;
      final ordersBodyRaw = ordersRes.data;
      final debtsBodyRaw = debtsRes.data;
      final receiptsBodyRaw = receiptsRes.data;
      final cashBodyRaw = cashRes.data;
      final withdrawalsBodyRaw = withdrawalsRes.data;
      final supplierPaymentsBodyRaw = supplierPaymentsRes.data;
      final productionDetailsBodyRaw = productionDetailsRes.data;
      if (expensesBodyRaw is! Map ||
          ordersBodyRaw is! Map ||
          debtsBodyRaw is! Map ||
          receiptsBodyRaw is! Map ||
          cashBodyRaw is! Map ||
          withdrawalsBodyRaw is! Map ||
          supplierPaymentsBodyRaw is! Map ||
          productionDetailsBodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final expensesBody = Map<String, dynamic>.from(expensesBodyRaw);
      final ordersBody = Map<String, dynamic>.from(ordersBodyRaw);
      final debtsBody = Map<String, dynamic>.from(debtsBodyRaw);
      final receiptsBody = Map<String, dynamic>.from(receiptsBodyRaw);
      final cashBody = Map<String, dynamic>.from(cashBodyRaw);
      final withdrawalsBody = Map<String, dynamic>.from(withdrawalsBodyRaw);
      final supplierPaymentsBody = Map<String, dynamic>.from(
        supplierPaymentsBodyRaw,
      );
      final productionDetailsBody = Map<String, dynamic>.from(
        productionDetailsBodyRaw,
      );
      if (expensesBody['success'] != true) {
        final msg = (expensesBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع المصاريف',
        );
      }
      if (ordersBody['success'] != true) {
        final msg = (ordersBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع الطلبيات',
        );
      }
      if (debtsBody['success'] != true) {
        final msg = (debtsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع الديون',
        );
      }
      if (receiptsBody['success'] != true) {
        final msg = (receiptsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع المقبوضات',
        );
      }
      if (cashBody['success'] != true) {
        final msg = (cashBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع النقد',
        );
      }
      if (withdrawalsBody['success'] != true) {
        final msg = (withdrawalsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع مسحوبات الشركاء',
        );
      }
      if (supplierPaymentsBody['success'] != true) {
        final msg = (supplierPaymentsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجموع التسديدات',
        );
      }
      if (productionDetailsBody['success'] != true) {
        final msg = (productionDetailsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب تفاصيل الانتاج',
        );
      }

      final expensesData = (expensesBody['data'] is Map)
          ? Map<String, dynamic>.from(expensesBody['data'] as Map)
          : <String, dynamic>{};
      final ordersData = (ordersBody['data'] is Map)
          ? Map<String, dynamic>.from(ordersBody['data'] as Map)
          : <String, dynamic>{};
      final debtsData = (debtsBody['data'] is Map)
          ? Map<String, dynamic>.from(debtsBody['data'] as Map)
          : <String, dynamic>{};
      final receiptsData = (receiptsBody['data'] is Map)
          ? Map<String, dynamic>.from(receiptsBody['data'] as Map)
          : <String, dynamic>{};
      final cashData = (cashBody['data'] as List?) ?? const [];
      final withdrawalsData = (withdrawalsBody['data'] is Map)
          ? Map<String, dynamic>.from(withdrawalsBody['data'] as Map)
          : <String, dynamic>{};
      final supplierPaymentsData = (supplierPaymentsBody['data'] is Map)
          ? Map<String, dynamic>.from(supplierPaymentsBody['data'] as Map)
          : <String, dynamic>{};
      final productionDetailsData =
          (productionDetailsBody['data'] as List?) ?? const [];

      final expenses = _asDouble(expensesData['المصاريف']);
      final ordersTotal = _asDouble(ordersData['مبلغ_الفاتورة']);
      final ordersMeters = _asDouble(ordersData['عدد_الامتار']);
      final debtsTotal = _asDouble(debtsData['اجمالي_المديونية']);
      final debtsExecuted = _asDouble(debtsData['المديونية_المنفذة']);
      final receiptsTotal = _asDouble(receiptsData['المبلغ']);
      final partnersWithdrawals = _asDouble(withdrawalsData['سحب']);
      final supplierPaymentsTotal = _asDouble(supplierPaymentsData['المبلغ']);
      final productionDetailsTotal = productionDetailsData
          .whereType<Map>()
          .map((row) => _asDouble(row['اجمالي عدد الامتار']))
          .fold<double>(0, (sum, value) => sum + value);
      var productionDetailsDouble = 0.0;
      var productionDetailsSingle = 0.0;
      for (final row in productionDetailsData.whereType<Map>()) {
        final item = Map<String, dynamic>.from(row);
        final orderType = _asString(item['نوع الطلبية']).toLowerCase();
        final meters = _asDouble(item['اجمالي عدد الامتار']);
        if (orderType == 'double') {
          productionDetailsDouble += meters;
        } else if (orderType == 'single') {
          productionDetailsSingle += meters;
        }
      }

      var cashDollar = 0.0;
      var cashDinar = 0.0;
      for (final row in cashData.whereType<Map>()) {
        final item = Map<String, dynamic>.from(row);
        final currency = _asString(item['العملة']).toLowerCase();
        final balance = _asDouble(item['الرصيد']);
        if (currency.contains('دولار') || currency == 'usd') {
          cashDollar += balance;
        } else if (currency.contains('دينار') || currency == 'iqd') {
          cashDinar += balance;
        }
      }

      return AdminMetrics(
        currentCash: cashDollar,
        currentCashDollar: cashDollar,
        currentCashDinar: cashDinar,
        todayMeters: ordersMeters,
        todayOrdersValue: ordersTotal,
        deliveredOrdersValue: supplierPaymentsTotal,
        purchasesToday: partnersWithdrawals,
        currentInventoryValue: fallback.currentInventoryValue,
        expensesToday: expenses,
        revenuesToday: receiptsTotal,
        productionDetailsTotal: productionDetailsTotal,
        productionDetailsDouble: productionDetailsDouble,
        productionDetailsSingle: productionDetailsSingle,
        customerDebtsTotal: debtsTotal,
        customerDebtsExecuted: debtsExecuted,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة مؤشرات الصفحة الرئيسية: $e');
    }
  }

  @override
  Future<List<AdminCustomerDebtSummary>> fetchCustomerDebts() async {
    try {
      final res = await _dio.post('/api/CustomerDebt/Get', data: const {});

      final bodyRaw = res.data;
      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب ديون الزبائن',
        );
      }

      final raw = (body['data'] as List?) ?? const [];
      return raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        return AdminCustomerDebtSummary(
          codeCom: _asInt(item['id']),
          customerName: '${item['اسم_الزبون'] ?? ''}'.trim(),
          settledAmount: _asDouble(item['المسلم']),
          totalDebt: _asDouble(item['الاجمالي']),
          lastSettlementDate: _asDate(item['تاريخ_اخر_تسديد']),
          lastSettlementAmount: item['اخر_تسديد'] == null
              ? null
              : _asDouble(item['اخر_تسديد']),
        );
      }).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة ديون الزبائن: $e');
    }
  }

  @override
  Future<AdminCustomerDebtTotals> fetchCustomerDebtTotals() async {
    try {
      final res = await _dio.post(
        '/api/CustomerDebt/GetTotals',
        data: const {},
      );

      final bodyRaw = res.data;
      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مجاميع الديون',
        );
      }

      final data = (body['data'] is Map)
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};

      return AdminCustomerDebtTotals(
        totalDebt: _asDouble(data['اجمالي_المديونية']),
        executedDebt: _asDouble(data['المديونية_المنفذة']),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة مجاميع الديون: $e');
    }
  }

  @override
  Future<AdminExpensesReport> fetchExpensesReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'dateFrom': _fmtDate(from), 'dateTo': _fmtDate(to)};

    try {
      final totalsRes = await _dio.post('/api/Expenses/Totals', data: payload);
      final listRes = await _dio.post('/api/Expenses/Get', data: payload);

      final totalsBodyRaw = totalsRes.data;
      final listBodyRaw = listRes.data;

      if (totalsBodyRaw is! Map || listBodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final totalsBody = Map<String, dynamic>.from(totalsBodyRaw);
      final listBody = Map<String, dynamic>.from(listBodyRaw);

      if (totalsBody['success'] != true) {
        final msg = (totalsBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب اجمالي المصروفات',
        );
      }
      if (listBody['success'] != true) {
        final msg = (listBody['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب قائمة المصروفات',
        );
      }

      final totalsData = (totalsBody['data'] is Map)
          ? Map<String, dynamic>.from(totalsBody['data'] as Map)
          : <String, dynamic>{};

      final itemsRaw = (listBody['data'] as List?) ?? const [];
      final items = itemsRaw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        return AdminExpenseItem(
          title: '${item['المصروف'] ?? ''}'.trim(),
          amount: _asDouble(item['المبلغ']),
          details: '${item['التفاصيل'] ?? ''}'.trim(),
        );
      }).toList();

      items.sort((a, b) => b.amount.compareTo(a.amount));

      return AdminExpensesReport(
        total: _asDouble(totalsData['المصاريف']),
        items: items,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات المصروفات: $e');
    }
  }

  @override
  Future<List<AdminCashAccount>> fetchCashAccounts() async {
    try {
      final res = await _dio.post('/api/CashBoxes/Get', data: const {});

      final bodyRaw = res.data;
      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب حسابات النقد',
        );
      }

      final raw = (body['data'] as List?) ?? const [];
      return raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        return AdminCashAccount(
          name: '${item['الصندوق'] ?? ''}'.trim(),
          amount: _asDouble(item['الرصيد']),
          currency: '${item['العملة'] ?? ''}'.trim(),
        );
      }).toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات الصناديق: $e');
    }
  }

  @override
  Future<AdminPeriodReport> fetchPeriodReport({
    required AdminPeriodReportType type,
    required DateTime from,
    required DateTime to,
  }) async {
    if (type == AdminPeriodReportType.orders) {
      return _fetchOrdersReport(from: from, to: to);
    }
    if (type == AdminPeriodReportType.customerReceipts) {
      return _fetchCustomerReceiptsReport(from: from, to: to);
    }
    if (type == AdminPeriodReportType.supplierPayments) {
      return _fetchSupplierPaymentsReport(from: from, to: to);
    }
    if (type == AdminPeriodReportType.personalWithdrawals) {
      return _fetchPersonalWithdrawalsReport(from: from, to: to);
    }
    if (type == AdminPeriodReportType.productionDetails) {
      return _fetchProductionDetailsReport(from: from, to: to);
    }
    return super.fetchPeriodReport(type: type, from: from, to: to);
  }

  Future<AdminPeriodReport> _fetchProductionDetailsReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'dateFrom': _fmtDate(from), 'dateTo': _fmtDate(to)};

    try {
      final res = await _dio.post(
        '/api/order-production/DetailsSeeMore',
        data: payload,
        options: Options(headers: {'x-api-key': _apiKey}),
      );
      final bodyRaw = res.data;

      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب تفاصيل الانتاج',
        );
      }

      final headerRaw = (body['header'] as List?) ?? const [];
      final headerEntries = headerRaw.whereType<Map>().map((row) {
        final item = Map<String, dynamic>.from(row);
        return AdminPeriodHeaderEntry(
          title: _asString(_pick(item, const ['نوع الطلبية', 'type', 'label'])),
          amount: _asDouble(
            _pick(item, const [
              'اجمالي عدد الامتار',
              'اجمالي_عدد_الامتار',
              'عدد الامتار',
              'total',
            ]),
          ),
        );
      }).toList();

      final raw = (body['data'] as List?) ?? const [];
      final entries = raw.whereType<Map>().map((row) {
        final item = Map<String, dynamic>.from(row);
        final categoryName = _asString(
          _pick(item, const ['الفئة', 'category', 'name', 'title']),
        );
        final amount = _asDouble(
          _pick(item, const [
            'عدد_الامتار',
            'عدد الامتار',
            'عدد الأمتار',
            'meters',
            'amount',
          ]),
        );

        return AdminPeriodReportEntry(
          date: from,
          title: categoryName.isNotEmpty ? categoryName : 'غير مصنف',
          subtitle: null,
          amount: amount,
        );
      }).toList();

      final totalFromHeader = headerEntries.fold<double>(
        0,
        (sum, row) => sum + row.amount,
      );
      final totalFromEntries = entries.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );

      return AdminPeriodReport(
        total: totalFromHeader > 0 ? totalFromHeader : totalFromEntries,
        entries: entries,
        headerEntries: headerEntries,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات تفاصيل الانتاج: $e');
    }
  }

  Future<AdminPeriodReport> _fetchOrdersReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};

    try {
      final res = await _dio.post('/api/Orders/Get', data: payload);
      final bodyRaw = res.data;

      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب بيانات الطلبيات',
        );
      }

      final header = (body['header'] is Map)
          ? Map<String, dynamic>.from(body['header'] as Map)
          : <String, dynamic>{};

      final raw = (body['data'] as List?) ?? const [];
      final entries = raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        final orderNo = _asInt(item['رقم_الطلبية']);
        final customer = '${item['اسم_الزبون'] ?? ''}'.trim();
        final project = '${item['اسم_المشروع'] ?? ''}'.trim();
        final invoiceAmount = _asDouble(item['مبلغ_الفاتورة']);
        final orderDate = _asDate(item['تاريخ_الطلبية']) ?? from;

        final subtitleParts = <String>[];
        if (customer.isNotEmpty) subtitleParts.add(customer);
        if (project.isNotEmpty && project.toLowerCase() != 'null') {
          subtitleParts.add(project);
        }

        return AdminPeriodReportEntry(
          date: orderDate,
          title: orderNo > 0 ? 'طلبية #$orderNo' : 'طلبية',
          subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
          amount: invoiceAmount,
        );
      }).toList();

      final totalFromHeader = _asDouble(header['مجموع_الفواتير']);
      final totalFromEntries = entries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return AdminPeriodReport(
        total: totalFromHeader > 0 ? totalFromHeader : totalFromEntries,
        entries: entries,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات الطلبيات: $e');
    }
  }

  Future<AdminPeriodReport> _fetchPersonalWithdrawalsReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};

    try {
      final res = await _dio.post('/api/AccountMovement/Get', data: payload);
      final bodyRaw = res.data;

      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مسحوبات الشركات',
        );
      }

      final header = (body['header'] is Map)
          ? Map<String, dynamic>.from(body['header'] as Map)
          : <String, dynamic>{};

      final raw = (body['data'] as List?) ?? const [];
      final entries = raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        final orderNo = _asInt(item['رقم_الطلبية']);
        final details = '${item['التفاصيل'] ?? ''}'.trim();
        final amount = _asDouble(item['سحب']);
        final movementDate =
            _asDate(item['التاريخ']) ?? _asDate(item['date']) ?? from;

        return AdminPeriodReportEntry(
          date: movementDate,
          title: orderNo > 0 ? 'وصل صرف #$orderNo' : 'وصل صرف',
          subtitle: details.isEmpty ? null : details,
          amount: amount,
        );
      }).toList();

      final totalFromHeader = _asDouble(header['مجموع_السحب']);
      final totalFromEntries = entries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return AdminPeriodReport(
        total: totalFromHeader > 0 ? totalFromHeader : totalFromEntries,
        entries: entries,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات مسحوبات الشركات: $e');
    }
  }

  Future<AdminPeriodReport> _fetchCustomerReceiptsReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};

    try {
      final res = await _dio.post('/api/Receipt/Get', data: payload);
      final bodyRaw = res.data;

      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب مقبوضات الزبائن',
        );
      }

      final header = (body['header'] is Map)
          ? Map<String, dynamic>.from(body['header'] as Map)
          : <String, dynamic>{};

      final raw = (body['data'] as List?) ?? const [];
      final entries = raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        final receiptNo = _asInt(item['رقم_الوصل']);
        final customer = '${item['اسم_الزبون'] ?? ''}'.trim();
        final amount = _asDouble(item['المبلغ']);
        final receiptDate = _asDate(item['التاريخ']) ?? from;

        return AdminPeriodReportEntry(
          date: receiptDate,
          title: receiptNo > 0 ? 'وصل قبض #$receiptNo' : 'وصل قبض',
          subtitle: customer.isEmpty ? null : customer,
          amount: amount,
        );
      }).toList();

      final totalFromHeader = _asDouble(header['مجموع_المبلغ']);
      final totalFromEntries = entries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return AdminPeriodReport(
        total: totalFromHeader > 0 ? totalFromHeader : totalFromEntries,
        entries: entries,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات مقبوضات الزبائن: $e');
    }
  }

  Future<AdminPeriodReport> _fetchSupplierPaymentsReport({
    required DateTime from,
    required DateTime to,
  }) async {
    final payload = {'date1': _fmtDate(from), 'date2': _fmtDate(to)};

    try {
      final res = await _dio.post('/api/SupplierPayment/Get', data: payload);
      final bodyRaw = res.data;

      if (bodyRaw is! Map) {
        throw const ServerFailure('استجابة غير صالحة من الخادم');
      }

      final body = Map<String, dynamic>.from(bodyRaw);
      if (body['success'] != true) {
        final msg = (body['message'] as String?)?.trim();
        throw ServerFailure(
          msg?.isNotEmpty == true ? msg! : 'تعذر جلب تسديدات المجهزين',
        );
      }

      final header = (body['header'] is Map)
          ? Map<String, dynamic>.from(body['header'] as Map)
          : <String, dynamic>{};

      final raw = (body['data'] as List?) ?? const [];
      final entries = raw.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        final receiptNo = _asInt(item['رقم_الوصل']);
        final supplier = '${item['اسم_المجهز'] ?? ''}'.trim();
        final amount = _asDouble(item['المبلغ']);
        final paymentDate = _asDate(item['التاريخ']) ?? from;

        return AdminPeriodReportEntry(
          date: paymentDate,
          title: receiptNo > 0 ? 'وصل تسديد #$receiptNo' : 'تسديد مجهز',
          subtitle: supplier.isEmpty ? null : supplier,
          amount: amount,
        );
      }).toList();

      final totalFromHeader = _asDouble(header['مجموع_المبلغ']);
      final totalFromEntries = entries.fold<double>(
        0,
        (sum, e) => sum + e.amount,
      );

      return AdminPeriodReport(
        total: totalFromHeader > 0 ? totalFromHeader : totalFromEntries,
        entries: entries,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkFailure('انتهت مهلة الاتصال بالخادم');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('تعذر الاتصال بالخادم، تحقق من الإنترنت');
      }
      final code = e.response?.statusCode;
      final msg = (e.response?.data is Map)
          ? (e.response!.data['message']?.toString())
          : null;
      throw ServerFailure(msg ?? 'خطأ في الخادم', code: code);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('تعذر قراءة بيانات تسديدات المجهزين: $e');
    }
  }
}
