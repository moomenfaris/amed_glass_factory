class StaffPlusHoursDay {
  final int day;
  final double hours;

  const StaffPlusHoursDay({required this.day, required this.hours});

  factory StaffPlusHoursDay.fromApi(Map<String, dynamic> json) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    double toDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    return StaffPlusHoursDay(
      day: toInt(json['day']),
      hours: toDouble(json['hours']),
    );
  }
}

class StaffPlusHoursDetails {
  final double totalHours;
  final List<StaffPlusHoursDay> days;

  const StaffPlusHoursDetails({required this.totalHours, required this.days});

  factory StaffPlusHoursDetails.fromApi(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    final rawDays = (json['days'] as List?) ?? const [];

    return StaffPlusHoursDetails(
      totalHours: toDouble(json['totalHours']),
      days:
          rawDays
              .whereType<Map>()
              .map(
                (e) => StaffPlusHoursDay.fromApi(Map<String, dynamic>.from(e)),
              )
              .toList()
            ..sort((a, b) => a.day.compareTo(b.day)),
    );
  }
}
