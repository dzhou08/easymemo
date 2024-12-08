import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';


class EnvConfig {

  static String getEnvVariable(String name) {

    if (!kReleaseMode) {
      return dotenv.env[name].toString();
    }
    else {
      // Release mode: Explicitly check for known environment variables
      switch (name) {
        case 'FIREBASE_API_KEY_WEB':
          return const String.fromEnvironment('FIREBASE_API_KEY_WEB', defaultValue: '');
        case 'FIREBASE_API_KEY_ANDROID':
          return const String.fromEnvironment('FIREBASE_API_KEY_ANDROID', defaultValue: '');
        case 'FIREBASE_API_KEY_IOS':
          return const String.fromEnvironment('FIREBASE_API_KEY_IOS', defaultValue: '');
        case 'FIREBASE_API_KEY_MACOS':
          return const String.fromEnvironment('FIREBASE_API_KEY_MACOS', defaultValue: '');
        case 'FIREBASE_API_KEY_WINDOWS':
          return const String.fromEnvironment('FIREBASE_API_KEY_WINDOWS', defaultValue: '');

        case 'FIREBASE_APP_ID_WEB':
          return const String.fromEnvironment('FIREBASE_APP_ID_WEB', defaultValue: '');
        case 'FIREBASE_APP_ID_ANDROID':
          return const String.fromEnvironment('FIREBASE_APP_ID_ANDROID', defaultValue: '');
        case 'FIREBASE_APP_ID_IOS':
          return const String.fromEnvironment('FIREBASE_APP_ID_IOS', defaultValue: '');
        case 'FIREBASE_APP_ID_MACOS':
          return const String.fromEnvironment('FIREBASE_APP_ID_MACOS', defaultValue: '');
        case 'FIREBASE_APP_ID_WINDOWS':
          return const String.fromEnvironment('FIREBASE_APP_ID_WINDOWS', defaultValue: '');
        
        case 'FIREBASE_MESSAGE_SENDER_ID':
          return const String.fromEnvironment('FIREBASE_MESSAGE_SENDER_ID', defaultValue: '');
        case 'FIREBASE_PROJECT_ID':
          return const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
        case 'FIREBASE_MEASUREMENT_ID':
          return const String.fromEnvironment('FIREBASE_MEASUREMENT_ID', defaultValue: '');
        case 'FIREBASE_IOS_CLIENT_ID':
          return const String.fromEnvironment('FIREBASE_IOS_CLIENT_ID', defaultValue: '');
        case 'FIREBASE_IOS_BUNDLE_ID':
          return const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID', defaultValue: '');

        case 'OPENAI_API_KEY':
          return const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

        default:
          return ''; // Handle unknown variables gracefully
      }
    }
  }

  static String get firebaseApiKeyWeb => getEnvVariable('FIREBASE_API_KEY_WEB');
  static String get firebaseApiKeyAndroid => getEnvVariable('FIREBASE_API_KEY_ANDROID');
  static String get firebaseApiKeyIos => getEnvVariable('FIREBASE_API_KEY_IOS');
  static String get firebaseApiKeyMacOS => getEnvVariable('FIREBASE_API_KEY_MACOS');
  static String get firebaseApiKeyWindows => getEnvVariable('FIREBASE_API_KEY_WINDOWS');

  static String get firebaseAppIdWeb => getEnvVariable('FIREBASE_APP_ID_WEB');
  static String get firebaseAppIdAndroid => getEnvVariable('FIREBASE_APP_ID_ANDROID');
  static String get firebaseAppIdIos => getEnvVariable('FIREBASE_APP_ID_IOS');
  static String get firebaseAppIdMacOS => getEnvVariable('FIREBASE_APP_ID_MACOS');
  static String get firebaseAppIdWindows => getEnvVariable('FIREBASE_APP_ID_WINDOWS');

  static String get firebaseMessagingSenderId => getEnvVariable('FIREBASE_MESSAGE_SENDER_ID');
  static String get firebaseProjectId => getEnvVariable('FIREBASE_PROJECT_ID');
  static String get firebaseAuthDomain => '${getEnvVariable('FIREBASE_PROJECT_ID')}.firebaseapp.com';
  static String get firebaseStorageBucket => '${getEnvVariable('FIREBASE_PROJECT_ID')}.appspot.com';
  static String get firebaseMeasurementId => getEnvVariable('FIREBASE_MEASUREMENT_ID');  

  static String get firebaseIosClientId => getEnvVariable('FIREBASE_IOS_CLIENT_ID');  
  static String get firebaseIosBundleId => getEnvVariable('FIREBASE_IOS_BUNDLE_ID');  

  static String get openAIApiKey => getEnvVariable('OPENAI_API_KEY');
}
