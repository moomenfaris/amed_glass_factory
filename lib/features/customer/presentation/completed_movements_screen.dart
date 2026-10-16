import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/error_message.dart';
import '../../../core/services/home_entry_metadata_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_bar_title.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../employee/presentation/widgets/employee_drawer.dart';
import '../../orders/data/models/order_production.dart';
import '../../orders/presentation/widgets/production_card.dart';
import '../../orders/providers/order_production_provider.dart';

class CompletedMovementsScreen extends ConsumerStatefulWidget {
  const CompletedMovementsScreen({super.key});

  @override
  ConsumerState<CompletedMovementsScreen> createState() =>
      _CompletedMovementsScreenState();
}

class _CompletedMovementsScreenState
    extends ConsumerState<CompletedMovementsScreen> {
  final HomeEntryMetadataService _homeEntryMetadataService =
      HomeEntryMetadataService();
  String _query = '';
  int? _lastSentForUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendEmployeeHomeEntryMetadataIfNeeded();
    });
  }

  Future<void> _sendEmployeeHomeEntryMetadataIfNeeded() async {
    final auth = ref.read(authStateProvider);
    final user = auth.user;
    if (user == null || user.role != 'employee') return;

    final userId = user.userId ?? int.tryParse(user.id);
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

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authStateProvider).role;
    final isEmployee = role == 'employee';
    final async = role == 'employee'
        ? ref.watch(employeeCompletedMovementsProvider)
        : ref.watch(completedMovementsProvider);

    return Scaffold(
      drawer: isEmployee ? const EmployeeDrawer() : null,
      appBar: AppBar(
        title: AppBarTitle(isEmployee ? 'مراحل الانتاج' : 'الحركات المكتملة'),
      ),
      body: async.when(
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.task_alt_outlined,
              message: isEmployee
                  ? 'لا توجد مراحل إنتاج'
                  : 'لا توجد حركات مكتملة',
            );
          }
          final orders = _groupByOrder(items);
          final visible = isEmployee
              ? _applyEmployeeFilter(orders, _query)
              : orders;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              isEmployee
                  ? employeeCompletedMovementsProvider
                  : completedMovementsProvider,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (isEmployee) ...[
                  TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'فلترة باسم العميل أو رقم الطلبية',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      message: 'لا توجد نتائج مطابقة',
                    ),
                ],
                for (final group in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompletedOrderCard(
                      group: group,
                      doneFromStatus: isEmployee,
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

  static List<_CompletedOrderGroup> _groupByOrder(
    List<OrderProductionItem> items,
  ) {
    final groups = <String, _CompletedOrderGroup>{};

    for (final item in items) {
      final customerName = (item.customerName ?? '').trim();
      final orderNumber = (item.orderNumber ?? '').trim();
      final projectName = (item.projectName ?? '').trim();
      final key = '$customerName|$orderNumber|$projectName';

      final existing = groups[key];
      if (existing == null) {
        groups[key] = _CompletedOrderGroup(
          customerName: customerName,
          orderNumber: orderNumber,
          projectName: projectName,
          items: [item],
        );
      } else {
        existing.items.add(item);
      }
    }

    return groups.values.toList();
  }

  static List<_CompletedOrderGroup> _applyEmployeeFilter(
    List<_CompletedOrderGroup> groups,
    String query,
  ) {
    if (query.isEmpty) return groups;
    final q = query.toLowerCase();
    return groups.where((g) {
      final customer = g.customerName.toLowerCase();
      final order = g.orderNumber.toLowerCase();
      return customer.contains(q) || order.contains(q);
    }).toList();
  }
}

class _CompletedOrderGroup {
  final String customerName;
  final String orderNumber;
  final String projectName;
  final List<OrderProductionItem> items;

  _CompletedOrderGroup({
    required this.customerName,
    required this.orderNumber,
    required this.projectName,
    required this.items,
  });
}

class _CompletedOrderCard extends StatefulWidget {
  final _CompletedOrderGroup group;
  final bool doneFromStatus;

  const _CompletedOrderCard({
    required this.group,
    required this.doneFromStatus,
  });

  @override
  State<_CompletedOrderCard> createState() => _CompletedOrderCardState();
}

class _CompletedOrderCardState extends State<_CompletedOrderCard> {
  bool _expanded = false;

  int? _invoiceIdFromOrderNumber(String? orderNumber) {
    final raw = (orderNumber ?? '').trim();
    if (raw.isEmpty) return null;

    final direct = int.tryParse(raw);
    if (direct != null) return direct;

    final digits = RegExp(r'(\d+)').firstMatch(raw)?.group(1);
    return digits == null ? null : int.tryParse(digits);
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.group.customerName;
    final orderNumber = widget.group.orderNumber;
    final projectName = widget.group.projectName;
    final invoiceId = _invoiceIdFromOrderNumber(orderNumber);

    return AppCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F2FF),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(
                                    0xFF0A84FF,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'الطلبية: ${orderNumber.isEmpty ? '-' : orderNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0A4D8F),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.group.items.length} فقرة',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          projectName.isEmpty ? 'بدون اسم مشروع' : projectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (customerName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.person_outline,
                                size: 15,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF0A4D8F),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                for (var i = 0; i < widget.group.items.length; i++) ...[
                  ProductionCard(
                    item: widget.group.items[i],
                    forceDoneStage: true,
                    doneFromStatus: widget.doneFromStatus,
                    showOrderMeta: false,
                    collapsibleDetails: false,
                  ),
                  if (i != widget.group.items.length - 1)
                    const SizedBox(height: 10),
                ],
                if (widget.doneFromStatus && invoiceId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/invoices/$invoiceId'),
                      icon: const Icon(Icons.receipt_long_outlined),
                      label: const Text('الفاتورة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA8C00),
                        side: const BorderSide(color: Color(0xFFEA8C00)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
