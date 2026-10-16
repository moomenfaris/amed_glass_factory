enum ProductionStage {
  cutting,
  coloring,
  oven,
  doubleGlass,
  silicone,
  sandblast,
  laminated,
  readyForDelivery,
}

extension ProductionStageX on ProductionStage {
  String get arabicLabel {
    switch (this) {
      case ProductionStage.cutting:
        return 'التقطيع';
      case ProductionStage.coloring:
        return 'التلوين';
      case ProductionStage.oven:
        return 'الفرن';
      case ProductionStage.doubleGlass:
        return 'الزجاج المزدوج';
      case ProductionStage.silicone:
        return 'السيليكون';
      case ProductionStage.sandblast:
        return 'الرمل (ساندبلاست)';
      case ProductionStage.laminated:
        return 'اللامينيت';
      case ProductionStage.readyForDelivery:
        return 'جاهز للتسليم';
    }
  }
}

enum OrderStatus { pending, inProduction, ready, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  String get arabicLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد الانتظار';
      case OrderStatus.inProduction:
        return 'قيد الإنتاج';
      case OrderStatus.ready:
        return 'جاهز';
      case OrderStatus.delivered:
        return 'مُسلَّم';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }
}

class Order {
  final String id;
  final DateTime date;
  final String productType;
  final String dimensions; // e.g. 120 × 80 cm
  final double totalMeters;
  final double pricePerMeter;
  final OrderStatus status;
  final ProductionStage currentStage;

  const Order({
    required this.id,
    required this.date,
    required this.productType,
    required this.dimensions,
    required this.totalMeters,
    required this.pricePerMeter,
    required this.status,
    required this.currentStage,
  });

  double get totalPrice => totalMeters * pricePerMeter;

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        productType: j['productType'] as String,
        dimensions: j['dimensions'] as String,
        totalMeters: (j['totalMeters'] as num).toDouble(),
        pricePerMeter: (j['pricePerMeter'] as num).toDouble(),
        status: OrderStatus.values.byName(j['status'] as String),
        currentStage:
            ProductionStage.values.byName(j['currentStage'] as String),
      );
}
