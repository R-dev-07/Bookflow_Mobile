import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../config.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../shared/messages_screens.dart';
import '../shared/provider_public_profile_screen.dart';
import '../sign_in_screen.dart';
import 'booking_flow_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId, required this.title});
  final String listingId, title;

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: FutureView<ListingDetail>(
        cacheKey: 'listing:$listingId',
        skeleton: SkeletonKind.detail,
        load: () => api.listing(listingId),
        builder: (context, d, reload) => _Detail(detail: d),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});
  final ListingDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    final s = d.summary;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _Gallery(photos: d.photos),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      s.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  if (s.verified) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.verified_rounded, color: AppColors.accent, size: 22),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (s.avgRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '${s.avgRating!.toStringAsFixed(1)} (${s.reviewCount} reviews)',
                            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  if (s.place.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place_outlined, size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(s.place, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  if (s.capacity != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_alt_outlined, size: 16, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text('Up to ${s.capacity} guests', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProviderPublicProfileScreen(providerId: s.providerId),
                  ),
                ),
                child: Text(
                  'Offered by ${s.providerName}',
                  style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const SectionTitle('About this listing'),
              Text(
                s.description ?? '',
                style: TextStyle(color: AppColors.text, height: 1.5, fontSize: 14),
              ),
              if (d.location != null && d.location!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.map_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(d.location!, style: TextStyle(color: AppColors.text, fontSize: 13)),
                    ),
                  ],
                ),
              ],
              if (d.amenities.isNotEmpty) ...[
                const SectionTitle('Amenities & Features'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in d.amenities)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          a,
                          style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
              const SectionTitle('Pricing Options'),
              for (final t in d.tiers)
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text)),
                            if (t.description != null && t.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(t.description!, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        money(t.price),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
              if (d.addOns.isNotEmpty) ...[
                const SectionTitle('Add-on Services'),
                for (final a in d.addOns)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.name + (a.isRequired ? ' (Required)' : ''),
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                              ),
                              if (a.description != null)
                                Text(a.description!, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '+${money(a.price)}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
              ],
              SectionTitle('Reviews (${d.reviews.length})'),
              if (d.reviews.isEmpty)
                Text('No reviews yet for this listing.', style: TextStyle(color: AppColors.muted)),
              for (final r in d.reviews)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.reviewerName, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                          ),
                          RatingStars(r.rating.toDouble()),
                        ],
                      ),
                      if (r.comment != null && r.comment!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(r.comment!, style: TextStyle(color: AppColors.text, height: 1.4)),
                        ),
                      const SizedBox(height: 6),
                      Text(fmtDate(r.createdAt), style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Sticky Bottom Booking Action Bar
        SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Starting from', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      Text(
                        money(s.minPrice),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (context.read<AppState>().me == null) {
                      requireSignIn(context, message: 'Sign in to negotiate with providers.');
                    } else {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => _NegotiateSheet(detail: d),
                      );
                    }
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 16),
                  label: const Text('Negotiate'),
                ),
                const SizedBox(width: 8),
                BFButton(
                  onPressed: d.tiers.isEmpty
                      ? null
                      : () {
                          if (context.read<AppState>().me == null) {
                            requireSignIn(
                              context,
                              message: 'Sign in or create an account to request this booking.',
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => BookingFlowScreen(detail: d)),
                            );
                          }
                        },
                  label: context.watch<AppState>().me == null ? 'Sign In' : 'Request',
                  isFullWidth: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NegotiateSheet extends StatefulWidget {
  const _NegotiateSheet({required this.detail});
  final ListingDetail detail;
  @override
  State<_NegotiateSheet> createState() => _NegotiateSheetState();
}

class _NegotiateSheetState extends State<_NegotiateSheet> {
  final _offer = TextEditingController();
  final _guests = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _offer.dispose();
    _guests.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    final offerVal = double.tryParse(_offer.text.trim());
    if (offerVal == null || offerVal <= 0) {
      showSnack(context, 'Enter a valid offer price', error: true);
      return;
    }
    if (widget.detail.tiers.isEmpty) {
      showSnack(context, 'This listing has no pricing tier available', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final api = context.read<Api>();
      final guestCount = int.tryParse(_guests.text.trim()) ?? 10;
      final tierId = widget.detail.tiers.first.id;
      final eventDate = DateTime.now().add(const Duration(days: 14));

      // 1. Create booking request for negotiation
      final booking = await api.createBooking(
        listingId: widget.detail.summary.id,
        pricingTierId: tierId,
        addOnIds: [],
        eventType: 'Negotiation Offer',
        eventDate: eventDate,
        guestCount: guestCount,
        notes: 'Negotiation offer: ${money(offerVal)} - ${_notes.text.trim()}',
      );

      final bookingItemId = booking.items.first.id;

      // 2. Post negotiation message in conversation thread
      final msg = '🤝 NEGOTIATION OFFER:\n'
          'Listing: ${widget.detail.summary.title}\n'
          'Offer Price: ${money(offerVal)}\n'
          'Guests: $guestCount\n'
          'Note: ${_notes.text.trim().isEmpty ? "No additional note" : _notes.text.trim()}';

      await api.sendMessage(bookingItemId, msg);

      if (!mounted) return;
      Navigator.pop(context);
      showSnack(context, 'Negotiation offer sent to provider!');

      // 3. Open ChatScreen for live negotiation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            bookingItemId: bookingItemId,
            title: widget.detail.summary.title,
          ),
        ),
      );
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, color: AppColors.accent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Negotiate with Provider',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Send your custom price offer directly to ${widget.detail.summary.providerName}',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _offer,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Your Offer Price (${AppConfig.currencySymbol})', hint: 'e.g. 3500'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _guests,
            keyboardType: TextInputType.number,
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Estimated Guests (optional)', hint: 'e.g. 50'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Negotiation Note', hint: 'e.g. We love the venue, can we negotiate for Sunday?'),
          ),
          const SizedBox(height: 20),
          BFButton(
            onPressed: _busy ? null : _sendOffer,
            label: _busy ? 'Sending...' : 'Send Offer to Provider',
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.photos});
  final List<String> photos;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos.isEmpty ? <String?>[null] : widget.photos;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: photos.length,
              itemBuilder: (_, i) {
                final url = photos[i];
                final isVideo = url != null && (url.startsWith('data:video/') || url.contains('.mp4') || url.contains('video'));
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(url, radius: 0, width: double.infinity, height: 240),
                    if (isVideo)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                        ),
                      ),
                    if (isVideo)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('VIDEO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: PageDots(
                    controller: _controller,
                    count: photos.length,
                    activeColor: AppColors.accent,
                    inactiveColor: Colors.white.withValues(alpha: 0.4),
                    dotSize: 7,
                    gap: 6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
