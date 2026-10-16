class MovementTotalItem {
  final String statement;
  final int count;
  final double net;

  const MovementTotalItem({
    required this.statement,
    required this.count,
    required this.net,
  });

  factory MovementTotalItem.fromApi(Map<String, dynamic> j) {
    final rawCount = j['العدد'] ?? j['count'] ?? 0;
    final rawNet = j['الصافي'] ?? j['net'] ?? j['balance'] ?? 0;

    int parsedCount = 0;
    if (rawCount is num) {
      parsedCount = rawCount.toInt();
    } else {
      parsedCount = int.tryParse(rawCount.toString()) ?? 0;
    }

    double parsedNet = 0;
    if (rawNet is num) {
      parsedNet = rawNet.toDouble();
    } else {
      parsedNet =
          double.tryParse(rawNet.toString().replaceAll(',', '').trim()) ?? 0;
    }

    return MovementTotalItem(
      statement: (j['البيان'] ?? j['statement'] ?? '').toString().trim(),
      count: parsedCount,
      net: parsedNet,
    );
  }
}
