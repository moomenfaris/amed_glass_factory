class StaffAttendance {
  final List<String> days;

  const StaffAttendance({required this.days});

  factory StaffAttendance.fromApiRow(Map<String, dynamic> row) {
    String normalize(dynamic value) {
      final v = (value?.toString() ?? '').trim();
      return v.isEmpty ? 'غير محدد' : v;
    }

    final values = <String>[];
    for (var i = 1; i <= 31; i++) {
      values.add(normalize(row['d$i']));
    }

    return StaffAttendance(days: values);
  }

  int get presentCount => days.where((e) => e == 'دوام').length;

  int get absentCount => days.where((e) => e == 'غياب').length;
}
