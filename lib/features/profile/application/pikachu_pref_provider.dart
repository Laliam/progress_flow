import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPikachuKey = 'pikachu_enabled';

/// Whether the floating Pikachu assistant overlay is visible.
final pikachuEnabledProvider =
    StateNotifierProvider<PikachuEnabledNotifier, bool>(
  (ref) => PikachuEnabledNotifier(),
);

class PikachuEnabledNotifier extends StateNotifier<bool> {
  PikachuEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kPikachuKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPikachuKey, value);
  }
}
