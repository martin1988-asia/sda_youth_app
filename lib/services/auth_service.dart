// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Identity Architecture — World-Class Auth Orchestrator for SDA Youth.
abstract class AuthService {
  Future<void> setSessionPersistence(bool rememberMe);
  Future<UserCredential> authenticateEmail({required String email, required String password});
  Future<UserCredential?> authenticateGoogle();
  Future<void> transmitPasswordReset(String email);
  Future<void> terminateSession();
  Future<void> terminateIdentity();
  User? get currentIdentity;
  Stream<User?> get identityStateChanges;
}

class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth;
  late final GoogleSignIn _googleSignIn;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance {
    // FIXED: Web requires a ClientId. If you haven't set one up yet, 
    // we initialize it safely to prevent the startup crash.
    _googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? "YOUR_CLIENT_ID_HERE.apps.googleusercontent.com" : null,
    );
  }

  @override
  User? get currentIdentity => _auth.currentUser;

  @override
  Stream<User?> get identityStateChanges => _auth.authStateChanges();

  @override
  Future<void> setSessionPersistence(bool rememberMe) async {
    await _auth.setPersistence(
      rememberMe ? Persistence.LOCAL : Persistence.SESSION,
    );
  }

  @override
  Future<UserCredential> authenticateEmail({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<UserCredential?> authenticateGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> transmitPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> terminateSession() async {
    if (!kIsWeb) await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> terminateIdentity() async {
    final user = _auth.currentUser;
    if (user != null) await user.delete();
  }
}
