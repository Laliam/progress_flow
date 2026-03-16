import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

export '../data/profile_repository.dart' show profileRepositoryProvider;

final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Future.value(null);
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});
