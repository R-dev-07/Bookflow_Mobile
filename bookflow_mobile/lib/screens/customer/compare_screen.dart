import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';

class CompareVenuesScreen extends StatelessWidget {
  const CompareVenuesScreen({
    super.key,
    required this.venueA,
    required this.venueB,
  });

  final ListingSummary venueA;
  final ListingSummary venueB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Compare Venues'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header: Venue Cards Side-by-Side
            Row(
              children: [
                Expanded(child: _venueHeader(venueA)),
                const SizedBox(width: 12),
                Expanded(child: _venueHeader(venueB)),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle('Side-by-Side Comparison'),
            _compareRow('Type / Category', venueA.isVenue ? 'Venue' : 'Service', venueB.isVenue ? 'Venue' : 'Service'),
            _compareRow('Starting Price', money(venueA.minPrice), money(venueB.minPrice), isPrice: true),
            _compareRow(
              'Capacity',
              venueA.capacity != null ? '${venueA.capacity} guests' : 'N/A',
              venueB.capacity != null ? '${venueB.capacity} guests' : 'N/A',
            ),
            _compareRow(
              'Location',
              venueA.place.isNotEmpty ? venueA.place : 'Not specified',
              venueB.place.isNotEmpty ? venueB.place : 'Not specified',
            ),
            _compareRow(
              'Rating',
              venueA.avgRating != null ? '${venueA.avgRating!.toStringAsFixed(1)} ★ (${venueA.reviewCount})' : 'No ratings yet',
              venueB.avgRating != null ? '${venueB.avgRating!.toStringAsFixed(1)} ★ (${venueB.reviewCount})' : 'No ratings yet',
            ),
            _compareRow(
              'Verified',
              venueA.verified ? 'Verified Provider ✓' : 'Standard',
              venueB.verified ? 'Verified Provider ✓' : 'Standard',
            ),
            _compareRow('Provider', venueA.providerName, venueB.providerName),
          ],
        ),
      ),
    );
  }

  Widget _venueHeader(ListingSummary v) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          NetImage(v.image, width: double.infinity, height: 110, radius: 12),
          const SizedBox(height: 10),
          Text(
            v.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            money(v.minPrice),
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _compareRow(String label, String valA, String valB, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valA,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isPrice ? AppColors.accent : AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(height: 16, width: 1, color: AppColors.border),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    valB,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isPrice ? AppColors.accent : AppColors.text,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
