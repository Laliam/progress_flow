import 'package:avatar_maker/fluttermoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_provider.dart';
import '../../../app_version.dart';
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
  bool _showCustomizer = false;

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

    // Sync avatar_maker options from DB to local SharedPreferences
    if (profile.avatarJsonOptions != null) {
      SharedPreferences.getInstance().then((pref) async {
        await pref.setString(
            'fluttermojiSelectedOptions', profile.avatarJsonOptions!);
        // Let the Fluttermoji controller reload on next build
        try {
          FluttermojiFunctions(); // ensure defaults loaded
        } catch (_) {}
      });
    }
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _isSaving = true);
    try {
      // Read current avatar options from SharedPreferences (autosaved by FluttermojiCustomizer)
      String? avatarJsonOptions;
      try {
        final pref = await SharedPreferences.getInstance();
        avatarJsonOptions = pref.getString('fluttermojiSelectedOptions');
      } catch (_) {}

      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            username: _usernameController.text.trim(),
            slogan: _sloganController.text.trim(),
            avatarJsonOptions: avatarJsonOptions,
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
              // ── Avatar section ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showCustomizer = !_showCustomizer),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: FluttermojiCircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showCustomizer ? 'Tap to hide editor' : 'Tap to customize avatar',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Fluttermoji customizer ───────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showCustomizer
                    ? Padding(
                        key: const ValueKey('customizer'),
                        padding: const EdgeInsets.only(top: 16),
                        child: FluttermojiCustomizer(
                          scaffoldHeight:
                              MediaQuery.of(context).size.height * 0.38,
                          autosave: true,
                          theme: FluttermojiThemeData(
                            primaryBgColor: const Color(0xFF1C1F2E),
                            secondaryBgColor: const Color(0xFF12141F),
                            iconColor: theme.colorScheme.primary,
                            selectedIconColor: theme.colorScheme.primary,
                            unselectedIconColor: Colors.white54,
                            labelTextStyle: theme.textTheme.labelMedium!
                                .copyWith(color: Colors.white70),
                            selectedTileDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.primary, width: 2),
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                            ),
                            boxDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFF1C1F2E),
                            ),
                            scrollPhysics: const BouncingScrollPhysics(),
                            tilePadding: const EdgeInsets.all(6),
                            tileMargin: const EdgeInsets.all(4),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-customizer')),
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
