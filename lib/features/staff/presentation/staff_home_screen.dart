import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/error/error_message.dart';
import '../../../core/providers/font_scale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/home_entry_metadata_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/font_scale_sheet.dart';
import '../../../core/widgets/theme_mode_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/staff_salary.dart';
import '../providers/staff_employee_image_provider.dart';
import '../providers/staff_salary_provider.dart';

class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: const _StaffScaffold(),
    );
  }
}

class _StaffHomeBody extends ConsumerWidget {
  const _StaffHomeBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final employeeId = user?.userId ?? int.tryParse(user?.id ?? '');

    if (employeeId == null || employeeId <= 0) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: const [
          AppCard(child: Text('تعذر تحديد رقم الموظف لعرض بيانات الراتب.')),
        ],
      );
    }

    final selectedDate = ref.watch(staffSelectedDateProvider);
    final query = StaffSalaryQuery(employeeId: employeeId, at: selectedDate);
    final async = ref.watch(staffSalaryProvider(query));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [AppCard(child: Text('خطأ: ${userErrorMessage(e)}'))],
      ),
      data: (salary) {
        final plusHoursAsync = ref.watch(staffPlusHoursProvider(query));
        final overtimeHoursValue = plusHoursAsync.maybeWhen(
          data: (v) => v,
          orElse: () => salary.overtimeHours,
        );
        final overtimeRemaining = (salary.advances - salary.deduction)
            .clamp(0, double.infinity)
            .toDouble();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffSalaryProvider(query));
            ref.invalidate(staffPlusHoursProvider(query));
            ref.invalidate(staffEmployeeImageProvider(employeeId));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _HeaderCard(salary: salary, reportDate: selectedDate),
              const SizedBox(height: 12),
              _StatsRowCard(
                salary: salary,
                overtimeHoursValue: overtimeHoursValue,
                onAttendanceTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => _AttendanceSheet(
                      employeeId: employeeId,
                      at: selectedDate,
                    ),
                  );
                },
                onOvertimeTap: () {
                  final at = selectedDate.toUtc().toIso8601String();
                  context.push('/staff/plus-hours?id=$employeeId&at=$at');
                },
              ),
              const SizedBox(height: 12),
              _InfoGrid(
                salary: salary,
                remainingAdvance: overtimeRemaining,
                overtimeHoursValue: overtimeHoursValue,
              ),
              const SizedBox(height: 12),
              _NetSalaryCard(salary: salary),
              const SizedBox(height: 12),
              _NoteCard(salary: salary),
            ],
          ),
        );
      },
    );
  }
}

class _StaffScaffold extends ConsumerStatefulWidget {
  const _StaffScaffold();

  @override
  ConsumerState<_StaffScaffold> createState() => _StaffScaffoldState();
}

class _StaffScaffoldState extends ConsumerState<_StaffScaffold> {
  final HomeEntryMetadataService _homeEntryMetadataService =
      HomeEntryMetadataService();
  int? _lastSentForUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendHomeEntryMetadataIfNeeded();
      ref
          .read(authStateProvider.notifier)
          .refreshUserState(force: true, apiType: 'employees');
    });
  }

  Future<void> _sendHomeEntryMetadataIfNeeded() async {
    final auth = ref.read(authStateProvider);
    final user = auth.user;
    final userId = user?.userId ?? int.tryParse(user?.id ?? '');
    if (userId == null || userId <= 0 || _lastSentForUserId == userId) return;

    try {
      final payload = await _homeEntryMetadataService.sendForUserOnHomeEnter(
        user: user,
        authToken: auth.token,
      );
      if (payload == null) return;
      _lastSentForUserId = userId;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال المعلومات: ${userErrorMessage(e)}')),
      );
    }
  }

  Future<void> _pickSelectedDate(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(staffSelectedDateProvider);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null) return;
    ref.read(staffSelectedDateProvider.notifier).state = DateTime(
      picked.year,
      picked.month,
      picked.day,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(staffSelectedDateProvider);
    final monthLabel = DateFormat('MMMM yyyy', 'ar').format(selectedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const _StaffDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111F31),
        surfaceTintColor: const Color(0xFF111F31),
        foregroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'بيانات دوام الموظف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              monthLabel,
              style: TextStyle(
                color: Color(0xFFD0DAEA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _pickSelectedDate(context, ref),
            icon: const Icon(Icons.calendar_today_rounded),
            tooltip: DateFormat('yyyy/MM/dd').format(selectedDate),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const _StaffHomeBody(),
    );
  }
}

class _StaffDrawer extends ConsumerWidget {
  const _StaffDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale = ref.watch(appFontScaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                'إعدادات الحساب',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.format_size, color: colors.onSurface),
              title: Text(
                'حجم الخط',
                style: TextStyle(color: colors.onSurface),
              ),
              trailing: Text(
                '${(fontScale * 100).round()}%',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                showFontScaleSheet(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.dark_mode_outlined, color: colors.onSurface),
              title: Text(
                'مظهر التطبيق',
                style: TextStyle(color: colors.onSurface),
              ),
              trailing: Text(
                themeMode == ThemeMode.dark ? 'داكن' : 'فاتح',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                showThemeModeSheet(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD83B3B),
              ),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Color(0xFFD83B3B)),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final StaffSalary salary;
  final DateTime reportDate;

  const _HeaderCard({required this.salary, required this.reportDate});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formattedReportDate = Formatters.dateEnglishDigits(reportDate);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                  alignment: Alignment.topCenter,
                  child: _EmployeeAvatar(radius: 34),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    salary.employeeName.isEmpty
                        ? 'غير محدد'
                        : salary.employeeName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    salary.department.isEmpty ? 'غير محدد' : salary.department,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: _ChipLabel(label: 'نشط', color: Color(0xFF1C9A55)),
                ),
                const SizedBox(height: 8),
                _MetaLine(
                  icon: Icons.badge_outlined,
                  text: 'رقم الموظف: ${salary.employeeCode}',
                ),
                const SizedBox(height: 4),
                _MetaLine(
                  icon: Icons.calendar_today_outlined,
                  text: 'تاريخ التقرير: $formattedReportDate',
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 140, color: colors.outlineVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الراتب الاسمي',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                _MoneyText(
                  amount: _fmtNum(salary.nominalSalary),
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF1B2233),
                  amountSize: 28,
                  bold: true,
                ),
                SizedBox(height: 10),
                Text(
                  'نوع الراتب: شهري',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'قسم: ${salary.department.isEmpty ? '-' : salary.department}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAvatar extends ConsumerWidget {
  final double radius;

  const _EmployeeAvatar({required this.radius});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).user;
    final employeeId = user?.userId ?? int.tryParse(user?.id ?? '');

    if (employeeId == null || employeeId <= 0) {
      return _fallbackAvatar(radius);
    }

    final async = ref.watch(staffEmployeeImageProvider(employeeId));
    return async.when(
      data: (url) {
        if (url == null || url.isEmpty) return _fallbackAvatar(radius);
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFFE9EEF8),
          child: ClipOval(
            child: Image.network(
              url,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallbackAvatar(radius),
            ),
          ),
        );
      },
      loading: () => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFE9EEF8),
        child: SizedBox(
          width: radius * 0.8,
          height: radius * 0.8,
          child: const CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
      error: (_, _) => _fallbackAvatar(radius),
    );
  }

  Widget _fallbackAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE9EEF8),
      child: Icon(
        Icons.person,
        size: radius * 1.05,
        color: Colors.blueGrey.shade400,
      ),
    );
  }
}

class _StatsRowCard extends StatelessWidget {
  final StaffSalary salary;
  final double overtimeHoursValue;
  final VoidCallback onAttendanceTap;
  final VoidCallback onOvertimeTap;

  const _StatsRowCard({
    required this.salary,
    required this.overtimeHoursValue,
    required this.onAttendanceTap,
    required this.onOvertimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.event_available_outlined,
              title: 'أيام الدوام',
              value: '${salary.attendanceDays}',
              suffix: 'يوم',
              color: const Color(0xFF1C9A55),
              onTap: onAttendanceTap,
            ),
          ),
          const _SplitLine(),
          Expanded(
            child: _StatItem(
              icon: Icons.event_busy_outlined,
              title: 'أيام الغياب',
              value: '${salary.absenceDays}',
              suffix: 'يوم',
              color: const Color(0xFFD83B3B),
            ),
          ),
          const _SplitLine(),
          Expanded(
            child: _StatItem(
              icon: Icons.schedule,
              title: 'الساعات الإضافية',
              value: _fmtNum(overtimeHoursValue),
              suffix: 'ساعة',
              color: const Color(0xFF1A5FD0),
              onTap: onOvertimeTap,
            ),
          ),
          const _SplitLine(),
          Expanded(
            child: _StatItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'قيمة الساعات الإضافية',
              value: _fmtNum(salary.overtimeValue),
              suffix: 'دولار',
              color: const Color(0xFF6B42D8),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final StaffSalary salary;
  final double remainingAdvance;
  final double overtimeHoursValue;

  const _InfoGrid({
    required this.salary,
    required this.remainingAdvance,
    required this.overtimeHoursValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DetailCard(
                title: 'تفاصيل الساعات الإضافية',
                lines: [
                  (
                    'عدد الساعات الإضافية',
                    '${_fmtNum(overtimeHoursValue)} ساعة',
                  ),
                  (
                    'قيمة الساعة الواحدة',
                    '${_fmtNum(salary.hourUnitValue)} دولار',
                  ),
                ],
                totalLabel: 'إجمالي قيمة الساعات الإضافية',
                totalValue: _fmtNum(salary.overtimeValue),
                totalColor: const Color(0xFF1A5FD0),
                icon: Icons.watch_later_outlined,
                iconColor: const Color(0xFF1A5FD0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailCard(
                title: 'السلفة',
                lines: [
                  ('إجمالي السلفة', '${_fmtNum(salary.advances)} دولار'),
                  ('المستقطع من السلفة', '${_fmtNum(salary.deduction)} دولار'),
                ],
                totalLabel: 'السلفة المتبقية',
                totalValue: _fmtNum(remainingAdvance),
                totalColor: const Color(0xFF1C9A55),
                icon: Icons.local_atm_outlined,
                iconColor: const Color(0xFF1C9A55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DetailCard(
                title: 'العقوبات',
                lines: [
                  ('عدد العقوبات', salary.penalties > 0 ? '1' : '0'),
                  ('إجمالي العقوبات', '${_fmtNum(salary.penalties)} دولار'),
                ],
                totalLabel: 'عرض تفاصيل العقوبات',
                totalValue: '',
                totalColor: const Color(0xFFC12D4D),
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFC12D4D),
                outlinedFooter: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailCard(
                title: 'الاستقطاع من السلفة',
                lines: [
                  ('إجمالي الاستقطاع', '${_fmtNum(salary.deduction)} دولار'),
                ],
                totalLabel: '',
                totalValue: '',
                totalColor: const Color(0xFFD58A17),
                icon: Icons.event_note_outlined,
                iconColor: const Color(0xFFD58A17),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NetSalaryCard extends StatelessWidget {
  final StaffSalary salary;

  const _NetSalaryCard({required this.salary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C9A55).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1C9A55).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF1C9A55),
              ),
              SizedBox(width: 8),
              Text(
                'صافي الراتب',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C9A55),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          _MoneyText(
            amount: _fmtNum(salary.netSalary),
            color: const Color(0xFF1C9A55),
            amountSize: 36,
            bold: true,
          ),
          const SizedBox(height: 6),
          Text(
            '(الراتب المستحق + المخصصات) - (العقوبات + الاستقطاع)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final StaffSalary salary;

  const _NoteCard({required this.salary});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ملاحظة: أيام الغياب ${salary.absenceDays} يوم، الراتب المستحق ${_fmtNum(salary.dueSalary)} دولار',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String suffix;
  final Color color;
  final VoidCallback? onTap;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.suffix,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            suffix,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSheet extends ConsumerWidget {
  final int employeeId;
  final DateTime at;

  const _AttendanceSheet({required this.employeeId, required this.at});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final query = StaffSalaryQuery(employeeId: employeeId, at: at);
    final async = ref.watch(staffAttendanceProvider(query));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: async.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 220,
            child: Center(child: Text('خطأ: ${userErrorMessage(e)}')),
          ),
          data: (attendance) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تفاصيل الدوام الشهرية',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'دوام: ${attendance.presentCount} يوم  |  غياب: ${attendance.absentCount} يوم',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: attendance.days.length,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final value = attendance.days[index];
                    final present = value == 'دوام';
                    final absent = value == 'غياب';
                    final color = present
                        ? const Color(0xFF1C9A55)
                        : absent
                        ? const Color(0xFFD83B3B)
                        : const Color(0xFF7A8395);
                    return Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'يوم $day',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            value,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitLine extends StatelessWidget {
  const _SplitLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 138,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<(String, String)> lines;
  final String totalLabel;
  final String totalValue;
  final Color totalColor;
  final IconData icon;
  final Color iconColor;
  final bool outlinedFooter;

  const _DetailCard({
    required this.title,
    required this.lines,
    required this.totalLabel,
    required this.totalValue,
    required this.totalColor,
    required this.icon,
    required this.iconColor,
    this.outlinedFooter = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in lines) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    line.$1,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  line.$2,
                  style: TextStyle(
                    color: totalColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (totalLabel.isNotEmpty || totalValue.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: outlinedFooter
                  ? BoxDecoration(
                      color: totalColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (totalLabel.isNotEmpty)
                    Text(
                      totalLabel,
                      style: TextStyle(
                        color: totalColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (totalValue.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _MoneyText(
                      amount: totalValue,
                      color: totalColor,
                      amountSize: 24,
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MoneyText extends StatelessWidget {
  final String amount;
  final Color color;
  final double amountSize;
  final bool bold;

  const _MoneyText({
    required this.amount,
    required this.color,
    required this.amountSize,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w800 : FontWeight.w700;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '\$ ',
              style: TextStyle(
                color: color,
                fontSize: amountSize * 0.52,
                fontWeight: weight,
                fontFamily: 'Tajawal',
              ),
            ),
            TextSpan(
              text: amount,
              style: TextStyle(
                color: color,
                fontSize: amountSize,
                fontWeight: weight,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtNum(num value) {
  if ((value - value.toInt()).abs() < 0.000001) {
    return NumberFormat.decimalPattern('en').format(value.toInt());
  }
  return NumberFormat('#,##0.##', 'en').format(value);
}
