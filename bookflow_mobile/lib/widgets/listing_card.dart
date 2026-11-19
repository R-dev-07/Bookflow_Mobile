import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils.dart';
import 'common.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.trailing,
    this.onCompareTap,
    this.isCompared = false,
  });
  final ListingSummary listing;
  final VoidCallback? onTap;
  final Widget? trailing;
  final VoidCallback? onCompareTap;
  final bool isCompared;

  @override
  Widget build(BuildContext context) {
    final l = listing;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: NetImage(
                  l.image,
                  radius: 0,
                  width: double.infinity,
                  icon: l.isVenue ? Icons.apartment_rounded : Icons.celebration_rounded,
                ),
              ),
              // Dark gradient overlay for bottom text contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Category tag badge (top left)
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bg.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        l.isVenue ? Icons.apartment_rounded : Icons.celebration_rounded,
                        size: 13,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        l.isVenue ? 'Venue' : (l.category ?? 'Service'),
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Rating badge (top right)
              if (l.avgRating != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bg.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          l.avgRating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (l.verified) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.verified_rounded, size: 18, color: AppColors.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 15, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [l.providerName, if (l.place.isNotEmpty) l.place].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                if (l.status == 'REJECTED' && l.rejectionReason != null && l.rejectionReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Rejected: ${l.rejectionReason}',
                      style: const TextStyle(color: AppColors.statusRejected, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (l.capacity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people_alt_outlined, size: 14, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              'Up to ${l.capacity}',
                              style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (onCompareTap != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onCompareTap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompared ? AppColors.accent.withValues(alpha: 0.18) : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isCompared ? AppColors.accent : AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompared ? Icons.check_circle_rounded : Icons.compare_arrows_rounded,
                                size: 14,
                                color: isCompared ? AppColors.accent : AppColors.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompared ? 'Compared' : 'Compare',
                                style: TextStyle(
                                  color: isCompared ? AppColors.accent : AppColors.muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (trailing != null)
                      trailing!
                    else if (l.minPrice != null)
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'From ',
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                            TextSpan(
                              text: money(l.minPrice),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
