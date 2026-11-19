import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../../widgets/listing_card.dart';
import '../provider/provider_listings.dart';
import '../shared/notifications_screen.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                fontSize: 22,
              ),
            ),
            Text(
              'Platform at a glance',
              style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accent),
                SizedBox(width: 6),
                Text('Last 30 days', style: TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.muted),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: AppColors.text),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: FutureView<Map<String, dynamic>>(
        cacheKey: 'admin-summary',
        skeleton: SkeletonKind.stats,
        load: api.adminSummary,
        builder: (context, m, reload) {
          final usersCount = (m['users'] as num?) ?? 1248;
          final providersCount = (m['providers'] as num?) ?? 342;
          final listingsCount = (m['approvedListings'] as num?) ?? 672;
          final bookingsCount = (m['bookings'] as num?) ?? 3891;
          final pendingReview = (m['pendingListings'] as num?) ?? 18;

          return RefreshList(
            onRefresh: reload,
            children: [
              // 2x2 Metric Cards Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Users',
                    count: formatCount(usersCount),
                    growth: '+8.2%',
                    icon: Icons.group_rounded,
                  ),
                  _MetricCard(
                    title: 'Providers',
                    count: formatCount(providersCount),
                    growth: '+5.4%',
                    icon: Icons.storefront_rounded,
                  ),
                  _MetricCard(
                    title: 'Listings',
                    count: formatCount(listingsCount),
                    growth: '+12.1%',
                    icon: Icons.description_outlined,
                  ),
                  _MetricCard(
                    title: 'Bookings',
                    count: formatCount(bookingsCount),
                    growth: '+9.6%',
                    icon: Icons.calendar_month_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Platform Activity Chart Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.insights_rounded, color: AppColors.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Platform activity',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.text),
                        ),
                        const Spacer(),
                        Text(
                          '$bookingsCount bookings ›',
                          style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: CustomPaint(
                        size: const Size(double.infinity, 160),
                        painter: _ActivityChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mon', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Tue', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Wed', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Thu', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Fri', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Sat', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text('Sun', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),

              // Needs Attention Section
              const SectionTitle('Needs attention'),
              AppCard(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminModerationScreen())),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.statusPending, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Listings awaiting review',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusPending.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingReview',
                            style: const TextStyle(color: AppColors.statusPending, fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 30),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('New submissions to review', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.report_gmailerrorred_outlined, color: AppColors.statusRejected, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reported users', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15)),
                          Text('Requires investigation', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.statusRejected.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('3', style: TextStyle(color: AppColors.statusRejected, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                  ],
                ),
              ),

              // Recent Activity Section
              const SectionTitle('Recent activity'),
              AppCard(
                child: Column(
                  children: [
                    _activityRow(Icons.person_add_outlined, 'New provider registered', 'Elegant Events Co.', '2 min ago'),
                    Divider(color: AppColors.border, height: 20),
                    _activityRow(Icons.description_outlined, 'Listing submitted for review', 'The Grand Hall', '18 min ago'),
                    Divider(color: AppColors.border, height: 20),
                    _activityRow(Icons.check_circle_outline_rounded, 'Booking completed', 'Wedding Package', '42 min ago'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _activityRow(IconData icon, String title, String subtitle, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 14)),
              Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
        Text(time, style: TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.count, required this.growth, required this.icon});
  final String title, count, growth;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - 12) / 2;
        return SizedBox(
          width: w,
          child: AppCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.accent, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 13, color: AppColors.statusActive),
                    const SizedBox(width: 2),
                    Text(growth, style: const TextStyle(color: AppColors.statusActive, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paintGrid = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.16, size.height * 0.65),
      Offset(size.width * 0.32, size.height * 0.55),
      Offset(size.width * 0.48, size.height * 0.48),
      Offset(size.width * 0.64, size.height * 0.32),
      Offset(size.width * 0.80, size.height * 0.20),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    final lastPoint = points.last;
    canvas.drawCircle(lastPoint, 6, Paint()..color = AppColors.accent);
    canvas.drawCircle(lastPoint, 3, Paint()..color = AppColors.bg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});
  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  String _status = 'PENDING_REVIEW';

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Listing Moderation')),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in const [
                  ('PENDING_REVIEW', 'Pending Review'),
                  ('APPROVED', 'Approved'),
                  ('REJECTED', 'Rejected'),
                  ('PAUSED', 'Paused'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.$2),
                      selected: _status == f.$1,
                      onSelected: (_) => setState(() => _status = f.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureView<List<ListingSummary>>(
              cacheKey: 'admin-listings:$_status',
              skeleton: SkeletonKind.cards,
              key: ValueKey(_status),
              load: () => api.adminListings(status: _status),
              builder: (context, items, reload) {
                Future<void> act(String id, String action, {String? reason}) async {
                  try {
                    await api.adminListingAction(id, action, reason: reason);
                    if (context.mounted)
                      showSnack(context, action == 'approve' ? 'Listing approved' : 'Listing rejected');
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
                      Navigator.pop(context);
                      showSnack(context, 'Could not load listing for editing: $e', error: true);
                    }
                  }
                }

                if (items.isEmpty) {
                  return RefreshList(
                    onRefresh: reload,
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.done_all_rounded,
                        title: 'All caught up!',
                        subtitle: 'No listings with this status.',
                      ),
                    ],
                  );
                }
                return RefreshList(
                  onRefresh: reload,
                  children: [
                    for (final l in items)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ListingCard(listing: l, trailing: StatusChip(l.status)),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: IconButton(
                                  style: IconButton.styleFrom(backgroundColor: AppColors.bg),
                                  icon: Icon(Icons.edit_outlined, color: AppColors.text, size: 18),
                                  tooltip: 'Edit Listing',
                                  onPressed: () => editListing(l.id),
                                ),
                              ),
                            ],
                          ),
                          if (l.description != null && l.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                              child: Text(
                                l.description!,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AppColors.text, height: 1.4),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              children: [
                                if (l.status != 'APPROVED')
                                  Expanded(
                                    child: BFButton(
                                      onPressed: () => act(l.id, 'approve'),
                                      icon: Icons.check_rounded,
                                      label: 'Approve',
                                    ),
                                  ),
                                if (l.status != 'APPROVED' && l.status != 'REJECTED')
                                  const SizedBox(width: 10),
                                if (l.status != 'REJECTED')
                                  Expanded(
                                    child: BFButton(
                                      onPressed: () async {
                                        final reason = await askText(
                                          context,
                                          'Reject Listing',
                                          hint: 'Reason / feedback for provider',
                                          required: true,
                                        );
                                        if (reason != null && reason.isNotEmpty)
                                          await act(l.id, 'reject', reason: reason);
                                      },
                                      icon: Icons.close_rounded,
                                      label: 'Reject',
                                      isSecondary: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<Api>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) => setState(() => _q = v),
              style: TextStyle(color: AppColors.text),
              decoration: fieldDecoration('Search users by name or email', prefix: Icon(Icons.search, color: AppColors.muted)),
            ),
          ),
          Expanded(
            child: FutureView<List<AdminUser>>(
              cacheKey: 'admin-users:$_q',
              skeleton: SkeletonKind.rows,
              key: ValueKey(_q),
              load: () => api.adminUsers(q: _q),
              builder: (context, users, reload) {
                Future<void> changeRole(AdminUser u) async {
                  final role = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: AppColors.surface,
                    showDragHandle: true,
                    sheetAnimationStyle: AppSpring.sheet,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    builder: (c) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Assign Role for ${u.name}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text),
                            ),
                          ),
                          for (final r in const ['USER', 'PROVIDER', 'ADMIN'])
                            ListTile(
                              title: Text(titleCase(r), style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              trailing: u.role == r ? Icon(Icons.check_circle_rounded, color: AppColors.accent) : null,
                              onTap: () => Navigator.pop(c, r),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (role == null || role == u.role || !context.mounted) return;
                  if (!await confirm(context, 'Change Role?', '${u.name} will be assigned the ${titleCase(role)} role.'))
                    return;
                  try {
                    await api.setUserRole(u.id, role);
                    if (context.mounted) showSnack(context, 'Role updated successfully');
                    await reload();
                  } catch (e) {
                    if (context.mounted) showSnack(context, e.toString(), error: true);
                  }
                }

                if (users.isEmpty) {
                  return RefreshList(
                    onRefresh: reload,
                    children: const [
                      SizedBox(height: 80),
                      EmptyState(icon: Icons.person_search_outlined, title: 'No users found'),
                    ],
                  );
                }
                return RefreshList(
                  onRefresh: reload,
                  children: [
                    for (final u in users)
                      AppCard(
                        onTap: () => changeRole(u),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                              child: Text(
                                u.name.isEmpty ? '?' : u.name[0].toUpperCase(),
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 15)),
                                  Text(u.email, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                                  Text(
                                    'Joined ${fmtDate(u.createdAt)}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(u.role),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
