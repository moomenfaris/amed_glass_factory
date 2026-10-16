class EmployeeWarehouseItem {
  final String code;
  final String materialName;
  final double meters;
  final int sheets;
  final double costPrice;
  final double length;
  final double width;
  final double total;

  const EmployeeWarehouseItem({
    required this.code,
    required this.materialName,
    required this.meters,
    required this.sheets,
    required this.costPrice,
    required this.length,
    required this.width,
    required this.total,
  });

  static double _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    final text = '${v ?? ''}'.replaceAll(',', '').trim();
    return double.tryParse(text) ?? 0;
  }

  static int _asInt(Object? v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}'.trim()) ?? 0;
  }

  factory EmployeeWarehouseItem.fromApi(Map<String, dynamic> json) {
    return EmployeeWarehouseItem(
      code: '${json['الكود'] ?? ''}'.trim(),
      materialName: '${json['اسم_المادة'] ?? ''}'.trim(),
      meters: _asDouble(json['عدد_الامتار']),
      sheets: _asInt(json['عدد_الالواح']),
      costPrice: _asDouble(json['سعر_الكلفة']),
      length: _asDouble(json['الطول']),
      width: _asDouble(json['العرض']),
      total: _asDouble(json['الاجمالي']),
    );
  }
}
