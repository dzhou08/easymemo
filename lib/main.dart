
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
//import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
//import 'home_task_checkbox_list.dart';
//import 'home_date_display.dart';
import 'home_calendar_page.dart';
import 'auth_provider.dart';

import 'my_app_state.dart';
import 'phone_page.dart';
import 'stepper_page.dart';
import 'asking_page.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
//import 'firebase_options.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'env_config.dart';

import 'package:flutter/foundation.dart';

Future main() async {
  // To load the .env file contents into dotenv.
  // NOTE: fileName defaults to .env and can be omitted in this case.
  // Ensure that the filename corresponds to the path in step 1 and 2.
  // Load .env only in development mode
  if (!kReleaseMode) {
    await dotenv.load(fileName: ".env");
  }
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      print(kIsWeb);
      await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: EnvConfig.firebaseApiKeyWeb,
            appId: EnvConfig.firebaseAppIdWeb,
            messagingSenderId: EnvConfig.firebaseMessagingSenderId,
            projectId: EnvConfig.firebaseProjectId,
            authDomain: EnvConfig.firebaseAuthDomain,
            storageBucket: EnvConfig.firebaseStorageBucket,
            measurementId: EnvConfig.firebaseMeasurementId,
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print('Firebase Initialized Successfully');
    
    //debugPaintPointersEnabled = true;  // Shows touch interactions on screen

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GAuthProvider()),  // Add AuthProvider
          ChangeNotifierProvider(create: (_) => MyAppState()),  // Add MyAppState
        ],
        child: MyApp(),
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = ThemeMode.light;
    bool useMaterial3 = false;

    return ChangeNotifierProvider(
      create: (context) => MyAppState(), 
      // we use `builder` to obtain a new `BuildContext` that has access to the provider
      builder: (context, child) {
      return MaterialApp(
          title: 'EasyMemo App',
          theme: ThemeData(
            // Define the color scheme for the app
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple, // The primary color
            ).copyWith(
              secondary: Colors.purpleAccent, // The secondary color (used instead of accentColor)
            ),

            // AppBar styling
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.purple, // App bar color using primary color
              foregroundColor: Colors.white,
              shadowColor: Colors.black,
              titleTextStyle: GoogleFonts.novaRound(
                  textStyle: TextStyle(
                    fontSize: 20,          // Set the font size
                    fontWeight: FontWeight.bold,  // Set the font weight
                    color: Colors.white,   // Set the font color
                  ),
                ),
              
            ),

            // Set FloatingActionButton background color using secondary color
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.purpleAccent, // Secondary color used for FAB
            ),

            // Define the default `TextTheme`. Use this to specify the default
            // text styling for headlines, titles, bodies of text, and more.
            textTheme: TextTheme(
              displayLarge: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
              // TRY THIS: Change one of the GoogleFonts
              //           to "lato", "poppins", or "lora".
              //           The title uses "titleLarge"
              //           and the middle text uses "bodyMedium".
              titleLarge: GoogleFonts.oswald(
                fontSize: 30,
                fontStyle: FontStyle.italic,
              ),
              bodyMedium: GoogleFonts.merriweather(
                fontSize: 18,
              ),
              displaySmall: GoogleFonts.pacifico(),
            ),
          ),
          home: MyHomePage(),
        );
      }
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final bool _initialized = true; // Firebase is already initialized in main()
  final bool _error = false;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context);
    var colorScheme = Theme.of(context).colorScheme;

    if (_error) {
      return Scaffold(
        body: Center(child: Text('Error initializing Firebase')),
      );
    }

    if (!_initialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = CalendarPage();
        break;
      case 1:
        page = StepperPage();
        break;
      case 2:
        page = PhonePage();
        break;
      case 3:
        page = AskingPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            return SafeArea(
              child: authProvider.getGoogleUser() == null
                  ? Center(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/EasyMemo_logo.png'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withOpacity(0.5),
                              BlendMode.dstATop,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 300),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Add padding for better spacing
                                alignment: Alignment.center, // Align content to the center
                              ),
                              onPressed: () {
                                authProvider.signInWithGoogle();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
                                mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
                                  
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/google.svg', // Path to your SVG asset
                                    width: 20.0, // Adjust the size as needed
                                    height: 20.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text('Sign in with Google'),
                                ],
                              ) 
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(child: mainArea),
                        SafeArea(
                          bottom: false,
                          child: BottomNavigationBar(
                            type: BottomNavigationBarType.fixed,
                            items: [
                              BottomNavigationBarItem(
                                icon: Icon(Icons.home),
                                label: 'Home',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.medical_information),
                                label: 'Mini-Cog™',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.phone),
                                label: 'Contacts',
                              ),
                              BottomNavigationBarItem(
                                icon: Icon(Icons.mic),
                                label: 'Ask Me!',
                              ),
                            ],
                            currentIndex: selectedIndex,
                            onTap: (value) {
                              setState(() {
                                selectedIndex = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            );
          } else {
            return 
              SafeArea(
                child: authProvider.getGoogleUser() == null
                    ? Center(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/EasyMemo_logo.png'),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.white.withOpacity(0.5),
                                BlendMode.dstATop,
                              ),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 200),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // Add padding for better spacing
                                  alignment: Alignment.center, // Align content to the center
                                ),
                                onPressed: () {
                                  authProvider.signInWithGoogle();
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min, // Makes the button width fit the content
                                  mainAxisAlignment: MainAxisAlignment.center, // Center-aligns the icon and text
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/google.svg', // Path to your SVG asset
                                      width: 20.0, // Adjust the size as needed
                                      height: 20.0,
                                    ),
                                    SizedBox(width: 8.0),
                                    Text('Sign in with Google'),
                                  ],
                                )
                              ),
                            ],
                          ),
                        ),
                      )
                      : 
                      Row(
                        children: [
                              NavigationRail(
                                extended: constraints.maxWidth >= 600,
                                destinations: [
                                  NavigationRailDestination(
                                    icon: Icon(Icons.home),
                                    label: Text('Home'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.medical_information),
                                    label: Text('Mini-Cog™'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.phone),
                                    label: Text('Contacts'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.mic),
                                    label: Text('Ask Me!'),
                                  ),
                                ],
                                selectedIndex: selectedIndex,
                                onDestinationSelected: (value) {
                                  setState(() {
                                    selectedIndex = value;
                                  });
                                },
                              ),
                          Expanded(child: mainArea),
                        ]
                      ),
            );
          }
        },
      ),
    );
  }
}

