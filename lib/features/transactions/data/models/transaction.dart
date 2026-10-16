enum TransactionType { order, invoice, payment, accountingEntry }

extension TransactionTypeX on TransactionType {
  String get arabicLabel {
    switch (this) {
      case TransactionType.order:
        return 'طلب';
      case TransactionType.invoice:
        return 'فاتورة';
      case TransactionType.payment:
        return 'دفعة';
      case TransactionType.accountingEntry:
        return 'قيد محاسبي';
    }
  }
}

class AccountTransaction {
  final String id;
  final DateTime date;
  final String? orderId;
  final double amount; // positive = debit on customer, negative = credit
  final String status;
  final TransactionType type;
  final String description;

  // Optional fields populated when data comes from the movements API.
  final int? movementNumber;
  final double? debit;
  final double? credit;
  final double? balance;
  final DateTime? deliveryDate;
  final String? projectName;
  final String? notes;

  const AccountTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
    required this.description,
    this.orderId,
    this.movementNumber,
    this.debit,
    this.credit,
    this.balance,
    this.deliveryDate,
    this.projectName,
    this.notes,
  });

  factory AccountTransaction.fromJson(Map<String, dynamic> j) =>
      AccountTransaction(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        orderId: j['orderId'] as String?,
        amount: (j['amount'] as num).toDouble(),
        status: j['status'] as String,
        type: TransactionType.values.byName(j['type'] as String),
        description: j['description'] as String,
      );

  /// Parses an item from the `/api/movment/get` response (Arabic keys).
  factory AccountTransaction.fromApi(Map<String, dynamic> j) {
    final desc = _asString(j['البيان']).trim();
    final movNum = _asInt(j['رقم الحركة']);
    final debit = _asDouble(j['المدين']);
    final credit = _asDouble(j['الدائن']);
    final balance = _asDouble(j['الرصيد']);
    final dateStr = _asString(j['التاريخ']);
    final delivStr = _asString(j['تاريخ التسليم']).trim();
    final project = _asString(j['اسم المشروع']).trim();
    final notes = _asString(j['الملاحظات']).trim();

    return AccountTransaction(
      id: movNum?.toString() ?? '${dateStr}_$desc',
      date: DateTime.tryParse(dateStr) ?? DateTime.now(),
      amount: debit - credit,
      status: '',
      type: _typeFromBayan(desc),
      description: desc,
      movementNumber: movNum,
      debit: debit,
      credit: credit,
      balance: balance,
      deliveryDate: delivStr.isEmpty ? null : DateTime.tryParse(delivStr),
      projectName: project.isEmpty ? null : project,
      notes: notes.isEmpty ? null : notes,
    );
  }

  static String _asString(Object? v) => v?.toString() ?? '';

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static double _asDouble(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '').trim();
    return double.tryParse(s) ?? 0;
  }

  static TransactionType _typeFromBayan(String s) {
    if (s.contains('بيع') || s.contains('فاتورة')) {
      return TransactionType.invoice;
    }
    if (s.contains('قبض') || s.contains('دفع')) {
      return TransactionType.payment;
    }
    if (s.contains('طلب')) {
      return TransactionType.order;
    }
    return TransactionType.accountingEntry;
  }
}
