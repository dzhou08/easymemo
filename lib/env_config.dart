import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';


class EnvConfig {

  static String getEnvVariable(String name) {

    if (!kReleaseMode) {
      return dotenv.env[name].toString();
    }
    else {
      return String.fromEnvironment(name, defaultValue: '');
    }
  }

  static String get firebaseApiKeyWeb => getEnvVariable('FIREBASE_API_KEY_WEB');
  static String get firebaseApiKeyAndroid => getEnvVariable('FIREBASE_API_KEY_ANDROID');
  static String get firebaseApiKeyIos => getEnvVariable('FIREBASE_API_KEY_IOS');
  static String get firebaseApiKeyMacOS => getEnvVariable('FIREBASE_API_KEY_MACOS');
  static String get firebaseApiKeyWindows => getEnvVariable('FIREBASE_API_KEY_WINDOWS');

  static String get firebaseAppIdWeb => getEnvVariable('FIREBASE_API_KEY_WEB');
  static String get firebaseAppIdAndroid => getEnvVariable('FIREBASE_API_KEY_ANDROID');
  static String get firebaseAppIdIos => getEnvVariable('FIREBASE_API_KEY_IOS');
  static String get firebaseAppIdMacOS => getEnvVariable('FIREBASE_API_KEY_MACOS');
  static String get firebaseAppIdWindows => getEnvVariable('FIREBASE_API_KEY_WINDOWS');

  static String get firebaseMessagingSenderId => getEnvVariable('FIREBASE_MESSAGE_SENDER_ID');
  static String get firebaseProjectId => getEnvVariable('FIREBASE_PROJECT_ID');
  static String get firebaseAuthDomain => '${getEnvVariable('FIREBASE_PROJECT_ID')}.firebaseapp.com';
  static String get firebaseStorageBucket => '${getEnvVariable('FIREBASE_PROJECT_ID')}.appspot.com';
  static String get firebaseMeasurementId => getEnvVariable('FIREBASE_MEASUREMENT_ID');  

  static String get firebaseIosClientId => getEnvVariable('FIREBASE_IOS_CLIENT_ID');  
  static String get firebaseIosBundleId => getEnvVariable('FIREBASE_IOS_BUNDLE_ID');  

  static String get openAIApiKey => getEnvVariable('OPENAI_API_KEY');
}
