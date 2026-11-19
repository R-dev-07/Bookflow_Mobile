import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../utils.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) => switch (type) {
    'BOOKING_REQUEST' => Icons.inbox_outlined,
    'BOOKING_UPDATE' => Icons.event_available_outlined,
    'MESSAGE' => Icons.chat_bubble_outline,
    'REVIEW' => Icons.star_outline_rounded,
    'LISTING_APPROVED' => Icons.check_circle_outline,
    'LISTING_REJECTED' => Icons.report_gmailerrorred_outlined,
    _ => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureView<NotificationsData>(
        cacheKey: 'notifications',
        skeleton: SkeletonKind.rows,
        load: () async {
          final data = await api.notifications();
          if (data.unread > 0) api.markAllNotificationsRead().catchError((_) {});
          return data;
        },
        builder: (context, data, reload) {
          if (data.items.isEmpty) {
            return RefreshList(
              onRefresh: reload,
              children: const [
                SizedBox(height: 80),
                EmptyState(icon: Icons.notifications_off_outlined, title: 'You are all caught up'),
              ],
            );
          }
          return RefreshList(
            onRefresh: reload,
            children: [
              for (final n in data.items)
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primary.withValues(alpha: n.isRead ? 0.08 : 0.2),
                        child: Icon(_icon(n.type), color: cs.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(n.message, style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timeAgo(n.createdAt), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
