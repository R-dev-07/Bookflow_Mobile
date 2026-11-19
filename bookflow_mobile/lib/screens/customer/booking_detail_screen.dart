import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../shared/messages_screens.dart';
import 'reviews_screen.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Booking Summary')),
      body: FutureView<(BookingModel, Set<String>)>(
        cacheKey: 'booking:$bookingId',
        skeleton: SkeletonKind.detail,
        load: () async {
          final r = await Future.wait([api.booking(bookingId), api.payments()]);
          final paid = (r[1] as PaymentsData).items.where((p) => p.paid).map((p) => p.bookingItemId).toSet();
          return (r[0] as BookingModel, paid);
        },
        builder: (context, data, reload) {
          final b = data.$1;
          final paid = data.$2;

          Future<void> run(Future<void> Function() action, String okMsg) async {
            try {
              await action();
              if (context.mounted) showSnack(context, okMsg);
              await reload();
            } catch (e) {
              if (context.mounted) showSnack(context, e.toString(), error: true);
            }
          }

          return RefreshList(
            onRefresh: reload,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.eventType,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  StatusChip(b.status),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  children: [
                    KeyValue('Event Date', fmtDateLong(b.eventDate)),
                    KeyValue('Guest Count', '${b.guestCount} guests'),
                    KeyValue('Requested On', fmtDate(b.createdAt)),
                    if (b.notes != null && b.notes!.isNotEmpty) KeyValue('Notes', b.notes!),
                    KeyValue('Estimated Total', money(b.total)),
                  ],
                ),
              ),
              const SectionTitle('Items & Services'),
              for (final i in b.items)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              i.listingTitle,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
                            ),
                          ),
                          StatusChip(i.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${i.providerName}${i.tierName != null ? ' · ${i.tierName}' : ''}',
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        money(i.quotedPrice),
                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 17),
                      ),
                      if (i.rejectionReason != null && i.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Reason: ${i.rejectionReason}', style: const TextStyle(color: AppColors.statusRejected)),
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          BFButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(bookingItemId: i.id, title: i.listingTitle),
                              ),
                            ),
                            icon: Icons.chat_bubble_outline,
                            label: 'Message Provider',
                            isSecondary: true,
                            isFullWidth: false,
                          ),
                          if ((i.status == 'APPROVED' || i.status == 'COMPLETED') && !paid.contains(i.id))
                            BFButton(
                              onPressed: () async {
                                final ok = await confirm(
                                  context,
                                  'Pay ${money(i.quotedPrice)}?',
                                  'Payments are currently a placeholder for testing.',
                                  confirmLabel: 'Pay Now (Mock)',
                                );
                                if (ok) await run(() => api.payMock(i.id), 'Payment recorded');
                              },
                              icon: Icons.payments_outlined,
                              label: 'Pay Now',
                              isFullWidth: false,
                            ),
                          if (paid.contains(i.id))
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.statusActive.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.statusActive),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.statusActive),
                                  SizedBox(width: 6),
                                  Text('Paid', style: TextStyle(color: AppColors.statusActive, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          if (i.status == 'COMPLETED')
                            BFButton(
                              onPressed: () async {
                                final done = await showReviewSheet(
                                  context,
                                  listingId: i.listingId,
                                  title: i.listingTitle,
                                );
                                if (done) await reload();
                              },
                              icon: Icons.star_outline_rounded,
                              label: 'Review',
                              isSecondary: true,
                              isFullWidth: false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (b.canCancel) ...[
                const SizedBox(height: 12),
                BFButton(
                  onPressed: () async {
                    final ok = await confirm(
                      context,
                      'Cancel this booking?',
                      'The provider will be notified immediately.',
                      confirmLabel: 'Cancel Booking',
                    );
                    if (ok) await run(() => api.cancelBooking(b.id), 'Booking cancelled');
                  },
                  label: 'Cancel Booking',
                  isSecondary: true,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
