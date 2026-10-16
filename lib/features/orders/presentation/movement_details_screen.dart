import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/models/order_production.dart';
import '../providers/order_production_provider.dart';
import 'widgets/production_card.dart';

class MovementDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;
  const MovementDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<MovementDetailsScreen> createState() =>
      _MovementDetailsScreenState();
}

class _MovementDetailsScreenState extends ConsumerState<MovementDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderProductionProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBarTitle('مراحل الإنتاج'),
            const SizedBox(height: 2),
            Text(
              'طلبية #${widget.orderId}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'refresh') {
                ref.invalidate(orderProductionProvider(widget.orderId));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('تحديث'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.inbox_outlined,
              message: 'لا توجد تفاصيل لهذه الحركة',
            );
          }

          final filtered = _filter(items, _query);
          final totalPieces = items.fold<int>(0, (s, e) => s + e.orderPieces);
          final allDone = items.every((e) => e.remainingPieces <= 0);

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(orderProductionProvider(widget.orderId)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _OrderSummaryCard(
                  orderId: widget.orderId,
                  totalPieces: totalPieces,
                  inProgress: !allDone,
                ),
                const SizedBox(height: 12),
                const _GlobalStagesCard(),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مادة أو مقاس...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.trim().isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 48,
                      width: 92,
                      decoration: BoxDecoration(
                        color: AppTheme.brandDark.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune, size: 19, color: AppTheme.brandDark),
                          SizedBox(width: 6),
                          Text(
                            'تصفية',
                            style: TextStyle(
                              color: AppTheme.brandDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'مواد الطلبية (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Center(
                      child: Text(
                        'لا توجد مواد مطابقة لبحثك',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                else
                  for (final item in filtered) ...[
                    ProductionCard(item: item),
                    const SizedBox(height: 12),
                  ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandDark.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.brandDark.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.brandDark),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ملاحظة: المراحل المعروضة تعتمد على مواصفات كل مادة وقد تختلف من مادة لأخرى.',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: ${userErrorMessage(e)}')),
      ),
    );
  }

  List<OrderProductionItem> _filter(List<OrderProductionItem> items, String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((e) {
      final dims = '${e.length}x${e.width}';
      return e.specs.toLowerCase().contains(query) ||
          dims.toLowerCase().contains(query);
    }).toList();
  }
}

class _OrderSummaryCard extends StatelessWidget {
  final String orderId;
  final int totalPieces;
  final bool inProgress;

  const _OrderSummaryCard({
    required this.orderId,
    required this.totalPieces,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = inProgress ? AppTheme.warning : AppTheme.success;
    final statusText = inProgress ? 'قيد التنفيذ' : 'مكتمل';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              icon: Icons.calendar_today_outlined,
              label: 'تاريخ الطلب',
              value: Formatters.dateEnglishDigits(DateTime.now()),
            ),
          ),
          const VerticalDivider(width: 10, thickness: 1),
          Expanded(
            child: _SummaryCell(
              icon: Icons.inventory_2_outlined,
              label: 'إجمالي القطع',
              value: '$totalPieces',
            ),
          ),
          const VerticalDivider(width: 10, thickness: 1),
          Expanded(
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.watch_later_outlined, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'حالة الطلب',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SummaryCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 7),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _GlobalStagesCard extends StatelessWidget {
  const _GlobalStagesCard();

  @override
  Widget build(BuildContext context) {
    final stages = const <({IconData icon, String label})>[
      (icon: Icons.content_cut, label: 'القص'),
      (icon: Icons.auto_fix_high_outlined, label: 'روداج'),
      (icon: Icons.brush_outlined, label: 'صبغ'),
      (icon: Icons.local_fire_department_outlined, label: 'فرن'),
      (icon: Icons.layers_outlined, label: 'دبل'),
      (icon: Icons.edit_outlined, label: 'سيليكون'),
      (icon: Icons.grain, label: 'رمل'),
      (icon: Icons.layers_clear_outlined, label: 'لامنيت'),
      (icon: Icons.check_circle_outline, label: 'Done'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kSoftShadow,
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  Column(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(stages[i].icon, size: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stages[i].label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (i != stages.length - 1)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      width: 18,
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.success, label: 'مكتمل'),
              SizedBox(width: 18),
              _LegendDot(color: AppTheme.warning, label: 'جاري'),
              SizedBox(width: 18),
              _LegendDot(color: Colors.grey, label: 'لم يبدأ'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
