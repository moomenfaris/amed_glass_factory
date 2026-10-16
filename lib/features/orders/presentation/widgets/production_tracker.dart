import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/order.dart';

/// Vertical stepper showing production stages.
class ProductionTracker extends StatelessWidget {
  final ProductionStage currentStage;
  const ProductionTracker({super.key, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stages = ProductionStage.values;
    final currentIdx = stages.indexOf(currentStage);

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _StageRow(
            label: stages[i].arabicLabel,
            isDone: i < currentIdx,
            isCurrent: i == currentIdx,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  const _StageRow({
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppTheme.primary
        : isDone
            ? AppTheme.success
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDone || isCurrent
                      ? color
                      : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone
                      ? Icons.check
                      : isCurrent
                          ? Icons.autorenew
                          : Icons.circle,
                  size: 14,
                  color: isDone || isCurrent ? Colors.white : color,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: color.withValues(alpha: 0.4)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrent
                      ? AppTheme.primary
                      : isDone
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
