abstract interface class AuthRepository {
  Future<bool> signInWithGoogle();
  Future<void> signOut();
}