import 'package:flutter/material.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:device_info_plus/device_info_plus.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'util.dart';

import 'package:http/http.dart' as http;
// For platform checks
import 'dart:convert';  // Import for JSON parsing
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';


class PhonePage extends StatefulWidget {
  const PhonePage({Key? key}) : super(key: key);

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final _key = GlobalKey();
  bool _isLoading = true;
  String? _googleSheetData;
  String? token;
  List<dynamic> values = []; // To store the fetched Google Sheet data

  final bool _isImageFailed = false;

  // Dial the phone number
  void _dialPhoneNumber(String phoneNumber) async {
    
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  // Read Google Sheet data
  Future<void> _readGoogleSheet(String accessToken) async {
    if (values.isNotEmpty) {
      return;
    }

    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    String? spreadsheetId = await authProvider.findGoogleSheetByName("contacts");//'1BDvsJVw3bffGMuRsKDyJHACDIBT9HOgcUDNdBqu_RXs';
    if (spreadsheetId == null)
    {
      print('Google Sheet not found');
      return;
    }

    // found the spreadsheet, now get the data
    String range = 'Sheet1!A1:D7';

    final response = await http.get(
      Uri.parse(
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        _googleSheetData = response.body;
        _isLoading = false;
      });
      // Parse the JSON string
      Map<String, dynamic> jsonData = jsonDecode(response.body);

      // Access the "values" key, which is a list of lists
      List<dynamic> jsonValues = jsonData['values'];

      // Set state to store the fetched data and stop the loading indicator
      setState(() {
        values = jsonValues.sublist(1); // Skip the header row
        _isLoading = false;
      });

    } else {
      print('Error fetching Google Sheets: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    token = authProvider.getAccessToken();
  }

  String extractFileId(String url) {
    List<String> parts = url.split('/');
    int index = parts.indexOf('d');
    if (index != -1 && index + 1 < parts.length) {
      return parts[index + 1];  // The file ID is the element after 'd'
    }
    throw Exception('Invalid Google Drive URL');
  }

  Future<Uint8List?> _loadNetworkImage(url) async {
    Uint8List? _imageData;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _imageData = response.bodyBytes; // This is the Uint8List data
      } else {
        debugPrint('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return _imageData;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<GAuthProvider>(context);
    final token = authProvider.getAccessToken();

    if (token != null) {
      _readGoogleSheet(token);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyMemo'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          // Handle scrolling behavior
          return false;
        },
        child: ListView.separated(
          itemCount: values.length,  // Number of items in the list
          separatorBuilder: (context, index) => const Divider(
            color: Colors.blueGrey,        // Color of the divider
            thickness: 2,              // Thickness of the line
            indent: 20,                // Left padding (indent)
            endIndent: 20,             // Right padding (indent)
          ),
          itemBuilder: (context, index) {
            // Get the data from the values list
            String name = values[index][0];        // Access the first column (Name)
            String relationship = values[index][1];    // Access the second column (Relationship)
            String avatarLink = values[index][2];  // Access the forth column (Avatar Link)
            print(avatarLink);
            // "https://drive.google.com/uc?export=view&id=$fileId";
            //avatarLink = "https://www.w3schools.com/w3images/lights.jpg";

            return AbsorbPointer(
              absorbing: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,  // Ensures the entire area responds to taps
                onTap: () {
                  print("tapped");
                  _dialPhoneNumber('17342395118'); // Replace with actual phone number
                },
                child: Material(
                  type: MaterialType.transparency,  // Ensure transparency
                  child: SizedBox(
                    width: double.infinity,  // Set width to full to fit list item
                    height: 100,  // You can adjust height based on your needs
                    child: Row(  // Adjust to Row to make avatar and details align horizontally
                      children: [
                        CircularProfileAvatar(
                          '',
                          radius: 50,  // Adjust radius for avatar size
                          backgroundColor: Colors.transparent,
                          borderWidth: 5,
                          elevation: 5.0,
                          cacheImage: false,
                          showInitialTextAbovePicture: false,
                          child: FutureBuilder<Uint8List?>(
                            future: _loadNetworkImage(avatarLink), // Load the image asynchronously
                            builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                // Show a loading indicator while waiting for the image
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                // Show an error icon if there was an error fetching the image
                                return const Icon(Icons.error);
                              } else if (snapshot.hasData) {
                                // Display the image when data is available
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                                    return const Icon(Icons.error); // Handle image rendering errors
                                  },
                                );
                              } else {
                                // Fallback for unexpected cases
                                return const Icon(Icons.person); // Placeholder for no data
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 20),  // Add spacing between avatar and details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(relationship, style: const TextStyle(fontSize: 16,)),
                              ElevatedButton(
                                  onPressed: () {
                                    print('Button Pressed');
                                    _dialPhoneNumber('17342395118'); // Replace with actual phone number
                                  },
                                  child: const Text('Call'),
                              ),
                            ]
                          ),
                        ),
                      ],
                      
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      )
    );
  }
}