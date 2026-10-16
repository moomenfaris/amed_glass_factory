class StaffSalary {
  final int employeeCode;
  final String employeeName;
  final String department;
  final double nominalSalary;
  final double allowances;
  final int attendanceDays;
  final int absenceDays;
  final double overtimeHours;
  final double deduction;
  final double penalties;
  final double dueSalary;
  final double overtimeValue;
  final double advances;
  final double netSalary;
  final double hourUnitValue;

  const StaffSalary({
    required this.employeeCode,
    required this.employeeName,
    required this.department,
    required this.nominalSalary,
    required this.allowances,
    required this.attendanceDays,
    required this.absenceDays,
    required this.overtimeHours,
    required this.deduction,
    required this.penalties,
    required this.dueSalary,
    required this.overtimeValue,
    required this.advances,
    required this.netSalary,
    required this.hourUnitValue,
  });

  factory StaffSalary.fromApi(Map<String, dynamic> json) {
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

    String toStringSafe(dynamic v) => (v?.toString() ?? '').trim();

    return StaffSalary(
      employeeCode: toInt(json['كود_الموظف']),
      employeeName: toStringSafe(json['اسم_الموظف']),
      department: toStringSafe(json['القسم']),
      nominalSalary: toDouble(json['الراتب_الاسمي']),
      allowances: toDouble(json['المخصصات']),
      attendanceDays: toInt(json['الدوام']),
      absenceDays: toInt(json['الغياب']),
      overtimeHours: toDouble(json['الساعت_الاضافية']),
      deduction: toDouble(json['الاستقطاع']),
      penalties: toDouble(json['العقوبات']),
      dueSalary: toDouble(json['الراتب_المستحق']),
      overtimeValue: toDouble(json['قيمة_الساعة']),
      advances: toDouble(json['السلف']),
      netSalary: toDouble(json['صافي_الراتب']),
      hourUnitValue: toDouble(json['قيمة_الساعة_الواحدة']),
    );
  }
}
