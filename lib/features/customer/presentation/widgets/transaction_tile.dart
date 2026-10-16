import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../transactions/data/models/transaction.dart';

const Color _kBlue = Color(0xFF2563EB);
const Color _kGreen = Color(0xFF16A34A);
const Color _kOrange = Color(0xFFEA8C00);
const Color _kRed = Color(0xFFDC2626);

class TransactionTile extends StatelessWidget {
  final AccountTransaction tx;
  final bool showCurrentBalance;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;
  final VoidCallback? onInvoiceTap;
  final VoidCallback? onImagesTap;

  const TransactionTile({
    super.key,
    required this.tx,
    this.showCurrentBalance = true,
    this.onTap,
    this.onDetailsTap,
    this.onInvoiceTap,
    this.onImagesTap,
  });

  ({IconData icon, Color color, String label}) _styleFor(TransactionType t) {
    switch (t) {
      case TransactionType.order:
        return (
          icon: Icons.shopping_bag_outlined,
          color: _kBlue,
          label: 'طلبية',
        );
      case TransactionType.invoice:
        return (
          icon: Icons.receipt_long_outlined,
          color: _kOrange,
          label: 'فاتورة',
        );
      case TransactionType.payment:
        return (
          icon: Icons.payments_outlined,
          color: _kGreen,
          label: 'سند قبض',
        );
      case TransactionType.accountingEntry:
        return (icon: Icons.swap_horiz, color: Colors.purple, label: 'قيد');
    }
  }

  ({String label, Color color})? _statusFor() {
    final s = '${tx.status} ${tx.description}';
    if (s.contains('تحت التنفيذ')) {
      return (label: 'تحت التنفيذ', color: _kOrange);
    }
    if (s.contains('مكتمل') || s.contains('منفذ') || s.contains('تم ')) {
      return (label: 'مكتملة', color: _kGreen);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = _styleFor(tx.type);
    final status = _statusFor();
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header: title + number + icon | status badge ----
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: s.color,
                      ),
                    ),
                    if (tx.movementNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '#${tx.movementNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 20),
                ),
                const Spacer(),
                if (status != null) _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            // ---- Date ----
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 15, color: muted),
                const SizedBox(width: 6),
                Text(
                  Formatters.dateEnglishDigits(tx.date),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (tx.projectName != null && tx.projectName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.business_outlined, size: 15, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tx.projectName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // ---- Financial row ----
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showCurrentBalance) ...[
                    Expanded(
                      child: _Metric(
                        label: 'الرصيد الحالي',
                        value: Formatters.currency(tx.balance ?? 0),
                        color: Theme.of(context).colorScheme.onSurface,
                        bold: true,
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                  ],
                  Expanded(
                    child: _Metric(
                      label: 'دائن',
                      value: Formatters.currency(tx.credit ?? 0),
                      color: _kGreen,
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: _Metric(
                      label: 'مدين',
                      value: Formatters.currency(tx.debit ?? 0),
                      color: _kRed,
                    ),
                  ),
                ],
              ),
            ),
            if (onDetailsTap != null ||
                onInvoiceTap != null ||
                onImagesTap != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  if (onDetailsTap != null)
                    Expanded(
                      child: _ActionButton(
                        onPressed: onDetailsTap!,
                        icon: Icons.visibility_outlined,
                        label: 'التفاصيل',
                        color: _kBlue,
                      ),
                    ),
                  if (onDetailsTap != null &&
                      (onInvoiceTap != null || onImagesTap != null))
                    const SizedBox(width: 10),
                  if (onInvoiceTap != null)
                    Expanded(
                      child: _ActionButton(
                        onPressed: onInvoiceTap!,
                        icon: Icons.receipt_long_outlined,
                        label: 'الفاتورة',
                        color: _kOrange,
                      ),
                    ),
                  if (onInvoiceTap != null && onImagesTap != null)
                    const SizedBox(width: 10),
                  if (onImagesTap != null)
                    Expanded(
                      child: _ActionButton(
                        onPressed: onImagesTap!,
                        icon: Icons.photo_library_outlined,
                        label: 'الصور',
                        color: _kGreen,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ({String label, Color color}) status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: muted)),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.45)),
        backgroundColor: color.withValues(alpha: 0.06),
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
