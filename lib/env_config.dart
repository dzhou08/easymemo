import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get firebaseApiKeyWeb => dotenv.env['FIREBASE_API_KEY_WEB'].toString();
  static String get firebaseApiKeyAndroid => dotenv.env['FIREBASE_API_KEY_ANDROID'].toString();
  static String get firebaseApiKeyIos => dotenv.env['FIREBASE_API_KEY_IOS'].toString();
  static String get firebaseApiKeyMacOS => dotenv.env['FIREBASE_API_KEY_MACOS'].toString();
  static String get firebaseApiKeyWindows => dotenv.env['FIREBASE_API_KEY_WINDOWS'].toString();

  static String get firebaseAppIdWeb => dotenv.env['FIREBASE_API_KEY_WEB'].toString();
  static String get firebaseAppIdAndroid => dotenv.env['FIREBASE_API_KEY_ANDROID'].toString();
  static String get firebaseAppIdIos => dotenv.env['FIREBASE_API_KEY_IOS'].toString();
  static String get firebaseAppIdMacOS => dotenv.env['FIREBASE_API_KEY_MACOS'].toString();
  static String get firebaseAppIdWindows => dotenv.env['FIREBASE_API_KEY_WINDOWS'].toString();

  static String get firebaseMessagingSenderId => dotenv.env['FIREBASE_MESSAGE_SENDER_ID'].toString();
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'].toString();
  static String get firebaseAuthDomain => '${dotenv.env['FIREBASE_PROJECT_ID']}.firebaseapp.com';
  static String get firebaseStorageBucket => '${dotenv.env['FIREBASE_PROJECT_ID']}.appspot.com';
  static String get firebaseMeasurementId => dotenv.env['FIREBASE_MEASUREMENT_ID'].toString();  

  static String get firebaseIosClientId => dotenv.env['FIREBASE_IOS_CLIENT_ID'].toString();  
  static String get firebaseIosBundleId => dotenv.env['FIREBASE_IOS_BUNDLE_ID'].toString();  

  static String get openAIApiKey => dotenv.env['OPENAI_API_KEY'].toString();
}
