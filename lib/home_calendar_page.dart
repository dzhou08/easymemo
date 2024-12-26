import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


import 'auth_provider.dart';
import 'home_date_display.dart';
import 'util.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {

  bool _isExpandedVisible = false; // This controls the visibility
  String? _googleAccessToken;

  List<dynamic> _events = [];
  // Track the checked state for each item
  List<bool> _checked = [];

  // get today's date string of format 2024-12-15
  String todayDateString = "";

  GoogleSignInAccount? _user;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    _googleAccessToken = authProvider.getAccessToken();
    _user = authProvider.getGoogleUser();
    // get today's date string of format 2024-12-15
    todayDateString = getTodayDate();
  }

  String getTodayDate() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0'); // Ensure 2 digits
    final day = now.day.toString().padLeft(2, '0');     // Ensure 2 digits
    return '$year-$month-$day';
  }

  // Function to get Google Calendar events
  Future<void> _getCalendarEvents(String? accessToken) async {
    if (_events.isNotEmpty) {
      return;
    }

    String googleQueryString = 'https://www.googleapis.com/calendar/v3/calendars/primary/events?timeMin=${todayDateString}T00:00:00Z&timeMax=${todayDateString}T23:59:59Z';
    print(googleQueryString);

    // Make the authorized API request to Google Calendar
    var response = await http.get(
      Uri.parse(googleQueryString),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _events = data['items']; // Save events data
        // Initialize all items as unchecked
        _checked = List<bool>.filled(_events.length, false);
        print(data['items']);
      });
    } else {
      print('Failed to load calendar events ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);

    var colorScheme = Theme.of(context).colorScheme;
    DateFormat format = DateFormat('HH:mm:ss');
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

    return Scaffold(
      appBar: AppBar(
      title: const Text('EasyMemo'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const DateDisplay(),
          const SizedBox(height: 10),
          const VerticalDivider(
              color: Colors.black,
              thickness: 4,
            ),
          // Button or Toggle to Show/Hide the Expanded Widget
          ElevatedButton(
            onPressed: () {
              setState(() {
                _getCalendarEvents(_googleAccessToken);
                _isExpandedVisible =!_isExpandedVisible; // Toggle visibility
              });
            },
            child: Text(_isExpandedVisible ? "Hide Today's Schedule" : "Show Today's Schedule"),
          ),

          // Visibility widget to control showing/hiding the Expanded widget
          Visibility(
            visible: _isExpandedVisible,
            child: Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_events.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0), // Reduced padding
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Start and End Time in a single line
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_events[index]['start'] == null || _events[index]['end'] == null)
                                    ? "all day"
                                    : '${DateFormat('HH:mm').format(DateTime.parse(_events[index]['start']['dateTime'] ?? todayDateString).toLocal())} - '
                                      '${DateFormat('HH:mm').format(DateTime.parse(_events[index]['end']['dateTime'] ?? todayDateString).toLocal())}',
                                style: const TextStyle(fontSize: 12), // Smaller font size for compactness
                              ),
                            ],
                          ),
                          const SizedBox(width: 8), // Small space between time and summary
                          // Summary and Description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _events[index]['summary']??"summary",
                                  style: const TextStyle(
                                    fontSize: 14, // Smaller font size for a more compact look
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _events[index]['description']??"",//.replaceAll(exp, ''),
                                  style: const TextStyle(
                                    fontSize: 12, // Smaller font size for a more compact look
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: _checked[index],
                            onChanged: (bool? value) {
                              setState(() {
                                _checked[index] = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  })
                ),
              ),
            ),
          ),
        ], 
      ),   
    );
  }
}