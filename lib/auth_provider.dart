import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GAuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets.readonly',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/drive.readonly',
      'email',
    ],
  );

  GoogleSignInAccount? _user;
  GoogleSignInAuthentication? _googleAuth;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with Google and obtain access token
  Future<void> signInWithGoogle() async {
    try {
      print("sign in");
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        _googleAuth = await account.authentication;
        _user = account;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: _googleAuth!.accessToken,
          idToken: _googleAuth!.idToken,
        );

        await _auth.signInWithCredential(credential);
        notifyListeners();  // Notify listeners to update UI

      } else {
        print('Google Sign-In was cancelled.');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  String? getAccessToken() {
    return _googleAuth?.accessToken;
  }

  GoogleSignInAccount? getGoogleUser() {
    return _user;
  }

  bool isSignedIn() {
    return _user != null;
  }
}
