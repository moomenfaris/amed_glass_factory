import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/staff_attendance.dart';
import '../data/models/staff_plus_hours.dart';
import '../data/models/staff_salary.dart';
import '../data/repositories/staff_salary_repository.dart';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class StaffSalaryQuery {
  final int employeeId;
  final DateTime at;

  const StaffSalaryQuery({required this.employeeId, required this.at});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StaffSalaryQuery &&
        other.employeeId == employeeId &&
        other.at == at;
  }

  @override
  int get hashCode => Object.hash(employeeId, at);
}

final staffSelectedDateProvider = StateProvider<DateTime>(
  (_) => _dateOnly(DateTime.now()),
);

final staffSalaryRepositoryProvider = Provider<StaffSalaryRepository>(
  (_) => ApiStaffSalaryRepository(),
);

final staffSalaryProvider =
    FutureProvider.family<StaffSalary, StaffSalaryQuery>((ref, query) {
      return ref
          .watch(staffSalaryRepositoryProvider)
          .fetch(employeeId: query.employeeId, at: query.at);
    });

final staffPlusHoursProvider = FutureProvider.family<double, StaffSalaryQuery>((
  ref,
  query,
) {
  return ref
      .watch(staffSalaryRepositoryProvider)
      .fetchPlusHours(employeeId: query.employeeId, at: query.at);
});

final staffPlusHoursDetailsProvider =
    FutureProvider.family<StaffPlusHoursDetails, StaffSalaryQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(staffSalaryRepositoryProvider)
          .fetchPlusHoursDetails(employeeId: query.employeeId, at: query.at);
    });

final staffAttendanceProvider =
    FutureProvider.family<StaffAttendance, StaffSalaryQuery>((ref, query) {
      return ref
          .watch(staffSalaryRepositoryProvider)
          .fetchAttendance(employeeId: query.employeeId, at: query.at);
    });
