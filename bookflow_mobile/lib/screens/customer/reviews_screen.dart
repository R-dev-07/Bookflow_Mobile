import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../utils.dart';
import '../../widgets/common.dart';

/// Bottom sheet to write a review. Returns true if a review was posted.
Future<bool> showReviewSheet(BuildContext context, {required String listingId, required String title}) async {
  final posted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    sheetAnimationStyle: AppSpring.sheet,
    builder: (_) => _ReviewSheet(listingId: listingId, title: title),
  );
  if (posted == true && context.mounted) showSnack(context, 'Thanks for your review!');
  return posted == true;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.listingId, required this.title});
  final String listingId, title;
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final text = _comment.text.trim();
      await context.read<Api>().postReview(
        listingId: widget.listingId,
        rating: _rating,
        comment: text.isEmpty ? null : text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review ${widget.title}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                onPressed: () => setState(() => _rating = i),
                icon: Icon(
                  i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34,
                  color: const Color(0xFFF59E0B),
                ),
              ),
          ],
        ),
        TextField(
          controller: _comment,
          maxLines: 4,
          decoration: fieldDecoration('Share your experience (optional)'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: _busy ? null : _submit, child: const Text('Submit review')),
        ),
      ],
    ),
  );
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My reviews')),
      body: FutureView<ReviewsData>(
        cacheKey: 'my-reviews',
        skeleton: SkeletonKind.rows,
        load: api.reviews,
        builder: (context, data, reload) => RefreshList(
          onRefresh: reload,
          children: [
            if (data.pending.isNotEmpty) ...[
              const SectionTitle('Waiting for your review'),
              for (final p in data.pending)
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(p.listingTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      FilledButton.tonal(
                        onPressed: () async {
                          final done = await showReviewSheet(
                            context,
                            listingId: p.listingId,
                            title: p.listingTitle,
                          );
                          if (done) await reload();
                        },
                        child: const Text('Write review'),
                      ),
                    ],
                  ),
                ),
            ],
            const SectionTitle('Reviews I wrote'),
            if (data.given.isEmpty)
              const EmptyState(
                icon: Icons.rate_review_outlined,
                title: 'No reviews yet',
                subtitle: 'Complete a booking to leave a review.',
              ),
            for (final r in data.given)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(r.listingTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        RatingStars(r.rating.toDouble()),
                      ],
                    ),
                    if (r.comment != null && r.comment!.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.comment!)),
                    const SizedBox(height: 4),
                    Text(fmtDate(r.createdAt), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
