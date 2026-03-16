import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/supabase_auth_repository.dart';
import 'auth_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    repository: ref.watch(authRepositoryProvider),
    ref: ref,
  );
});

class AuthService {
  final AuthRepository _repository;
  final Ref _ref;

  const AuthService({required AuthRepository repository, required Ref ref})
      : _repository = repository,
        _ref = ref;

  /// Signs the user in with Google.
  /// Returns `true` if sign-in completed successfully, `false` if the user
  /// cancelled the flow.
  Future<bool> signInWithGoogle() async {
    return _repository.signInWithGoogle();
  }

  /// Signs up a new user with email and password.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _repository.signUpWithEmail(email: email, password: password);
  }

  /// Signs in an existing user with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _repository.signInWithEmail(email: email, password: password);
  }

  /// Signs the current user out and clears the local session.
  Future<void> signOut() async {
    return _repository.signOut();
  }

  /// Returns the currently authenticated [User], or `null` if unauthenticated.
  User? get currentUser => _ref.read(currentUserProvider);

  /// Returns `true` when a valid session exists.
  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);
}
