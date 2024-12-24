
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis/drive/v3.dart';


class GAuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets.readonly',
      'https://www.googleapis.com/auth/calendar.readonly',
      //'https://www.googleapis.com/auth/drive.readonly',
      'https://www.googleapis.com/auth/drive',
      'https://www.googleapis.com/auth/drive.appdata',
      'https://www.googleapis.com/auth/drive.appfolder',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.resource',
      'email',
    ],
  );

  GoogleSignInAccount? _user;
  GoogleSignInAuthentication? _googleAuth;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Client httpClient;

  // Sign in with Google and obtain access token
  Future<void> signInWithGoogle() async {
    try {
      print("sign in");
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        _googleAuth = await account.authentication;

        httpClient = (await _googleSignIn.authenticatedClient())!;

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

  Future<void> signOut() async {
    print("sign out");
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
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

  Client getAuthClient() {
    return httpClient;
  }

  Future<String?> findGoogleSheetByName(String fileName) async {
    var driveApi = DriveApi(httpClient);
    String? fileId;

    try {
      // Search for the file by name and ensure it's a spreadsheet
      String queryString = "name = '$fileName' and mimeType = 'application/vnd.google-apps.spreadsheet'";
      var fileList = await driveApi.files.list(q: queryString);

      // Check if the file exists
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          print('Found file: ${file.name} with ID: ${file.id}');
          fileId = file.id;
          break; // Exit after finding the first match
        }
      } else {
        print('No spreadsheet named "$fileName" found.');
      }
    } catch (e) {
      print('Error searching Google Drive: $e');
    }
    return fileId;
  }

}