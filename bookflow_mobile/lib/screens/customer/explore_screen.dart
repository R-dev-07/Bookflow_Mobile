import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../cache.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../shared/notifications_screen.dart';
import '../sign_in_screen.dart';
import 'compare_list_screen.dart';
import 'compare_screen.dart';
import 'listing_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.guest = false});

  final bool guest;
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _type; // null = all
  List<ListingSummary> _items = [];
  int _page = 1, _seq = 0;
  bool _hasMore = false, _loading = false;
  bool _dimmed = false;
  bool _animateIn = false;
  Timer? _settleTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = DataCache.get<ListingsPage>('explore:all');
    if (cached != null) {
      _items = cached.items;
      _hasMore = cached.hasMore;
    }
    _animateIn = cached == null;
    _load(keep: cached != null);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _settleTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true, bool keep = false, bool dim = false}) async {
    final seq = ++_seq;
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _dimmed = dim;
      _error = null;
      if (reset && !keep) _items = [];
    });
    try {
      final r = await context.read<Api>().searchListings(q: _search.text, type: _type, page: _page);
      if (!mounted || seq != _seq) return;
      if (reset && _search.text.trim().isEmpty && _type == null) DataCache.put('explore:all', r);
      setState(() {
        _items = reset ? r.items : [..._items, ...r.items];
        _hasMore = r.hasMore;
      });
      if (_animateIn) _settleTimer ??= Timer(const Duration(milliseconds: 700), () => _animateIn = false);
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e.toString());
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = _dimmed = false);
    }
  }

  Future<void> _requery() => _load(keep: true, dim: true);

  void _onQuery(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _requery);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ListingSummary>>(
      valueListenable: CompareManager.items,
      builder: (context, compareList, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: Text(widget.guest ? 'Browse' : 'Explore'),
            actions: [
              if (widget.guest)
                TextButton(onPressed: () => requireSignIn(context), child: const Text('Sign in'))
              else
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_rounded, color: AppColors.text),
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
            ],
          ),
          bottomNavigationBar: compareList.isNotEmpty
              ? SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comparing ${compareList.length}/2 venues',
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 13),
                              ),
                              Text(
                                compareList.map((c) => c.title).join(' vs '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (compareList.length == 2)
                          BFButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompareVenuesScreen(
                                    venueA: compareList[0],
                                    venueB: compareList[1],
                                  ),
                                ),
                              );
                            },
                            label: 'Compare Now',
                            isFullWidth: false,
                          )
                        else
                          Text(
                            'Select 1 more',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.muted, size: 20),
                          onPressed: CompareManager.clear,
                        ),
                      ],
                    ),
                  ),
                )
              : (widget.guest
                  ? SafeArea(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Sign in to book venues, message providers and post reviews.',
                                style: TextStyle(color: AppColors.muted, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 10),
                            BFButton(
                              onPressed: () => requireSignIn(context),
                              label: 'Sign in',
                              isFullWidth: false,
                            ),
                          ],
                        ),
                      ),
                    )
                  : null),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: _onQuery,
                  onSubmitted: (_) => _requery(),
                  textInputAction: TextInputAction.search,
                  style: TextStyle(color: AppColors.text),
                  decoration: fieldDecoration('Search venues, services, cities', prefix: Icon(Icons.search, color: AppColors.muted))
                      .copyWith(
                        suffixIcon: _search.text.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close, color: AppColors.muted),
                                onPressed: () {
                                  _search.clear();
                                  _requery();
                                },
                              ),
                      ),
                ),
              ),
              // Category Filter Chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final t in const [(null, 'All Marketplace'), ('VENUE', 'Venues'), ('SERVICE', 'Services')])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.$2),
                          selected: _type == t.$1,
                          onSelected: (_) {
                            setState(() => _type = t.$1);
                            _requery();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _body(compareList)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(List<ListingSummary> compareList) {
    if (_loading && _items.isEmpty) return const LoadingView(kind: SkeletonKind.cards);
    if (_error != null && _items.isEmpty) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No results found',
        subtitle: 'Try searching for a different venue, service, or city.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(keep: true),
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      child: AnimatedOpacity(
        opacity: _dimmed ? 0.55 : 1,
        duration: AppMotion.fade,
        curve: AppMotion.outStrong,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: _items.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: _loading
                      ? CircularProgressIndicator(color: AppColors.accent)
                      : OutlinedButton(
                          onPressed: () {
                            _page++;
                            _load(reset: false);
                          },
                          child: const Text('Load More'),
                        ),
                ),
              );
            }
            final l = _items[i];
            final card = ListingCard(
              listing: l,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListingDetailScreen(listingId: l.id, title: l.title),
                ),
              ),
              onCompareTap: () => CompareManager.toggle(l),
              isCompared: compareList.any((c) => c.id == l.id),
            );
            return _animateIn && i < 5 ? FadeSlideIn(index: i, child: card) : card;
          },
        ),
      ),
    );
  }
}
