import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import 'booking_detail_screen.dart';

const _eventTypes = ['Wedding', 'Birthday', 'Corporate Event', 'Conference', 'Party', 'Other'];

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, required this.detail});
  final ListingDetail detail;
  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _eventType = TextEditingController();
  final _notes = TextEditingController();
  late final TextEditingController _guests;
  DateTime? _date;
  late PricingTier _tier;
  late final Set<String> _addOns;
  bool _busy = false;

  ListingDetail get d => widget.detail;

  @override
  void initState() {
    super.initState();
    final cap = d.summary.capacity;
    _guests = TextEditingController(text: '${cap != null && cap < 50 ? cap : 50}');
    _tier = d.tiers.first;
    _addOns = d.addOns.where((a) => a.isRequired).map((a) => a.id).toSet();
  }

  @override
  void dispose() {
    _eventType.dispose();
    _notes.dispose();
    _guests.dispose();
    super.dispose();
  }

  double get _total =>
      _tier.price + d.addOns.where((a) => _addOns.contains(a.id)).fold(0.0, (s, a) => s + a.price);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day).add(Duration(days: d.minimumLeadTime ?? 0));
    var initial = _date ?? first.add(const Duration(days: 1));
    for (var i = 0; i < 800 && d.isBlocked(initial); i++) {
      initial = initial.add(const Duration(days: 1));
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365 * 3)),
      selectableDayPredicate: (day) => !d.isBlocked(day),
      helpText: 'Select event date',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final guests = int.tryParse(_guests.text.trim()) ?? 0;
    final cap = d.summary.capacity;
    String? problem;
    if (_eventType.text.trim().isEmpty) {
      problem = 'Choose or enter an event type';
    } else if (_date == null) {
      problem = 'Pick an event date';
    } else if (guests < 1) {
      problem = 'Enter the number of guests';
    } else if (cap != null && guests > cap) {
      problem = 'This venue holds at most $cap guests';
    }
    if (problem != null) {
      showSnack(context, problem, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final b = await context.read<Api>().createBooking(
        listingId: d.summary.id,
        pricingTierId: _tier.id,
        addOnIds: _addOns.toList(),
        eventType: _eventType.text.trim(),
        eventDate: _date!,
        guestCount: guests,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      showSnack(context, 'Request sent! The provider will review it.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Request to Book')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Text(
            d.summary.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(d.summary.providerName, style: TextStyle(color: AppColors.muted, fontSize: 14)),
          const SectionTitle('1. Event Details'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final t in _eventTypes)
                ChoiceChip(
                  label: Text(t),
                  selected: _eventType.text == t,
                  onSelected: (_) => setState(() => _eventType.text = t == 'Other' ? '' : t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _eventType,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Event type', hint: 'e.g. Wedding reception'),
          ),
          const SizedBox(height: 12),
          BFButton(
            onPressed: _pickDate,
            icon: Icons.calendar_month_outlined,
            label: _date == null ? 'Select Event Date' : fmtDateLong(_date!),
            isSecondary: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _guests,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Number of guests', prefix: Icon(Icons.people_alt_outlined, color: AppColors.muted)),
          ),
          const SectionTitle('2. Package Option'),
          for (final t in d.tiers)
            AppCard(
              onTap: () => setState(() => _tier = t),
              borderColor: _tier.id == t.id ? AppColors.accent : AppColors.border,
              child: Row(
                children: [
                  Icon(
                    _tier.id == t.id ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: _tier.id == t.id ? AppColors.accent : AppColors.muted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 16)),
                        if (t.description != null && t.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(t.description!, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  Text(money(t.price), style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 17)),
                ],
              ),
            ),
          if (d.addOns.isNotEmpty) ...[
            const SectionTitle('3. Add-on Services'),
            for (final a in d.addOns)
              AppCard(
                onTap: a.isRequired ? null : () => setState(() => _addOns.contains(a.id) ? _addOns.remove(a.id) : _addOns.add(a.id)),
                borderColor: _addOns.contains(a.id) ? AppColors.accent.withValues(alpha: 0.5) : AppColors.border,
                child: Row(
                  children: [
                    Icon(
                      _addOns.contains(a.id) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: _addOns.contains(a.id) ? AppColors.accent : AppColors.muted,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
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
                    Text('+${money(a.price)}', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent)),
                  ],
                ),
              ),
          ],
          const SectionTitle('4. Notes for Provider'),
          TextField(
            controller: _notes,
            maxLines: 4,
            style: TextStyle(color: AppColors.text),
            decoration: fieldDecoration('Any special requests or instructions? (optional)'),
          ),
          const SizedBox(height: 12),
          Text(
            'You will not be charged now. The provider will review your booking request.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                    Text('Estimated Total', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    AnimatedNumber(
                      value: _total,
                      format: money,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
              BFButton(
                onPressed: _busy ? null : _submit,
                label: _busy ? 'Sending...' : 'Send Request',
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
