import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../shared/notifications_screen.dart';

class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Provider Hub'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: AppColors.text),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: FutureView<Map<String, dynamic>>(
        cacheKey: 'prov-summary',
        skeleton: SkeletonKind.stats,
        load: api.providerSummary,
        builder: (context, m, reload) {
          final rating = m['avgRating'];
          return RefreshList(
            onRefresh: reload,
            children: [
              Text(
                'Welcome, ${m['businessName']}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.4,
                ),
              ),
              if (m['isVerified'] != true)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(
                    'Your provider profile is undergoing verification.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 12),
              StatGrid(
                tiles: [
                  StatTile(
                    label: 'Total Revenue',
                    amount: (m['revenue'] as num?) ?? 0,
                    format: money,
                    icon: Icons.payments_outlined,
                  ),
                  StatTile(
                    label: 'Pending Requests',
                    amount: (m['pendingRequests'] as num?) ?? 0,
                    icon: Icons.inbox_outlined,
                  ),
                  StatTile(
                    label: 'Upcoming Bookings',
                    amount: (m['upcomingBookings'] as num?) ?? 0,
                    icon: Icons.event_available_outlined,
                  ),
                  StatTile(
                    label: '${m['reviewCount']} Reviews',
                    value: rating == null ? '-' : (rating as num).toStringAsFixed(1),
                    icon: Icons.star_outline_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProviderReviewsScreen()),
                    ),
                  ),
                  StatTile(
                    label: 'Live Listings',
                    amount: (m['listingsApproved'] as num?) ?? 0,
                    icon: Icons.storefront_outlined,
                  ),
                  StatTile(
                    label: 'Awaiting Approval',
                    amount: (m['listingsPending'] as num?) ?? 0,
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Customer Reviews')),
      body: FutureView<List<ReviewItem>>(
        cacheKey: 'prov-reviews',
        skeleton: SkeletonKind.rows,
        load: api.providerReviews,
        builder: (context, items, reload) => RefreshList(
          onRefresh: reload,
          children: [
            if (items.isEmpty) const EmptyState(icon: Icons.rate_review_outlined, title: 'No reviews yet'),
            for (final r in items)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.reviewerName, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text)),
                        ),
                        RatingStars(r.rating.toDouble()),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(r.listingTitle, style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (r.comment != null && r.comment!.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 8), child: Text(r.comment!, style: TextStyle(color: AppColors.text))),
                    const SizedBox(height: 6),
                    Text(fmtDate(r.createdAt), style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
