import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  factory AppUser.fromGoogleUser(GoogleSignInAccount googleUser) {
    return AppUser(
      id: googleUser.id,
      email: googleUser.email,
      displayName: googleUser.displayName,
      photoUrl: googleUser.photoUrl,
    );
  }
}

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '147298740710-7v4al3sdq8jvlotk473teqbt15vt9tsf.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthViewModel() {
    try {
      _auth.authStateChanges().listen(
        (user) {
          if (user != null) {
            _currentUser = AppUser.fromFirebaseUser(user);
            _syncUserProfileToFirestore(user);
          }
          if (hasListeners) notifyListeners();
        },
        onError: (e) {
          debugPrint("FirebaseAuth authStateChanges channel error: $e");
        },
      );
    } catch (e) {
      debugPrint("FirebaseAuth listener init error: $e");
    }
  }

  Future<void> _syncUserProfileToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error syncing user profile to Firestore: $e");
    }
  }

  Future<void> _syncGoogleUserToFirestore(GoogleSignInAccount googleUser) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(googleUser.id).set({
        'uid': googleUser.id,
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error syncing google user to Firestore: $e");
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    _isLoading = true;
    if (hasListeners) notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        if (hasListeners) notifyListeners();
        return null;
      }

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          _currentUser = AppUser.fromFirebaseUser(user);
          await _syncUserProfileToFirestore(user);
        } else {
          _currentUser = AppUser.fromGoogleUser(googleUser);
          await _syncGoogleUserToFirestore(googleUser);
        }
      } catch (e) {
        debugPrint("Firebase Auth channel fallback triggered: $e");
        _currentUser = AppUser.fromGoogleUser(googleUser);
        await _syncGoogleUserToFirestore(googleUser);
      }

      _isLoading = false;
      if (hasListeners) notifyListeners();
      return _currentUser;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      _isLoading = false;
      if (hasListeners) notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentUser = null;
    if (hasListeners) notifyListeners();
  }
}
