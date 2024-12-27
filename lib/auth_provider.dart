
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';


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

  Future<String?> reportGameScore(String gameName, int score) async {
    var driveApi = drive.DriveApi(httpClient);
    String? fileId;
    String fileName = 'scores';

    try {
      // Search for the file by name and ensure it's a spreadsheet
      String queryString = "name = '$fileName' and mimeType = 'application/vnd.google-apps.spreadsheet'";
      var fileList = await driveApi.files.list(q: queryString);

      // Check if the file exists
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          print('Found file: ${file.name} with ID: ${file.id}');
          fileId = file.id;
          // insert values into the sheet
          var sheetApi = sheets.SheetsApi(httpClient);
          var values = [
            [DateTime.now().toIso8601String(), gameName, score],
          ];
          var valueRange = sheets.ValueRange()..values = values;
          await sheetApi.spreadsheets.values.append(
            valueRange,
            fileId!,
            'Sheet1!A1:C1',
            valueInputOption: 'RAW',
          );
          break; // Exit after finding the first match
        }
      } else {
        try {
          print('No spreadsheet named "$fileName" found. Will create a new one.');
          var newFile = await driveApi.files.create(
            drive.File()
              ..name = fileName
              ..mimeType = 'application/vnd.google-apps.spreadsheet',
          );
          fileId = newFile.id;
          // add column title to the new sheet
          var sheetApi = sheets.SheetsApi(httpClient);
          var values = [
            ['Date', 'Game', 'Score'],
            [DateTime.now().toIso8601String(), gameName, score],
          ];
          var valueRange = sheets.ValueRange()..values = values;
          await sheetApi.spreadsheets.values.update(
            valueRange,
            fileId!,
            'Sheet1!A1:C2',
            valueInputOption: 'RAW',
          );
        } catch (e) {
          print('Error creating Google Sheet with name $fileName: $e');
        }
      }
    } catch (e) {
      print('Error searching Google Drive: $e');
    }

    return fileId;
  }

  Future<List<List<dynamic>>> readGameScore(String gameName) async {
    var driveApi = drive.DriveApi(httpClient);
    String? fileId;
    String fileName = 'scores';

    // return a data table
    List<List<dynamic>> table = [];

    try {
      // Search for the file by name and ensure it's a spreadsheet
      String queryString = "name = '$fileName' and mimeType = 'application/vnd.google-apps.spreadsheet'";
      var fileList = await driveApi.files.list(q: queryString);

      // Check if the file exists
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var file in fileList.files!) {
          print('Found file: ${file.name} with ID: ${file.id}');
          fileId = file.id;
          // read data frame from google sheet
          var sheetApi = sheets.SheetsApi(httpClient);
          // column title ['Date', 'Game', 'Score'],
          var range = 'Sheet1!A1:C';
          var response = await sheetApi.spreadsheets.values.get(fileId!, range);
          var values = response.values;
          if (values != null) {
            for (var row in values) {
              if (row[1] == gameName) {

                print("${row[0]} ${row[1]} ${row[2]} points");
                // insert the row into the table
                table.add(row);
              }
            }
          } else {
            print('No data found in Google Sheet');
          }
          break; // Exit after finding the first match
        }
      } else {
        print('No spreadsheet named "$fileName" found.');
      }
    } catch (e) {
      print('Error searching Google Drive: $e');
    }
    return table;
  }

  Future<String?> findGoogleSheetByName(String fileName) async {
    var driveApi = drive.DriveApi(httpClient);
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