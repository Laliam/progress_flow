import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_provider.dart';
import '../application/profile_providers.dart';
import '../../../services/notification_service.dart';

const _kAvatarEmojis = [
  '🦊', '🐉', '🐨', '🐸', '🦁', '🐼', '🐬', '🦋', '🐙', '🌟',
  '🐯', '🦄', '🐺', '🦅', '🐻', '🦊', '🦁', '🐧', '🐳', '🦖',
];

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const ProfileScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _sloganController = TextEditingController();
  String _selectedEmoji = '🦊';
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  void _loadProfile(dynamic profile) {
    if (_loaded || profile == null) return;
    _loaded = true;
    _usernameController.text = profile.username ?? '';
    _sloganController.text = profile.slogan ?? '';
    setState(() => _selectedEmoji = profile.avatarEmoji ?? '🦊');
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
        userId: userId,
        username: _usernameController.text.trim(),
        slogan: _sloganController.text.trim(),
        avatarEmoji: _selectedEmoji,
      );
      ref.invalidate(currentProfileProvider);
      HapticFeedback.heavyImpact();
      if (mounted) {
        if (widget.isSetup) {
          context.go('/dashboard');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);

    profileAsync.whenData(_loadProfile);

    return Scaffold(
      appBar: AppBar(
        leading: widget.isSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/dashboard'),
              ),
        title: Text(widget.isSetup ? 'Set Up Your Profile' : 'My Profile'),
        actions: widget.isSetup
            ? [
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('Skip'),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => _showEmojiPicker(context),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(_selectedEmoji, style: const TextStyle(fontSize: 52)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change avatar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text('Nickname', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Your display name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Text('Slogan', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sloganController,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Your personal motto…',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Icon(Icons.format_quote_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving
                      ? 'Saving…'
                      : widget.isSetup
                          ? 'Continue →'
                          : 'Save Profile'),
                ),
              ),
              const SizedBox(height: 28),
              Text('Daily Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _NotificationSettings(buddyEmoji: _selectedEmoji),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose your buddy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _kAvatarEmojis.map((emoji) {
                final selected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmoji = emoji);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettings extends ConsumerStatefulWidget {
  final String buddyEmoji;
  const _NotificationSettings({required this.buddyEmoji});
  @override
  ConsumerState<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends ConsumerState<_NotificationSettings> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _notifService.isEnabled();
    final time = await _notifService.getReminderTime();
    if (mounted) setState(() { _enabled = enabled; _time = time; });
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    await _notifService.scheduleDailyReminder(
      enabled: value, time: _time, buddyEmoji: widget.buddyEmoji,
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
      if (_enabled) {
        await _notifService.scheduleDailyReminder(
          enabled: true, time: _time, buddyEmoji: widget.buddyEmoji,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFF1C1F2E),
        border: Border.all(color: const Color(0xFF2A2D40)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily reminder'),
            subtitle: Text(_enabled ? 'Enabled at ${_time.format(context)}' : 'Tap to enable'),
            value: _enabled,
            onChanged: _toggleEnabled,
            secondary: Text(widget.buddyEmoji, style: const TextStyle(fontSize: 24)),
          ),
          if (_enabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: const Text('Reminder time'),
              trailing: Text(
                _time.format(context),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _pickTime,
            ),
          ],
        ],
      ),
    );
  }
}
