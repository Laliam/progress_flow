import 'package:avatar_plus/avatar_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_provider.dart';
import '../../../app_version.dart';
import '../application/pikachu_pref_provider.dart';
import '../application/profile_providers.dart';
import '../../../services/notification_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const ProfileScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _sloganController = TextEditingController();
  bool _isSaving = false;
  bool _loaded = false;
  String? _selectedSeed;

  static const _kAvatarSeeds = [
    'cosmic_tiger', 'brave_dragon', 'neon_panda', 'swift_fox',
    'calm_ocean', 'fire_spirit', 'moon_rabbit', 'storm_wolf',
    'crystal_bear', 'jade_phoenix', 'ruby_falcon', 'golden_lion',
    'silver_hawk', 'emerald_deer', 'indigo_whale', 'violet_owl',
    'scarlet_eagle', 'azure_dolphin', 'forest_sprite', 'sun_gecko',
    'shadow_cat', 'dawn_lynx', 'dusk_panther', 'starlight_fox',
  ];

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
    if (profile.avatarSeed != null) {
      setState(() => _selectedSeed = profile.avatarSeed);
    }
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
            avatarSeed: _selectedSeed,
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

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1F2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Choose your avatar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _kAvatarSeeds.length,
                    itemBuilder: (_, i) {
                      final seed = _kAvatarSeeds[i];
                      final selected = seed == _selectedSeed;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedSeed = seed);
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.white12,
                              width: selected ? 3 : 1.5,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  )]
                                : null,
                          ),
                          child: ClipOval(child: AvatarPlus(seed, height: 60, width: 60)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              // ── Avatar section ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showAvatarPicker(context),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: AvatarPlus(
                                _selectedSeed ?? ref.watch(currentUserIdProvider) ?? 'user',
                                height: 100,
                                width: 100,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => _showAvatarPicker(context),
                      child: const Text('Change avatar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Nickname ────────────────────────────────────────────────
              Text('Nickname',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
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

              // ── Slogan ─────────────────────────────────────────────────
              Text('Slogan',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
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

              // ── Save ───────────────────────────────────────────────────
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

              // ── Notifications ──────────────────────────────────────────
              Text('Daily Reminder',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const _NotificationSettings(),

              const SizedBox(height: 20),

              // ── Pikachu assistant ──────────────────────────────────────
              Text('App Settings',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFF1C1F2E),
                  border: Border.all(color: const Color(0xFF2A2D40)),
                ),
                child: SwitchListTile(
                  title: const Text('Pikachu assistant'),
                  subtitle: const Text('Show floating Pikachu on all screens'),
                  secondary: const Text('⚡', style: TextStyle(fontSize: 24)),
                  value: ref.watch(pikachuEnabledProvider),
                  onChanged: (v) =>
                      ref.read(pikachuEnabledProvider.notifier).setEnabled(v),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                AppVersion.versionString,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationSettings extends ConsumerStatefulWidget {
  const _NotificationSettings();
  @override
  ConsumerState<_NotificationSettings> createState() =>
      _NotificationSettingsState();
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
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _time = time;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    await _notifService.scheduleDailyReminder(
      enabled: value,
      time: _time,
      buddyEmoji: '⚡',
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
      if (_enabled) {
        await _notifService.scheduleDailyReminder(
          enabled: true,
          time: _time,
          buddyEmoji: '⚡',
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
            subtitle: Text(_enabled
                ? 'Enabled at ${_time.format(context)}'
                : 'Tap to enable'),
            value: _enabled,
            onChanged: _toggleEnabled,
            secondary: const Text('⚡', style: TextStyle(fontSize: 24)),
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
