import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../api.dart';
import '../../models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils.dart';
import '../../widgets/common.dart';
import '../customer/payments_screen.dart';
import '../customer/reviews_screen.dart';
import 'notifications_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.me!;
    final customer = s.mode == AppMode.customer;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Account & Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          // Profile Banner Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                  backgroundImage: (u.imageUrl != null && u.imageUrl!.isNotEmpty)
                      ? NetworkImage(u.imageUrl!)
                      : null,
                  child: (u.imageUrl == null || u.imageUrl!.isEmpty)
                      ? Text(
                          u.displayName[0].toUpperCase(),
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.accent),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(u.email, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 8),
                      StatusChip(u.role),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Role Switcher Segmented Control
          if (s.availableModes.length > 1) ...[
            const SectionTitle('Switch View'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: SegmentedButton<AppMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  selectedBackgroundColor: AppColors.accent,
                  selectedForegroundColor: AppColors.onAccent,
                  foregroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                segments: [
                  for (final m in s.availableModes) ButtonSegment(value: m, label: Text(titleCase(m.name))),
                ],
                selected: {s.mode},
                onSelectionChanged: (v) => s.setMode(v.first),
              ),
            ),
          ],

          const SectionTitle('Activity'),
          _tile(
            context,
            Icons.notifications_none_rounded,
            'Notifications',
            () => _open(context, const NotificationsScreen()),
          ),
          if (customer) ...[
            _tile(context, Icons.payments_outlined, 'Payments & Invoices', () => _open(context, const PaymentsScreen())),
            _tile(
              context,
              Icons.star_outline_rounded,
              'My Reviews',
              () => _open(context, const ReviewsScreen()),
            ),
            if (u.providerProfile == null)
              _tile(
                context,
                Icons.storefront_outlined,
                'Become a Provider',
                () => _open(context, const BecomeProviderScreen()),
                subtitle: 'List your venue or service on BookFlow',
              ),
          ],

          const SectionTitle('Appearance'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                backgroundColor: AppColors.surface,
                selectedBackgroundColor: AppColors.accent,
                selectedForegroundColor: AppColors.onAccent,
                foregroundColor: AppColors.muted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Auto'),
                ),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => s.setThemeMode(v.first),
            ),
          ),

          const SizedBox(height: 14),
          _ThemePicker(selected: s.themeId, onSelect: s.setThemeId),

          const SectionTitle('Preferences'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Startup Notification Alert', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text, fontSize: 15)),
              subtitle: Text('Show popup when you have unread notifications on launch', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              value: s.showNotificationPopup,
              onChanged: (v) => s.setShowNotificationPopup(v),
              activeColor: AppColors.accent,
            ),
          ),

          const SectionTitle('Manage Profile'),
          _tile(
            context,
            Icons.person_outline,
            'Edit Profile',
            () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => _EditProfileModal(user: u),
            ),
            subtitle: 'Update your username and profile picture',
          ),
          if (u.providerProfile != null)
            _tile(
              context,
              Icons.storefront_outlined,
              'Edit Provider Profile',
              () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (_) => _EditProviderModal(user: u),
              ),
              subtitle: 'Update store name, description and company logo',
            ),
          _tile(
            context,
            Icons.delete_outline,
            'Delete Account',
            () async {
              if (await confirm(
                context,
                'Delete Account?',
                'This action is permanent and cannot be undone.',
                confirmLabel: 'Delete',
              )) {
                try {
                  final api = context.read<Api>();
                  await api.deleteAccount();
                  if (!context.mounted) return;
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  await s.signOut();
                  showSnack(context, 'Account deleted');
                } catch (e) {
                  if (context.mounted) showSnack(context, e.toString(), error: true);
                }
              }
            },
            subtitle: 'Permanently remove your account and data',
            isDestructive: true,
          ),

          const SizedBox(height: 28),
          BFButton(
            onPressed: () async {
              if (await confirm(
                context,
                'Sign out?',
                'You will need to sign in again to access your account.',
                confirmLabel: 'Sign Out',
              )) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                await s.signOut();
              }
            },
            label: 'Sign Out',
            isSecondary: true,
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap, {String? subtitle, bool isDestructive = false}) =>
      AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDestructive ? AppColors.statusRejected : AppColors.accent).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isDestructive ? AppColors.statusRejected : AppColors.accent, size: 20),
          ),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDestructive ? AppColors.statusRejected : AppColors.text, fontSize: 15)),
          subtitle: subtitle == null ? null : Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          trailing: Icon(Icons.chevron_right, color: AppColors.muted),
        ),
      );
}

class _EditProfileModal extends StatefulWidget {
  const _EditProfileModal({required this.user});
  final AppUser user;
  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  String? _imageUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController(text: widget.user.firstName ?? '');
    _lastName = TextEditingController(text: widget.user.lastName ?? '');
    _imageUrl = widget.user.imageUrl;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        setState(() => _imageUrl = 'data:$mime;base64,${base64Encode(bytes)}');
        showSnack(context, 'Profile picture attached');
      }
    } catch (e) {
      showSnack(context, 'Could not pick image: $e', error: true);
    }
  }

  ImageProvider? _imageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final api = context.read<Api>();
      await api.updateMe(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        imageUrl: _imageUrl,
      );
      if (!mounted) return;
      await context.read<AppState>().loadMe(api, silent: true);
      Navigator.pop(context);
      showSnack(context, 'Profile updated successfully');
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
          Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                backgroundImage: _imageProvider(_imageUrl),
                child: (_imageUrl == null || _imageUrl!.isEmpty)
                    ? Icon(Icons.camera_alt, color: AppColors.accent, size: 28)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _firstName, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('First Name')),
          const SizedBox(height: 12),
          TextField(controller: _lastName, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Last Name')),
          const SizedBox(height: 20),
          BFButton(onPressed: _busy ? null : _save, label: _busy ? 'Saving...' : 'Save Profile'),
        ],
      ),
    );
  }
}

class _EditProviderModal extends StatefulWidget {
  const _EditProviderModal({required this.user});
  final AppUser user;
  @override
  State<_EditProviderModal> createState() => _EditProviderModalState();
}

class _EditProviderModalState extends State<_EditProviderModal> {
  late final TextEditingController _bizName;
  late final TextEditingController _desc;
  String? _logoUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bizName = TextEditingController(text: widget.user.providerProfile?.businessName ?? '');
    _desc = TextEditingController(text: widget.user.providerProfile?.description ?? '');
    _logoUrl = widget.user.imageUrl;
  }

  @override
  void dispose() {
    _bizName.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 82);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        setState(() => _logoUrl = 'data:$mime;base64,${base64Encode(bytes)}');
        showSnack(context, 'Company logo attached');
      }
    } catch (e) {
      showSnack(context, 'Could not pick logo: $e', error: true);
    }
  }

  ImageProvider? _imageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image/')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final api = context.read<Api>();
      await api.updateMe(
        businessName: _bizName.text.trim(),
        description: _desc.text.trim(),
        imageUrl: _logoUrl,
      );
      if (!mounted) return;
      await context.read<AppState>().loadMe(api, silent: true);
      Navigator.pop(context);
      showSnack(context, 'Provider profile updated');
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
          Text('Edit Provider Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.text)),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                backgroundImage: _imageProvider(_logoUrl),
                child: (_logoUrl == null || _logoUrl!.isEmpty)
                    ? Icon(Icons.storefront, color: AppColors.accent, size: 28)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: _bizName, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Store / Business Name')),
          const SizedBox(height: 12),
          TextField(controller: _desc, maxLines: 3, style: TextStyle(color: AppColors.text), decoration: fieldDecoration('Company Description')),
          const SizedBox(height: 20),
          BFButton(onPressed: _busy ? null : _save, label: _busy ? 'Saving...' : 'Save Provider Profile'),
        ],
      ),
    );
  }
}

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});
  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      showSnack(context, 'Business name is required', error: true);
      return;
    }
    setState(() => _busy = true);
    final api = context.read<Api>();
    final state = context.read<AppState>();
    try {
      await api.becomeProvider(
        businessName: _name.text.trim(),
        description: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );
      await state.loadMe(api, silent: true);
      if (!mounted) return;
      state.setMode(AppMode.provider);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Become a Provider')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Tell customers about your business. Once created, you can publish venue or service listings.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _name,
          style: TextStyle(color: AppColors.text),
          decoration: fieldDecoration('Business name *'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _desc,
          maxLines: 4,
          style: TextStyle(color: AppColors.text),
          decoration: fieldDecoration('Description'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          style: TextStyle(color: AppColors.text),
          decoration: fieldDecoration('Phone number'),
        ),
        const SizedBox(height: 24),
        BFButton(
          onPressed: _busy ? null : _submit,
          label: _busy ? 'Creating...' : 'Create Provider Profile',
        ),
      ],
    ),
  );
}


/// Row of colour-theme swatches. Each swatch previews the theme in the *current* brightness,
/// so what you tap is what you get.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.selected, required this.onSelect});
  final BFThemeId selected;
  final ValueChanged<BFThemeId> onSelect;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Colour theme',
              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final id in BFThemeId.values)
                Expanded(
                  child: _Swatch(
                    id: id,
                    palette: BFPalette.of(id, brightness),
                    selected: id == selected,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(id);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.id, required this.palette, required this.selected, required this.onTap});
  final BFThemeId id;
  final BFPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: AppMotion.outStrong,
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? palette.accent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, 0.5, 0.5, 1],
                    colors: [palette.bg, palette.bg, palette.accent, palette.accent],
                  ),
                ),
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Icon(Icons.check_rounded, size: 22, color: palette.onAccent),
                ),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? AppColors.text : AppColors.muted,
              ),
              child: Text(id.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
