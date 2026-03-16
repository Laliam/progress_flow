import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

const String _googleIosClientId = String.fromEnvironment(
  'GOOGLE_IOS_CLIENT_ID',
  defaultValue: '',
);

const String _googleIosWebClientId = String.fromEnvironment(
  'GOOGLE_IOS_WEB_CLIENT_ID',
  defaultValue: '',
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  const SupabaseAuthRepository(this._client);

  @override
  Future<bool> signInWithGoogle() async {
    if (Platform.isIOS &&
        (_googleIosClientId.isEmpty || _googleIosWebClientId.isEmpty)) {
      throw Exception(
        'Missing iOS Google Client ID. Set GOOGLE_IOS_CLIENT_ID and GOOGLE_IOS_WEB_CLIENT_ID and configure URL schemes in ios/Runner/Info.plist.',
      );
    }

    final googleSignIn = GoogleSignIn(
      clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
      scopes: ['email', 'profile'],
      serverClientId: _googleIosWebClientId.isEmpty ? null : _googleIosWebClientId,
    );
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return false;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Failed to retrieve Google ID token');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );

    return true;
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}