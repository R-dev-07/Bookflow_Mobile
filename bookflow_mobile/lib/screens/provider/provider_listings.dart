import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';

class ProviderListingsScreen extends StatelessWidget {
  const ProviderListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return FutureView<List<ListingSummary>>(
      cacheKey: 'prov-listings',
      skeleton: SkeletonKind.cards,
      load: api.providerListings,
      builder: (context, items, reload) {
        Future<void> act(String id, String action) async {
          try {
            await api.listingAction(id, action);
            if (context.mounted) showSnack(context, 'Listing updated');
            await reload();
          } catch (e) {
            if (context.mounted) showSnack(context, e.toString(), error: true);
          }
        }

        Future<void> editListing(String id) async {
          try {
            showDialog(context: context, barrierDismissible: false, builder: (_) => const FullScreenLoader());
            final detail = await api.listing(id);
            if (context.mounted) Navigator.pop(context); // pop loader
            if (!context.mounted) return;
            final updated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => ListingFormScreen(existing: detail)),
            );
            if (updated == true) reload();
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // pop loader
              showSnack(context, 'Could not load listing for editing: $e', error: true);
            }
          }
        }

        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(title: const Text('My Listings')),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: FloatingActionButton.extended(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const ListingFormScreen()),
                );
                if (created == true) reload();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Listing', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          body: RefreshList(
            onRefresh: reload,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (items.isEmpty)
                const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No listings created yet',
                  subtitle: 'Tap New Listing to add your venue or event service.',
                ),
              for (final l in items)
                Stack(
                  children: [
                    ListingCard(listing: l, trailing: StatusChip(l.status)),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: PopupMenuButton<String>(
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.border),
                        ),
                        icon: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.bg,
                          child: Icon(Icons.more_vert, color: AppColors.text, size: 18),
                        ),
                        onSelected: (a) {
                          if (a == 'edit') {
                            editListing(l.id);
                          } else {
                            act(l.id, a);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text('Edit Listing', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700))),
                          if (l.status == 'DRAFT' || l.status == 'REJECTED')
                            PopupMenuItem(value: 'submit', child: Text('Submit for Review', style: TextStyle(color: AppColors.text))),
                          if (l.status == 'APPROVED')
                            PopupMenuItem(value: 'pause', child: Text('Pause Listing', style: TextStyle(color: AppColors.text))),
                          if (l.status == 'PAUSED')
                            PopupMenuItem(value: 'resume', child: Text('Resume Listing', style: TextStyle(color: AppColors.text))),
                          PopupMenuItem(value: 'archive', child: Text('Archive Listing', style: TextStyle(color: AppColors.text))),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TierInput {
  _TierInput({String name = '', String price = '', String desc = ''}) {
    this.name.text = name;
    this.price.text = price;
    this.desc.text = desc;
  }
  final name = TextEditingController();
  final price = TextEditingController();
  final desc = TextEditingController();
  void dispose() {
    name.dispose();
    price.dispose();
    desc.dispose();
  }
}

class ListingFormScreen extends StatefulWidget {
  const ListingFormScreen({super.key, this.existing});
  final ListingDetail? existing;

  @override
  State<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends State<ListingFormScreen> {
  late String _type;
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _address;
  late final TextEditingController _capacity;
  late final TextEditingController _category;
  late final TextEditingController _photos;
  late final TextEditingController _amenities;
  late final List<_TierInput> _tiers;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.summary.type ?? 'VENUE';
    _title = TextEditingController(text: e?.summary.title ?? '');
    _desc = TextEditingController(text: e?.summary.description ?? '');
    _city = TextEditingController(text: e?.summary.city ?? '');
    _state = TextEditingController(text: e?.summary.state ?? '');
    _address = TextEditingController(text: e?.location ?? '');
    _capacity = TextEditingController(text: e?.summary.capacity?.toString() ?? '');
    _category = TextEditingController(text: e?.summary.category ?? '');
    _photos = TextEditingController(text: e?.photos.join('\n') ?? '');
    _amenities = TextEditingController(text: e?.amenities.join(', ') ?? '');
    
    if (e != null && e.tiers.isNotEmpty) {
      _tiers = e.tiers.map((t) => _TierInput(
        name: t.name,
        price: t.price.toString(),
        desc: t.description ?? '',
      )).toList();
    } else {
      _tiers = [_TierInput()];
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _city, _state, _address, _capacity, _category, _photos, _amenities]) {
      c.dispose();
    }
    for (final t in _tiers) {
      t.dispose();
    }
    super.dispose();
  }

  List<String> _split(String s) =>
      s.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> _pickDeviceImages() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(maxWidth: 1200, maxHeight: 1200, imageQuality: 82);
      if (pickedList.isNotEmpty) {
        final newUris = <String>[];
        for (final picked in pickedList) {
          final bytes = await picked.readAsBytes();
          final ext = picked.path.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          newUris.add('data:$mime;base64,${base64Encode(bytes)}');
        }
        final current = _photos.text.trim();
        final updated = current.isEmpty ? newUris.join('\n') : '$current\n${newUris.join('\n')}';
        setState(() => _photos.text = updated);
        showSnack(context, '${pickedList.length} image(s) attached');
      }
    } catch (e) {
      showSnack(context, 'Could not upload images: $e', error: true);
    }
  }

  Future<void> _pickDeviceVideo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'mp4' ? 'video/mp4' : 'video/webm';
        final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
        final current = _photos.text.trim();
        final updated = current.isEmpty ? dataUri : '$current\n$dataUri';
        setState(() => _photos.text = updated);
        showSnack(context, 'Video attached');
      }
    } catch (e) {
      showSnack(context, 'Could not upload video: $e', error: true);
    }
  }

  Future<void> _save({required bool submit}) async {
    final tiers = [
      for (final t in _tiers)
        if (t.name.text.trim().isNotEmpty || t.price.text.trim().isNotEmpty)
          {
            'name': t.name.text.trim(),
            'price': double.tryParse(t.price.text.trim()) ?? 0,
            'description': t.desc.text.trim(),
          },
    ];
    String? problem;
    if (_title.text.trim().isEmpty) {
      problem = 'Add a title';
    } else if (_desc.text.trim().isEmpty) {
      problem = 'Add a description';
    } else if (tiers.isEmpty ||
        tiers.any((t) => (t['name'] as String).isEmpty || (t['price'] as double) <= 0)) {
      problem = 'Each pricing option needs a name and a price above 0';
    } else if (_type == 'VENUE' && (int.tryParse(_capacity.text.trim()) ?? 0) < 1) {
      problem = 'Enter the venue capacity';
    }
    if (problem != null) {
      showSnack(context, problem, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final body = {
        'type': _type,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim(),
        'location': _address.text.trim(),
        if (_type == 'VENUE')
          'capacity': int.parse(_capacity.text.trim())
        else
          'category': _category.text.trim(),
        'photos': _split(_photos.text),
        'amenities': _split(_amenities.text),
        'tiers': tiers,
        'submit': submit,
      };

      if (widget.existing != null) {
        await context.read<Api>().updateListing(widget.existing!.summary.id, body);
        if (!mounted) return;
        showSnack(context, 'Listing updated & submitted for review');
      } else {
        await context.read<Api>().createListing(body);
        if (!mounted) return;
        showSnack(context, submit ? 'Submitted for review' : 'Saved as draft');
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(isEditing ? 'Edit Listing' : 'Create New Listing')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface,
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.onAccent,
                foregroundColor: AppColors.muted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              segments: const [
                ButtonSegment(value: 'VENUE', icon: Icon(Icons.apartment_rounded), label: Text('Venue')),
                ButtonSegment(value: 'SERVICE', icon: Icon(Icons.celebration_rounded), label: Text('Service')),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() => _type = v.first),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _title, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Title *')),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 4, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Description *')),
          const SizedBox(height: 12),
          if (_type == 'VENUE')
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: AppColors.text),
              decoration: fieldDecoration('Capacity (guests) *', prefix: Icon(Icons.people_alt_outlined, color: AppColors.muted)),
            )
          else
            TextField(
              controller: _category,
              style: TextStyle(color: AppColors.text),
              decoration: fieldDecoration('Category', hint: 'e.g. Photography, Catering, DJ'),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(controller: _city, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('City (e.g. Lusaka)')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(controller: _state, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('State / Region')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(controller: _address, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Address / Location')),
          SectionTitle(
            'Photos & Videos',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: _pickDeviceImages,
                  icon: Icon(Icons.photo_library_outlined, color: AppColors.accent, size: 16),
                  label: Text('+ Images', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: _pickDeviceVideo,
                  icon: Icon(Icons.videocam_outlined, color: AppColors.accent, size: 16),
                  label: Text('+ Video', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          TextField(
            controller: _photos,
            maxLines: 4,
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Photo & Video URLs or Data', hint: 'One image/video per line. Tap + Images or + Video to pick files.'),
          ),
          if (_type == 'VENUE') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _amenities,
              style: TextStyle(color: AppColors.text),
              decoration: fieldDecoration('Amenities', hint: 'Comma separated, e.g. Stage, Garden, Parking'),
            ),
          ],
          SectionTitle(
            'Pricing Options',
            trailing: TextButton.icon(
              onPressed: () => setState(() => _tiers.add(_TierInput())),
              icon: Icon(Icons.add_rounded, color: AppColors.accent),
              label: Text('Add Tier', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ),
          for (var i = 0; i < _tiers.length; i++)
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(controller: _tiers[i].name, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Name *')),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _tiers[i].price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: AppColors.text),
                          decoration: fieldDecoration('Price (K) *'),
                        ),
                      ),
                      if (_tiers.length > 1)
                        IconButton(
                          onPressed: () => setState(() => _tiers.removeAt(i).dispose()),
                          icon: const Icon(Icons.delete_outline, color: AppColors.statusRejected),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _tiers[i].desc, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Description')),
                ],
              ),
            ),
          const SizedBox(height: 20),
          BFButton(
            onPressed: _busy ? null : () => _save(submit: true),
            label: _busy ? 'Saving...' : (isEditing ? 'Save Changes & Review' : 'Submit for Review'),
          ),
          if (!isEditing) ...[
            const SizedBox(height: 10),
            BFButton(
              onPressed: _busy ? null : () => _save(submit: false),
              label: 'Save as Draft',
              isSecondary: true,
            ),
          ],
        ],
      ),
    );
  }
}
