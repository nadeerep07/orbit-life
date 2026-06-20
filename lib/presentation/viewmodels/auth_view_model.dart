import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthViewModel extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '147298740710-7v4al3sdq8jvlotk473teqbt15vt9tsf.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Error signing in: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
