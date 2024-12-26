import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'package:provider/provider.dart';

class ProfilePopupMenu extends StatelessWidget {
  late GoogleSignInAccount user;
  final GlobalKey _key = GlobalKey();
  late GAuthProvider authProvider;
  late VoidCallback onSignOut;

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
    final user = authProvider.getGoogleUser();
    if (user == null) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        _showPopupMenu(context, authProvider.signOut);
      },
      child: Container(
        key: _key,
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          child: ClipOval(
            child: FutureBuilder<Uint8List?>(
              future: _loadNetworkImage(user.photoUrl!), // Load the image asynchronously
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
        ),
      ),
    );
  }

  void _showPopupMenu(BuildContext context, VoidCallback signOut) {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx, // Horizontal position
        offset.dy + renderBox.size.height, // Vertical position just below the avatar
        0,
        0,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'Profile',
          child: Text('Profile'),
        ),
        const PopupMenuItem<String>(
          value: 'Logout',
          child: Text('Logout'),
        ),
      ],
    ).then((value) {
      if (value == 'Logout') {
        signOut();
      }
    });
  }
}