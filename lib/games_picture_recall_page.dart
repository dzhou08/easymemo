import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'dart:math';
import 'dart:typed_data';
import 'util.dart';


class PictureRecallPage extends StatefulWidget {
  const PictureRecallPage({Key? key}) : super(key: key);

  @override
  State<PictureRecallPage> createState() => PictureRecallPageState();
}

class PictureRecallPageState extends State<PictureRecallPage> {
  final _key = GlobalKey();
  bool _isLoading = true;
  List<dynamic> pictureValues = []; // To store the fetched Google Sheet data
  String pictureUrl = ""; // the picture URL
  String pictureDescription = ""; // the description of the picture

    @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final authProvider = Provider.of<GAuthProvider>(context, listen: false);
    final token = authProvider.getAccessToken();

    if (token != null) {
      setState(() {
        _isLoading = true;
      });
      final jsonValues = await authProvider.getGoogleSheetContent(token, "memory_pictures", 'Sheet1!A2:B');
      setState(() {
        _isLoading = false;
        pictureValues = jsonValues;
      });
      randomizePicture();
    }
  }

  void randomizePicture() {
    setState(() {
        _isLoading = false;
        final randomIndex = Random().nextInt(pictureValues.length);
        pictureUrl = pictureValues[randomIndex][0];
        pictureDescription = pictureValues[randomIndex][1];
      });
  }

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<GAuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Picture Recall Game'),
        actions: [
          ProfilePopupMenu(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Remember this moment? \nTry to recall it first, and then click to flip it!', 
              style: TextStyle(fontSize: 20, 
              fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,),
            const SizedBox(height: 20), // Adjust the height as needed
            FlipCard(
              direction: FlipDirection.HORIZONTAL, // Can be FlipDirection.VERTICAL
              front: Card(
                elevation: 4.0,
                child: Container(
                  width: 300,
                  height: 400,
                  child: FutureBuilder<Uint8List?>(
                    future: authProvider.getGoogleImageFileContent(pictureUrl), // Load the image asynchronously
                    builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Show a loading indicator while waiting for the image
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        // Show an error icon if there was an error fetching the image
                        return const Center(child: Icon(Icons.error));
                      } else if (snapshot.hasData) {
                        // Display the image when data is available
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                            return const Center(child: Icon(Icons.error)); // Handle image rendering errors
                          },
                        );
                      } else {
                        // Fallback for unexpected cases
                        return const Center(child: Icon(Icons.person)); // Placeholder for no data
                      }
                    },
                  ),
                ),
              ),
              back: Card(
                elevation: 4.0,
                child: Container(
                  width: 300,
                  height: 400,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    pictureDescription,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10), // Adjust the height as needed
            ElevatedButton(
              onPressed: () {
                randomizePicture(); // Call the method to fetch new questions
              },
              child: Text('New Picture'),
            ),
          ]
        )
      ),
    );
  }
}