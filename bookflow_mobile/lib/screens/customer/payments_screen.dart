import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../utils.dart';
import '../../widgets/common.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: FutureView<PaymentsData>(
        cacheKey: 'payments',
        skeleton: SkeletonKind.rows,
        load: api.payments,
        builder: (context, data, reload) => RefreshList(
          onRefresh: reload,
          children: [
            StatGrid(
              tiles: [
                StatTile(
                  label: 'Due',
                  amount: data.totalDue,
                  format: money,
                  icon: Icons.hourglass_bottom_rounded,
                ),
                StatTile(
                  label: 'Paid',
                  amount: data.totalPaid,
                  format: money,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Payments are a placeholder: no real money moves yet.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SectionTitle('Approved bookings'),
            if (data.items.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing to pay yet',
                subtitle: 'Approved bookings appear here.',
              ),
            for (final p in data.items)
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            fmtDate(p.eventDate),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          Text(money(p.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (p.paid)
                      const Chip(avatar: Icon(Icons.check_circle, size: 18), label: Text('Paid'))
                    else
                      FilledButton(
                        onPressed: () async {
                          final ok = await confirm(
                            context,
                            'Pay ${money(p.amount)}?',
                            'Mock payment: no money is charged.',
                            confirmLabel: 'Pay (mock)',
                          );
                          if (!ok) return;
                          try {
                            await api.payMock(p.bookingItemId);
                            if (context.mounted) showSnack(context, 'Payment recorded (mock)');
                            await reload();
                          } catch (e) {
                            if (context.mounted) showSnack(context, e.toString(), error: true);
                          }
                        },
                        child: const Text('Pay'),
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
