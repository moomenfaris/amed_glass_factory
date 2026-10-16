class Invoice {
  final InvoiceHeader? header;
  final List<InvoiceItem> items;

  const Invoice({required this.header, required this.items});

  bool get isEmpty => (header == null || header!.isEmpty) && items.isEmpty;

  int get itemCount => items.length;

  double get totalArea => items.fold<double>(0, (sum, e) => sum + e.meterCount);

  double get totalAmount {
    if (header?.invoiceAmount != null) return header!.invoiceAmount!;
    return items.fold<double>(0, (sum, e) => sum + e.total);
  }

  factory Invoice.fromApi(Map<String, dynamic> j) {
    final rawHeader = j['header'];
    final rawItems = (j['items'] as List?) ?? const [];

    return Invoice(
      header: rawHeader is Map
          ? InvoiceHeader.fromApi(Map<String, dynamic>.from(rawHeader))
          : null,
      items: rawItems
          .whereType<Map>()
          .map((e) => InvoiceItem.fromApi(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class InvoiceHeader {
  final DateTime? dateOrder;
  final String? projectName;
  final String? customerCode;
  final double? invoiceAmount;
  final String? notes;
  final String? reference;
  final String? status;

  const InvoiceHeader({
    this.dateOrder,
    this.projectName,
    this.customerCode,
    this.invoiceAmount,
    this.notes,
    this.reference,
    this.status,
  });

  bool get isEmpty =>
      (projectName == null || projectName!.trim().isEmpty) &&
      invoiceAmount == null &&
      dateOrder == null;

  factory InvoiceHeader.fromApi(Map<String, dynamic> j) {
    return InvoiceHeader(
      dateOrder: _toDate(j['dateOrder']),
      projectName: _toStringOrNull(j['projectName']),
      customerCode: _toStringOrNull(j['customerCode']),
      invoiceAmount: _toDoubleOrNull(j['invoiceAmount']),
      notes: _toStringOrNull(j['notes']),
      reference: _toStringOrNull(j['noUpdate']),
      status: _toStringOrNull(j['status'] ?? j['state'] ?? j['حالة']),
    );
  }
}

class InvoiceItem {
  final String specification;
  final double glassHeight;
  final double glassWidth;
  final double glassHeight2;
  final double glassWidth2;
  final double aluminumHeight;
  final double aluminumWidth;
  final double meterCount;
  final int piecesCount;
  final double meterPrice;
  final double total;
  final String notes;
  final String code;

  const InvoiceItem({
    required this.specification,
    required this.glassHeight,
    required this.glassWidth,
    required this.glassHeight2,
    required this.glassWidth2,
    required this.aluminumHeight,
    required this.aluminumWidth,
    required this.meterCount,
    required this.piecesCount,
    required this.meterPrice,
    required this.total,
    required this.notes,
    required this.code,
  });

  bool get hasSecondGlass => glassHeight2 > 0 || glassWidth2 > 0;
  bool get hasAluminum => aluminumHeight > 0 || aluminumWidth > 0;

  factory InvoiceItem.fromApi(Map<String, dynamic> j) {
    return InvoiceItem(
      specification: _toStringOrNull(j['specification'])?.trim() ?? '',
      glassHeight: _toDouble(j['glassHeight']),
      glassWidth: _toDouble(j['glassWidth']),
      glassHeight2: _toDouble(j['glassHeight2']),
      glassWidth2: _toDouble(j['glassWidth2']),
      aluminumHeight: _toDouble(j['aluminumHeight']),
      aluminumWidth: _toDouble(j['aluminumWidth']),
      meterCount: _toDouble(j['meterCount']),
      piecesCount: _toDouble(j['piecesCount']).round(),
      meterPrice: _toDouble(j['meterPrice']),
      total: _toDouble(j['total']),
      notes: _toStringOrNull(j['notes'])?.trim() ?? '',
      code: _toStringOrNull(j['customerCode'])?.trim() ?? '',
    );
  }
}

double _toDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0;
  return 0;
}

double? _toDoubleOrNull(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', ''));
  return null;
}

String? _toStringOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.trim().isEmpty ? null : s;
}

DateTime? _toDate(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
