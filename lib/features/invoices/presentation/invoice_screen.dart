import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/models/invoice.dart';
import '../providers/invoice_provider.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  const InvoiceScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  static const int _initialVisible = 3;

  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expanded = {0};
  String _query = '';
  bool _showAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(invoiceProvider(widget.invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle('فاتورة #${widget.invoiceId}'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  ref.invalidate(invoiceProvider(widget.invoiceId));
                  break;
                case 'images':
                  context.push('/movement-images/${widget.invoiceId}');
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 12),
                    Text('تحديث'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'images',
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('صور الحركة'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: async.when(
        data: (invoice) {
          if (invoice.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'لا توجد بيانات لهذه الفاتورة',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(invoiceProvider(widget.invoiceId)),
            child: _InvoiceContent(
              invoice: invoice,
              searchController: _searchController,
              query: _query,
              expanded: _expanded,
              showAll: _showAll,
              initialVisible: _initialVisible,
              onQueryChanged: (v) => setState(() => _query = v),
              onToggleExpand: (i) => setState(() {
                if (!_expanded.remove(i)) _expanded.add(i);
              }),
              onShowAll: () => setState(() => _showAll = true),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
      ),
    );
  }
}

class _InvoiceContent extends StatelessWidget {
  final Invoice invoice;
  final TextEditingController searchController;
  final String query;
  final Set<int> expanded;
  final bool showAll;
  final int initialVisible;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onToggleExpand;
  final VoidCallback onShowAll;

  const _InvoiceContent({
    required this.invoice,
    required this.searchController,
    required this.query,
    required this.expanded,
    required this.showAll,
    required this.initialVisible,
    required this.onQueryChanged,
    required this.onToggleExpand,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filteredIndexes = <int>[];
    for (var i = 0; i < invoice.items.length; i++) {
      final item = invoice.items[i];
      if (q.isEmpty || item.specification.toLowerCase().contains(q)) {
        filteredIndexes.add(i);
      }
    }

    final searching = q.isNotEmpty;
    final visibleIndexes = (searching || showAll)
        ? filteredIndexes
        : filteredIndexes.take(initialVisible).toList();
    final hiddenCount = filteredIndexes.length - visibleIndexes.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _HeaderMeta(header: invoice.header),
        const SizedBox(height: 14),
        _SummaryCard(invoice: invoice),
        const SizedBox(height: 16),
        _SearchField(controller: searchController, onChanged: onQueryChanged),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'بنود الفاتورة (${invoice.items.length})',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        if (filteredIndexes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'لا توجد مواد مطابقة لبحثك',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        else
          for (final i in visibleIndexes) ...[
            _ItemCard(
              order: i + 1,
              item: invoice.items[i],
              expanded: expanded.contains(i),
              onTap: () => onToggleExpand(i),
            ),
            const SizedBox(height: 10),
          ],
        if (hiddenCount > 0) ...[
          const SizedBox(height: 2),
          _ShowMoreButton(count: hiddenCount, onTap: onShowAll),
        ],
        const SizedBox(height: 16),
        _TotalsCard(invoice: invoice),
      ],
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  final InvoiceHeader? header;
  const _HeaderMeta({required this.header});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    final date = header?.dateOrder;
    final status = header?.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (date != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_outlined, size: 15, color: muted),
              const SizedBox(width: 6),
              Text(
                Formatters.longDate(date),
                style: TextStyle(
                  color: muted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        _StatusBadge(status: status),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = (status == null || status!.trim().isEmpty)
        ? 'قيد التنفيذ'
        : status!.trim();
    const color = AppTheme.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB46B00),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Invoice invoice;
  const _SummaryCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final header = invoice.header;
    final customerName = header?.projectName ?? '—';
    final reference = header?.reference;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'إجمالي الفاتورة',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(invoice.totalAmount),
                        style: TextStyle(
                          color: AppTheme.brandDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 32, thickness: 1),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'العميل',
                            style: TextStyle(color: muted, fontSize: 13),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.person_outline, size: 16, color: muted),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customerName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      if (reference != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'مرجع: $reference',
                          style: TextStyle(color: muted, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.crop_free,
                  label: 'إجمالي المساحة',
                  value: '${invoice.totalArea.toStringAsFixed(2)} m²',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'عدد البنود',
                  value: '${invoice.itemCount} مادة',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.brandLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.brandDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: muted, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث عن مادة...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final int order;
  final InvoiceItem item;
  final bool expanded;
  final VoidCallback onTap;

  const _ItemCard({
    required this.order,
    required this.item,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.brandDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$order',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.specification.isEmpty ? '—' : item.specification,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.brandDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Formatters.currency(item.total),
                      style: const TextStyle(
                        color: AppTheme.brandDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ItemDetails(item: item),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _ItemDetails extends StatelessWidget {
  final InvoiceItem item;
  const _ItemDetails({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.brandMid.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.brandMid.withValues(alpha: 0.35),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/img/fg.png',
                    width: 66,
                    height: 66,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.crop_square,
                      size: 40,
                      color: AppTheme.brandMid.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.straighten,
                            label: 'المقاس (عرض × ارتفاع)',
                            value:
                                '${_fmt(item.glassWidth)} × ${_fmt(item.glassHeight)} mm',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.inventory_2_outlined,
                            label: 'الكمية',
                            value: '${item.piecesCount}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.crop_free,
                            label: 'المساحة',
                            value: '${item.meterCount.toStringAsFixed(2)} m²',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DetailTile(
                            icon: Icons.sell_outlined,
                            label: 'سعر المتر',
                            value: Formatters.currency(item.meterPrice),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.brandDark.withValues(alpha: 0.06),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currency(item.total),
                style: const TextStyle(
                  color: AppTheme.brandDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'الإجمالي',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: muted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShowMoreButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ShowMoreButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.brandDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.brandDark.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 18,
              color: AppTheme.brandDark,
            ),
            const SizedBox(width: 8),
            Text(
              'عرض المزيد من البنود ($count)',
              style: const TextStyle(
                color: AppTheme.brandDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  final Invoice invoice;
  const _TotalsCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.brandLight.withValues(alpha: 0.7),
            AppTheme.brandMid.withValues(alpha: 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brandMid.withValues(alpha: 0.25)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'الإجمالي النهائي',
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.currency(invoice.totalAmount),
                    style: const TextStyle(
                      color: AppTheme.brandDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 28, thickness: 1),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MiniStat(
                    icon: Icons.crop_free,
                    label: 'إجمالي المساحات',
                    value: '${invoice.totalArea.toStringAsFixed(2)} m²',
                  ),
                  const SizedBox(height: 12),
                  _MiniStat(
                    icon: Icons.widgets_outlined,
                    label: 'عدد المواد',
                    value: '${invoice.itemCount} مادة',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppTheme.brandDark),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: muted, fontSize: 11.5)),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
