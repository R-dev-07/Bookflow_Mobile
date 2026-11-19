import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import 'tab_bar_spec.dart';
import 'variants/glass_tab_bar.dart';
import 'variants/quiet_tab_bar.dart';
import 'variants/scrubber_tab_bar.dart';

const _tabs = [
  TabSpec('Explore', Icons.explore_outlined, Icons.explore),
  TabSpec('Bookings', Icons.event_note_outlined, Icons.event_note),
  TabSpec('Messages', Icons.chat_bubble_outline, Icons.chat_bubble),
  TabSpec('Account', Icons.person_outline, Icons.person),
];

class _Variant {
  const _Variant({
    required this.name,
    required this.axis,
    required this.overlapsContent,
    required this.blockHeight,
    required this.build,
  });
  final String name;
  final String axis;

  /// True when content scrolls underneath the bar (so the list needs extra bottom padding).
  final bool overlapsContent;

  /// Space the bar occupies at the bottom (excluding the device safe area).
  final double blockHeight;
  final Widget Function(int index, TabSelected onSelect) build;
}

final _variants = <_Variant>[
  _Variant(
    name: 'Glass',
    axis: 'Material: translucent blur, content scrolls beneath',
    overlapsContent: true,
    blockHeight: GlassTabBar.height,
    build: (i, s) => GlassTabBar(tabs: _tabs, index: i, onSelect: s),
  ),
  _Variant(
    name: 'Scrubber',
    axis: 'Interaction: floating pill you can drag across (momentum + rubber band)',
    overlapsContent: true,
    blockHeight: ScrubberTabBar.height + ScrubberTabBar.bottomGap,
    build: (i, s) => ScrubberTabBar(tabs: _tabs, index: i, onSelect: s),
  ),
  _Variant(
    name: 'Quiet',
    axis: 'Density: solid, labelled, no blur and almost no motion',
    overlapsContent: false,
    blockHeight: QuietTabBar.height,
    build: (i, s) => QuietTabBar(tabs: _tabs, index: i, onSelect: s),
  ),
];

/// Full-size harness: ONE variant at a time inside a realistic app screen, switched instantly.
/// Flip with the picker, ← / → (or [ and ]), or the keys 1-3.
class TabBarPrototype extends StatefulWidget {
  const TabBarPrototype({super.key});
  @override
  State<TabBarPrototype> createState() => _TabBarPrototypeState();
}

class _TabBarPrototypeState extends State<TabBarPrototype> {
  int _variant = 0;
  int _tab = 0;

  void _flip(int to) =>
      setState(() => _variant = (to % _variants.length + _variants.length) % _variants.length);

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.bracketRight) {
      _flip(_variant + 1);
    } else if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.bracketLeft) {
      _flip(_variant - 1);
    } else if (k == LogicalKeyboardKey.digit1) {
      _flip(0);
    } else if (k == LogicalKeyboardKey.digit2) {
      _flip(1);
    } else if (k == LogicalKeyboardKey.digit3) {
      _flip(2);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final v = _variants[_variant];
    final mq = MediaQuery.of(context);
    final block = v.blockHeight + mq.padding.bottom;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: _FakeScreen(
                      key: ValueKey('screen-$_tab'),
                      tab: _tab,
                      topPadding: mq.padding.top + 76,
                      bottomPadding: v.overlapsContent ? block + 16 : 16,
                    ),
                  ),
                  if (!v.overlapsContent) SizedBox(height: block),
                ],
              ),
            ),
            // Swapping variants is instant on purpose: flipping is a high-frequency action.
            Positioned(left: 0, right: 0, bottom: 0, child: v.build(_tab, (i) => setState(() => _tab = i))),
            Positioned(
              top: mq.padding.top + 8,
              left: 12,
              right: 12,
              child: _Picker(index: _variant, onFlip: _flip),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prototype chrome. Its look is fixed on purpose (not part of the design being explored).
class _Picker extends StatelessWidget {
  const _Picker({required this.index, required this.onFlip});
  final int index;
  final ValueChanged<int> onFlip;

  @override
  Widget build(BuildContext context) {
    final v = _variants[index];
    return Center(
      child: Material(
        color: const Color(0xEB111111),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous variant',
                      onPressed: () => onFlip(index - 1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _variants.length; i++)
                            GestureDetector(
                              onTap: () => onFlip(i),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: i == index ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${i + 1} ${_variants[i].name}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: i == index ? Colors.black : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next variant',
                      onPressed: () => onFlip(index + 1),
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    v.axis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Product-shaped content so the bar is judged in context: listings, bookings, chats, profile.
class _FakeScreen extends StatelessWidget {
  const _FakeScreen({super.key, required this.tab, required this.topPadding, required this.bottomPadding});
  final int tab;
  final double topPadding, bottomPadding;

  static final _listings = [
    ('Riverside Garden Venue', 'VENUE', 'Riverside Events', 'Downtown', 4.8, 126, 1800.0, 220),
    ('Lumen Photography Studio', 'SERVICE', 'Lumen Studio', 'Downtown', 4.9, 84, 350.0, 0),
    ('The Old Mill Hall', 'VENUE', 'Mill & Co', 'Old Town', 4.6, 57, 1200.0, 150),
    ('Bloom & Co Florals', 'SERVICE', 'Bloom & Co', 'Riverside', 4.7, 41, 180.0, 0),
    ('Skyline Rooftop Lounge', 'VENUE', 'Skyline Hospitality', 'Downtown', 4.5, 33, 2600.0, 120),
    ('Golden Hour Catering', 'SERVICE', 'Golden Hour', 'Downtown', 4.8, 98, 25.0, 0),
  ];

  List<Widget> _content(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (tab) {
      case 0:
        return [
          for (final l in _listings)
            ListingCard(
              listing: ListingSummary.fromJson({
                'id': l.$1,
                'type': l.$2,
                'title': l.$1,
                'status': 'APPROVED',
                'providerName': l.$3,
                'city': l.$4,
                'avgRating': l.$5,
                'reviewCount': l.$6,
                'minPrice': l.$7,
                'capacity': l.$8 == 0 ? null : l.$8,
                'category': l.$2 == 'SERVICE' ? l.$1.split(' ').last : null,
                'verified': true,
              }),
              onTap: () {},
            ),
        ];
      case 1:
        const rows = [
          ('Wedding reception', 'Riverside Garden Venue', 'PENDING', '\$1,800'),
          ('Birthday party', 'Golden Hour Catering', 'APPROVED', '\$1,250'),
          ('Product launch', 'Skyline Rooftop Lounge', 'COMPLETED', '\$2,600'),
          ('Engagement shoot', 'Lumen Photography Studio', 'APPROVED', '\$350'),
          ('Office party', 'The Old Mill Hall', 'CANCELLED', '\$1,200'),
          ('Baby shower', 'Bloom & Co Florals', 'PENDING', '\$180'),
        ];
        return [
          for (final r in rows)
            AppCard(
              onTap: () {},
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(r.$2, style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        StatusChip(r.$3),
                      ],
                    ),
                  ),
                  Text(r.$4, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ];
      case 2:
        const chats = [
          ('Riverside Events', 'Yes, the garden is free on the 14th!', '2m', 2),
          ('Golden Hour', 'Could you share the final guest count?', '1h', 0),
          ('Lumen Studio', 'Thanks! See you at 3pm.', '3h', 0),
          ('Skyline Hospitality', 'We can add a sound system for \$120.', '1d', 1),
          ('Bloom & Co', 'Your quote has been updated.', '2d', 0),
        ];
        return [
          for (final c in chats)
            AppCard(
              onTap: () {},
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.15), child: Text(c.$1[0])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.$1,
                          style: TextStyle(fontWeight: c.$4 > 0 ? FontWeight.w800 : FontWeight.w700),
                        ),
                        Text(
                          c.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(c.$3, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
        ];
      default:
        return [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                  child: const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Alex Morgan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text('alex@example.com'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final t in const [
            'Notifications',
            'Payments',
            'My reviews',
            'Become a provider',
            'Appearance',
            'Sign out',
          ])
            AppCard(
              onTap: () {},
              child: Row(
                children: [
                  Expanded(
                    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, bottomPadding),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _tabs[tab].label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        ..._content(context),
      ],
    );
  }
}
