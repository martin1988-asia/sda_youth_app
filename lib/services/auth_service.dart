import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthService {
  Future<void> setSessionPersistence(bool rememberMe);

  Future<UserCredential> authenticateEmail({
    required String email,
    required String password,
  });

  Future<UserCredential?> authenticateGoogle();

  Future<void> transmitPasswordReset(String email);

  Future<void> terminateSession();

  Future<void> terminateIdentity();

  User? get currentIdentity;

  Stream<User?> get identityStateChanges;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  @override
  User? get currentIdentity => _auth.currentUser;

  @override
  Stream<User?> get identityStateChanges => _auth.authStateChanges();

  @override
  Future<void> setSessionPersistence(bool rememberMe) async {
    try {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    } catch (e) {
      debugPrint("Persistence error: $e");
    }
  }

  @override
  Future<UserCredential> authenticateEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // ✅ FINAL FIXED GOOGLE SIGN-IN
  @override
  Future<UserCredential?> authenticateGoogle() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();

      final auth = account.authentication; // ✅ NOT awaited

      final idToken = auth.idToken;

      if (idToken == null) {
        debugPrint("Google ID token is null");
        return null;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }

  @override
  Future<void> transmitPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password reset error: $e");
    }
  }

  @override
  Future<void> terminateSession() async {
    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  @override
  Future<void> terminateIdentity() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint("Delete account error: $e");
    }
  }
}
