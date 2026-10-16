/// A single production line item returned by `/api/order-production/get`.
///
/// The API returns Arabic-keyed objects describing each piece/spec of an
/// order and which production stages it must pass through.
class OrderProductionItem {
  final String? customerName; // اسم الزبون
  final String? orderNumber; // رقم الطلبية
  final String? projectName; // اسم المشروع
  final String specs; // المواصفات
  final double length; // الطول
  final double width; // العرض
  final double length2; // الطول2
  final double width2; // العرض2
  final double meters; // عدد الامتار
  final int orderPieces; // عدد قطع الطلبية
  final int? deliveredPieces; // عدد القطع المسلمة (nullable)
  final double remainingMeters; // عدد الامتار المتبقية
  final int remainingPieces; // عدد القطع المتبقية
  final String status; // الحالة

  // Production stage flags (0/1).
  final bool cut; // قص
  final bool grinding; // روداج
  final bool dye; // صبغ
  final bool oven; // فرن
  final bool doubleGlazing; // دبل
  final bool silicone; // سيليكون
  final bool sandBlast; // رمل
  final bool laminate; // لامنيت

  const OrderProductionItem({
    required this.customerName,
    required this.orderNumber,
    required this.projectName,
    required this.specs,
    required this.length,
    required this.width,
    required this.length2,
    required this.width2,
    required this.meters,
    required this.orderPieces,
    required this.deliveredPieces,
    required this.remainingMeters,
    required this.remainingPieces,
    required this.status,
    required this.cut,
    required this.grinding,
    required this.dye,
    required this.oven,
    required this.doubleGlazing,
    required this.silicone,
    required this.sandBlast,
    required this.laminate,
  });

  factory OrderProductionItem.fromApi(Map<String, dynamic> j) {
    final customerName = _asString(
      _pick(j, ['اسم_الزبون', 'اسم الزبون']),
    ).trim();
    final orderNumber = _asString(
      _pick(j, ['رقم_الطلبية', 'رقم الطلبية']),
    ).trim();
    final projectName = _asString(
      _pick(j, ['اسم_المشروع', 'اسم المشروع']),
    ).trim();
    return OrderProductionItem(
      customerName: customerName.isEmpty ? null : customerName,
      orderNumber: orderNumber.isEmpty ? null : orderNumber,
      projectName: projectName.isEmpty ? null : projectName,
      specs: _asString(_pick(j, ['المواصفات'])).trim(),
      length: _asDouble(_pick(j, ['الطول'])),
      width: _asDouble(_pick(j, ['العرض'])),
      length2: _asDouble(_pick(j, ['الطول2'])),
      width2: _asDouble(_pick(j, ['العرض2'])),
      meters: _asDouble(_pick(j, ['عدد_الامتار', 'عدد الامتار'])),
      orderPieces:
          _asInt(_pick(j, ['عدد_قطع_الطلبية', 'عدد قطع الطلبية'])) ?? 0,
      deliveredPieces: _asInt(
        _pick(j, ['عدد_القطع_المسلمة', 'عدد القطع المسلمة']),
      ),
      remainingMeters: _asDouble(
        _pick(j, ['عدد_الامتار_المتبقية', 'عدد الامتار المتبقية']),
      ),
      remainingPieces:
          _asInt(_pick(j, ['عدد_القطع_المتبقية', 'عدد القطع المتبقية'])) ?? 0,
      status: _asString(_pick(j, ['الحالة'])).trim(),
      cut: _asBool(_pick(j, ['قص'])),
      grinding: _asBool(_pick(j, ['روداج'])),
      dye: _asBool(_pick(j, ['صبغ'])),
      oven: _asBool(_pick(j, ['فرن'])),
      doubleGlazing: _asBool(_pick(j, ['دبل'])),
      silicone: _asBool(_pick(j, ['سيليكون'])),
      sandBlast: _asBool(_pick(j, ['رمل'])),
      laminate: _asBool(_pick(j, ['لامنيت'])),
    );
  }

  static Object? _pick(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      if (j.containsKey(k)) return j[k];
    }
    return null;
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

  static bool _asBool(Object? v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    return s == '1' || s == 'true';
  }
}
