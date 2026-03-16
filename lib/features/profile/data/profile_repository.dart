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
    String? avatarJsonOptions,
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
      avatarJsonOptions: row['avatar_json_options'] as String?,
    );
  }

  @override
  Future<void> updateProfile({
    required String userId,
    required String username,
    String? slogan,
    String? avatarEmoji,
    String? avatarJsonOptions,
  }) async {
    final payload = <String, dynamic>{
      'id': userId,
      'username': username,
      'slogan': slogan ?? '',
      'avatar_emoji': avatarEmoji ?? '🦊',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (avatarJsonOptions != null) {
      payload['avatar_json_options'] = avatarJsonOptions;
    }
    await _client.from('profiles').upsert(payload);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(Supabase.instance.client);
});
