import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared design tokens + reusable building blocks for the admin (الإدارة)
/// screens. Built to match the modern dashboard mockup.
class AdminPalette {
  AdminPalette._();

  static const Color bg = Color(0xFFF4F6FB);
  static const Color card = Colors.white;

  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0xFFEFF4FF);
  static const Color navy = Color(0xFF1E293B);

  static const Color green = Color(0xFF16A34A);
  static const Color greenSoft = Color(0xFFEAF7EE);
  static const Color orange = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color red = Color(0xFFDC2626);
  static const Color redSoft = Color(0xFFFEF2F2);

  static const Color text = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B);
  static const Color line = Color(0xFFEDF1F7);

  /// Donut / category color cycle.
  static const List<Color> chart = [
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF94A3B8),
    Color(0xFF06B6D4),
  ];
}

const List<BoxShadow> kAdminCardShadow = [
  BoxShadow(color: Color(0x0F1E293B), blurRadius: 18, offset: Offset(0, 8)),
];

/// White rounded surface used across admin screens.
class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kAdminCardShadow,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// اليوم / هذا الشهر / هذه السنة period selector.
enum AdminPeriod { today, month, year }

extension AdminPeriodLabel on AdminPeriod {
  String get label => switch (this) {
    AdminPeriod.today => 'اليوم',
    AdminPeriod.month => 'هذا الشهر',
    AdminPeriod.year => 'هذه السنة',
  };

  String get storageKey => switch (this) {
    AdminPeriod.today => 'today',
    AdminPeriod.month => 'month',
    AdminPeriod.year => 'year',
  };

  static AdminPeriod fromStorage(String? raw) => switch (raw) {
    'month' => AdminPeriod.month,
    'year' => AdminPeriod.year,
    _ => AdminPeriod.today,
  };
}

class AdminPeriodChips extends StatelessWidget {
  final AdminPeriod value;
  final ValueChanged<AdminPeriod> onChanged;

  const AdminPeriodChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final p in AdminPeriod.values) ...[
          _chip(context, p),
          if (p != AdminPeriod.values.last) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _chip(BuildContext context, AdminPeriod p) {
    final selected = p == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AdminPalette.blue
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AdminPalette.blue : AdminPalette.line,
            ),
          ),
          child: Text(
            p.label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title row with optional "عرض الكل" action.
class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AdminPalette.blue,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact metric tile (icon, label, value).
class AdminMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? secondaryValue;
  final IconData icon;
  final Color color;
  final Color? secondaryColor;
  final bool equalValueAndSecondaryFont;
  final VoidCallback? onTap;

  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.secondaryValue,
    this.secondaryColor,
    this.equalValueAndSecondaryFont = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryValue != null && secondaryValue!.isNotEmpty;
    final hasMultilineSecondary =
        hasSecondary && secondaryValue!.contains('\n');

    return AdminCard(
      padding: EdgeInsets.all(hasMultilineSecondary ? 10 : 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: hasMultilineSecondary ? 30 : (hasSecondary ? 34 : 38),
                height: hasMultilineSecondary ? 30 : (hasSecondary ? 34 : 38),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  size: hasMultilineSecondary ? 16 : (hasSecondary ? 18 : 20),
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          SizedBox(height: hasMultilineSecondary ? 6 : (hasSecondary ? 8 : 12)),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: hasMultilineSecondary ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: hasMultilineSecondary ? 2 : 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: hasMultilineSecondary ? 14 : (hasSecondary ? 15 : 16),
              color: color,
            ),
          ),
          if (secondaryValue != null) ...[
            SizedBox(height: hasMultilineSecondary ? 0 : 1),
            Text(
              secondaryValue!,
              maxLines: hasMultilineSecondary ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: equalValueAndSecondaryFont
                    ? (hasMultilineSecondary ? 14 : (hasSecondary ? 15 : 16))
                    : (hasMultilineSecondary ? 10.5 : 12),
                color:
                    secondaryColor ??
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Large centered total banner (e.g. "اجمالي الطلبات").
class AdminTotalBanner extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const AdminTotalBanner({
    super.key,
    required this.label,
    required this.value,
    this.color = AdminPalette.blue,
    this.background = AdminPalette.blueSoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 26,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat used in groups (value above, label below).
class AdminStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const AdminStatBox({
    super.key,
    required this.value,
    required this.label,
    this.color = AdminPalette.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple vertical bar chart with rounded bars + bottom labels.
class AdminBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final bool showValueLabels;
  final String valueUnit;
  final int valueDecimals;

  const AdminBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = AdminPalette.blue,
    this.height = 160,
    this.showValueLabels = false,
    this.valueUnit = '',
    this.valueDecimals = 0,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce(math.max).clamp(1, double.infinity);
    final topPadding = showValueLabels ? 18.0 : 0.0;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final availableHeight = constraints.maxHeight;
                          final chartArea = math.max(
                            8.0,
                            availableHeight - topPadding,
                          );
                          final barHeight =
                              chartArea *
                              (values[i] / maxValue).clamp(0.04, 1.0);

                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: SizedBox(
                                  height: barHeight,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.65),
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(7),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (showValueLabels)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: (barHeight + 4).clamp(
                                    2.0,
                                    availableHeight - 14,
                                  ),
                                  child: Text(
                                    _formatValue(values[i]),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) {
    final formatted = value.toStringAsFixed(valueDecimals);
    if (valueUnit.isEmpty) return formatted;
    return '$formatted $valueUnit';
  }
}

class AdminDonutSegment {
  final String label;
  final double value;
  final Color color;
  const AdminDonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Donut chart with a center caption and a side legend.
class AdminDonutChart extends StatelessWidget {
  final List<AdminDonutSegment> segments;
  final String centerLabel;
  final double size;

  const AdminDonutChart({
    super.key,
    required this.segments,
    required this.centerLabel,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    return Row(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(segments),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in segments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        total == 0
                            ? '0%'
                            : '${(s.value / total * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<AdminDonutSegment> segments;
  _DonutPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);
    final rect = Offset.zero & size;
    final stroke = size.width * 0.18;
    final arcRect = rect.deflate(stroke / 2);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AdminPalette.line;
    canvas.drawArc(arcRect, 0, 2 * math.pi, false, bg);

    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.04;
    for (final s in segments) {
      final sweep = (s.value / total) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = s.color;
      canvas.drawArc(
        arcRect,
        start + gap / 2,
        math.max(sweep - gap, 0.001),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.segments != segments;
}

/// Generic horizontal progress row used for "أعلى المصروفات".
class AdminProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double fraction;
  final Color color;

  const AdminProgressRow({
    super.key,
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1),
              minHeight: 7,
              backgroundColor: AdminPalette.line,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight table with a tinted header row.
class AdminDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<int> flex;

  const AdminDataTable({
    super.key,
    required this.headers,
    required this.rows,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            color: AdminPalette.blueSoft,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < headers.length; i++)
                Expanded(
                  flex: flex[i],
                  child: Text(
                    headers[i],
                    textAlign: i == 0 ? TextAlign.start : TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AdminPalette.blue,
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var r = 0; r < rows.length; r++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: r == rows.length - 1
                      ? Colors.transparent
                      : AdminPalette.line,
                ),
              ),
            ),
            child: Row(
              children: [
                for (var i = 0; i < rows[r].length; i++)
                  Expanded(
                    flex: flex[i],
                    child: Align(
                      alignment: i == 0
                          ? AlignmentDirectional.centerStart
                          : Alignment.center,
                      child: rows[r][i],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Text adminCell(String text, {bool bold = false, Color? color}) => Text(
  text,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontSize: 12.5,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
    color: color,
  ),
);
