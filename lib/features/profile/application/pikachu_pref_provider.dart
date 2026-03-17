import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kCatKey = 'cat_enabled';

/// Whether the floating Cat assistant overlay is visible.
final catEnabledProvider = StateNotifierProvider<CatEnabledNotifier, bool>(
  (ref) => CatEnabledNotifier(),
);

class CatEnabledNotifier extends StateNotifier<bool> {
  CatEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Migrate old key if present
    final legacy = prefs.getBool('pikachu_enabled');
    state = legacy ?? prefs.getBool(_kCatKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCatKey, value);
  }
}
