import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/models/order_production.dart';

class ProductionCard extends StatefulWidget {
  final OrderProductionItem item;
  final bool forceDoneStage;
  final bool doneFromStatus;
  final bool showOrderMeta;
  final bool collapsibleDetails;
  const ProductionCard({
    super.key,
    required this.item,
    this.forceDoneStage = false,
    this.doneFromStatus = false,
    this.showOrderMeta = false,
    this.collapsibleDetails = false,
  });

  @override
  State<ProductionCard> createState() => _ProductionCardState();
}

class _ProductionCardState extends State<ProductionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsibleDetails;
  }

  @override
  void didUpdateWidget(covariant ProductionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsibleDetails != widget.collapsibleDetails) {
      _expanded = !widget.collapsibleDetails;
    }
  }

  static String _num(double v) {
    if ((v - v.truncateToDouble()).abs() < 0.0001) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(2);
  }

  static const _stages = <({String label, IconData icon})>[
    (label: 'القص', icon: Icons.content_cut),
    (label: 'روداج', icon: Icons.auto_fix_high_outlined),
    (label: 'صبغ', icon: Icons.colorize_outlined),
    (label: 'فرن', icon: Icons.local_fire_department_outlined),
    (label: 'دبل', icon: Icons.layers_outlined),
    (label: 'سيليكون', icon: Icons.edit_outlined),
    (label: 'رمل', icon: Icons.blur_on),
    (label: 'لامينت', icon: Icons.layers_clear_outlined),
    (label: 'Done', icon: Icons.check_circle_outline),
  ];

  List<bool> _flags() {
    final core = [
      widget.item.cut,
      widget.item.grinding,
      widget.item.dye,
      widget.item.oven,
      widget.item.doubleGlazing,
      widget.item.silicone,
      widget.item.sandBlast,
      widget.item.laminate,
    ];
    final statusDone = widget.item.status.trim().toLowerCase() == 'done';
    final done = widget.doneFromStatus
        ? statusDone
        : (widget.forceDoneStage || core.every((e) => e));
    return [...core, done];
  }

  int _currentIndex(List<bool> flags) {
    if (flags.every((f) => !f)) return 0;
    if (flags.last) return flags.length - 1;
    for (var i = flags.length - 2; i >= 0; i--) {
      if (flags[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final flags = _flags();
    final current = _currentIndex(flags);
    final hasOrderMeta =
        widget.showOrderMeta &&
        ((widget.item.orderNumber?.isNotEmpty ?? false) ||
            (widget.item.projectName?.isNotEmpty ?? false));
    final showDetails = !widget.collapsibleDetails || _expanded;

    return AppCard(
      child: InkWell(
        onTap: widget.collapsibleDetails
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            if (hasOrderMeta || widget.collapsibleDetails)
              Padding(
                padding: EdgeInsets.only(bottom: showDetails ? 10 : 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (widget.item.orderNumber?.isNotEmpty ?? false)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brandLight,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'الطلبية: ${widget.item.orderNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.brandMid,
                                ),
                              ),
                            ),
                          if ((widget.item.orderNumber?.isNotEmpty ?? false) &&
                              (widget.item.projectName?.isNotEmpty ?? false))
                            const SizedBox(width: 8),
                          if (widget.item.projectName?.isNotEmpty ?? false)
                            Expanded(
                              child: Text(
                                widget.item.projectName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.collapsibleDetails) ...[
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.brandMid,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.brandLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/img/fg.png',
                            width: 46,
                            height: 68,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.crop_square,
                              size: 34,
                              color: AppTheme.brandMid,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'المواصفات',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.item.specs.isEmpty
                                  ? '—'
                                  : widget.item.specs,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _FieldChip(
                                  label: 'الطول',
                                  value: _num(widget.item.length),
                                ),
                                _FieldChip(
                                  label: 'العرض',
                                  value: _num(widget.item.width),
                                ),
                                _FieldChip(
                                  label: 'الطول2',
                                  value: _num(widget.item.length2),
                                ),
                                _FieldChip(
                                  label: 'العرض2',
                                  value: _num(widget.item.width2),
                                ),
                                _FieldChip(
                                  label: 'عدد الامتار',
                                  value: _num(widget.item.meters),
                                ),
                                _FieldChip(
                                  label: 'عدد قطع الطلبية',
                                  value: '${widget.item.orderPieces}',
                                ),
                                _FieldChip(
                                  label: 'عدد القطع المسلمة',
                                  value: '${widget.item.deliveredPieces ?? 0}',
                                ),
                                _FieldChip(
                                  label: 'عدد الامتار المتبقية',
                                  value: _num(widget.item.remainingMeters),
                                ),
                                _FieldChip(
                                  label: 'عدد القطع المتبقية',
                                  value: '${widget.item.remainingPieces}',
                                ),
                                _FieldChip(
                                  label: 'الحالة',
                                  value: widget.item.status.isEmpty
                                      ? '-'
                                      : widget.item.status,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < _stages.length; i++) ...[
                          _StageChip(
                            icon: _stages[i].icon,
                            label: _stages[i].label,
                            done: flags[i],
                            current: !flags[i] && i == current,
                          ),
                          if (i != _stages.length - 1)
                            Container(
                              width: 16,
                              height: 1.2,
                              color: const Color(0xFFD4D8DF),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: showDetails
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool done;
  final bool current;
  const _StageChip({
    required this.icon,
    required this.label,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppTheme.success
        : (current ? AppTheme.warning : const Color(0xFF9DA4B2));
    final status = done ? 'تم' : (current ? 'جاري التنفيذ' : 'لم يبدأ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.34)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldChip extends StatelessWidget {
  final String label;
  final String value;

  const _FieldChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDCE2EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
