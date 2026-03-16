import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchProfile(String userId);
  Future<void> updateProfile({
    required String userId,
    required String username,
    String? slogan,
    String? avatarEmoji,
    String? avatarSeed,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;
  const SupabaseProfileRepository(this._client);

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile(
      id: row['id'] as String,
      username: row['username'] as String? ?? '',
      fullName: row['full_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      slogan: row['slogan'] as String?,
      avatarEmoji: row['avatar_emoji'] as String? ?? '🦊',
      avatarSeed: row['avatar_seed'] as String?,
    );
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String username,
    String? slogan,
    String? avatarEmoji,
    String? avatarSeed,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'username': username,
      'slogan': slogan ?? '',
      'avatar_emoji': avatarEmoji ?? '🦊',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarSeed != null) payload['avatar_seed'] = avatarSeed;

    // Upsert with explicit conflict target so Supabase uses UPDATE when the
    // row already exists (avoids needing INSERT policy for repeat saves).
    try {
      await _client
          .from('profiles')
          .upsert(payload, onConflict: 'id');
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('avatar_seed') || msg.contains('column')) {
        // Migration 0007 not yet run — retry without avatar_seed column.
        payload.remove('avatar_seed');
        await _client.from('profiles').upsert(payload, onConflict: 'id');
      } else {
        rethrow;
      }
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});
