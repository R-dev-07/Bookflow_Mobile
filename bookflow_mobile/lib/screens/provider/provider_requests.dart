import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../shared/messages_screens.dart';

class ProviderRequestsScreen extends StatefulWidget {
  const ProviderRequestsScreen({super.key});
  @override
  State<ProviderRequestsScreen> createState() => _ProviderRequestsScreenState();
}

class _ProviderRequestsScreenState extends State<ProviderRequestsScreen> {
  String? _status = 'PENDING'; // null = all

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Booking Requests')),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in const [
                  ('PENDING', 'Pending'),
                  ('APPROVED', 'Approved'),
                  ('COMPLETED', 'Completed'),
                  (null, 'All'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _status == f.$1,
                      onSelected: (_) => setState(() => _status = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureView<List<ProviderRequest>>(
              cacheKey: 'prov-req:$_status',
              skeleton: SkeletonKind.rows,
              key: ValueKey(_status),
              load: () => api.providerRequests(status: _status),
              builder: (context, items, reload) {
                Future<void> act(String itemId, String action, {String? reason, double? price}) async {
                  try {
                    await api.requestAction(itemId, action, reason: reason, quotedPrice: price);
                    if (context.mounted) showSnack(context, 'Request updated');
                    await reload();
                  } catch (e) {
                    if (context.mounted) showSnack(context, e.toString(), error: true);
                  }
                }

                if (items.isEmpty) {
                  return RefreshList(
                    onRefresh: reload,
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(icon: Icons.inbox_outlined, title: 'No requests found'),
                    ],
                  );
                }
                return RefreshList(
                  onRefresh: reload,
                  children: [
                    for (final r in items)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.listingTitle,
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
                                  ),
                                ),
                                StatusChip(r.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            KeyValue('Customer', r.customerName),
                            KeyValue('Event', '${r.eventType} · ${r.guestCount} guests'),
                            KeyValue('Date', fmtDateLong(r.eventDate)),
                            if (r.tierName != null) KeyValue('Package', r.tierName!),
                            KeyValue('Price', money(r.quotedPrice)),
                            if (r.notes != null && r.notes!.isNotEmpty) KeyValue('Notes', r.notes!),
                            if (r.rejectionReason != null && r.rejectionReason!.isNotEmpty)
                              KeyValue('Declined Reason', r.rejectionReason!),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (r.status == 'PENDING') ...[
                                  BFButton(
                                    onPressed: () async {
                                      final price = await _askPrice(context, r.quotedPrice);
                                      if (price != null) await act(r.itemId, 'approve', price: price);
                                    },
                                    icon: Icons.check_rounded,
                                    label: 'Approve',
                                    isFullWidth: false,
                                  ),
                                  BFButton(
                                    onPressed: () async {
                                      final reason = await askText(
                                        context,
                                        'Decline Request',
                                        hint: 'Reason (optional)',
                                      );
                                      if (reason != null)
                                        await act(r.itemId, 'reject', reason: reason.isEmpty ? null : reason);
                                    },
                                    icon: Icons.close_rounded,
                                    label: 'Decline',
                                    isSecondary: true,
                                    isFullWidth: false,
                                  ),
                                ],
                                if (r.status == 'APPROVED')
                                  BFButton(
                                    onPressed: () => act(r.itemId, 'complete'),
                                    icon: Icons.task_alt_rounded,
                                    label: 'Mark Complete',
                                    isFullWidth: false,
                                  ),
                                BFButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ChatScreen(bookingItemId: r.itemId, title: r.listingTitle),
                                    ),
                                  ),
                                  icon: Icons.chat_bubble_outline,
                                  label: 'Message',
                                  isSecondary: true,
                                  isFullWidth: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Future<double?> _askPrice(BuildContext context, double? current) async {
  final ctrl = TextEditingController(text: current == null ? '' : current.toStringAsFixed(2));
  final r = await showDialog<double>(
    context: context,
    builder: (c) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.border),
      ),
      title: Text('Approve Booking Request', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: AppColors.text),
        decoration: fieldDecoration('Final Price (K)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
        ),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.trim());
            if (v == null || v < 0) return;
            Navigator.pop(c, v);
          },
          child: const Text('Approve'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return r;
}
