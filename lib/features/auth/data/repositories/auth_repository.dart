abstract interface class AuthRepository {
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<void> signUpWithEmail({required String email, required String password});
  Future<void> signInWithEmail({required String email, required String password});
}