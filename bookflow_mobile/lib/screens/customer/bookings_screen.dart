import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import 'booking_detail_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});
  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _filter = 'All';

  bool _match(BookingModel b) {
    switch (_filter) {
      case 'Active':
        return b.status == 'PENDING' || b.status == 'APPROVED';
      case 'Past':
        return b.status == 'COMPLETED' || b.status == 'CANCELLED' || b.status == 'REJECTED';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Bookings')),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in const ['All', 'Active', 'Past'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureView<List<BookingModel>>(
              cacheKey: 'bookings',
              skeleton: SkeletonKind.rows,
              load: api.bookings,
              builder: (context, all, reload) {
                final items = all.where(_match).toList();
                if (items.isEmpty) {
                  return RefreshList(
                    onRefresh: reload,
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.event_busy_outlined,
                        title: 'No bookings found',
                        subtitle: 'Explore venues and services on the Explore tab.',
                      ),
                    ],
                  );
                }
                return RefreshList(
                  onRefresh: reload,
                  children: [
                    for (final b in items)
                      AppCard(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)),
                          );
                          reload();
                        },
                        child: Row(
                          children: [
                            NetImage(b.image, width: 76, height: 76, radius: 14, icon: Icons.event),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.headline,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b.eventType} · ${fmtDate(b.eventDate)}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      StatusChip(b.status),
                                      const Spacer(),
                                      Text(
                                        money(b.total),
                                        style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
