import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../customer/listing_detail_screen.dart';

class ProviderPublicProfileScreen extends StatelessWidget {
  const ProviderPublicProfileScreen({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Provider Profile')),
      body: FutureView<Map<String, dynamic>>(
        cacheKey: 'provider:$providerId',
        skeleton: SkeletonKind.detail,
        load: () => api.providerPublicProfile(providerId),
        builder: (context, data, reload) {
          final businessName = data['businessName'] as String? ?? 'Provider';
          final description = data['description'] as String?;
          final isVerified = data['isVerified'] == true;
          final imageUrl = data['imageUrl'] as String?;
          final email = data['email'] as String? ?? '';
          final avgRating = data['avgRating'] as double?;
          final reviewCount = data['reviewCount'] as int? ?? 0;
          final rawListings = (data['listings'] as List?) ?? [];
          final listings = rawListings.map((j) => ListingSummary.fromJson(j as Map<String, dynamic>)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Profile Card
              AppCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? Text(
                              businessName[0].toUpperCase(),
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.accent),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          businessName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.verified_rounded, color: AppColors.accent, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    if (avgRating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${avgRating.toStringAsFixed(1)} ($reviewCount reviews)',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted, height: 1.4, fontSize: 13.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SectionTitle('Listings by this Provider'),
              if (listings.isEmpty)
                const EmptyState(icon: Icons.storefront_outlined, title: 'No active listings found'),
              for (final l in listings)
                ListingCard(
                  listing: l,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listingId: l.id, title: l.title),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
