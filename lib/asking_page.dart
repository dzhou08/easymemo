
import 'package:flutter/material.dart';

import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Import for JSON parsing

// Ensure this import is present
// For handling file content
// For making API requests
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;

//import 'home_speaker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';



class AskingPage extends StatefulWidget {
  const AskingPage({Key? key}) : super(key: key);

  @override
  State<AskingPage> createState() => _AskingPageState();
}

class _AskingPageState extends State<AskingPage> {
  /// Needed so that [MyAppState] can tell [AnimatedList] below to animate
  /// new items.
  final _key = GlobalKey();
  
  List<Map<String, String>> messages = [];
  String? _fileContent;
  bool _isLoading = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _voiceInput = '';
  
  // Controller to manage the TextField
  final TextEditingController _controller = TextEditingController();

  // LabelText that will be updated
  String inputLabelText = "Enter your prompt";

  File? _image;

  // Function to pick an image
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<GAuthProvider>(context);
    final token = authProvider.getAccessToken();

    if (token != null) {
      _searchFilesByName(token, 'memo.txt');
    }
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }


  @override
  void dispose() {
    // Cancel any async operations if needed
    super.dispose();
  }
  
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _voiceInput = val.recognizedWords;
          _controller.text = _voiceInput;  // Populate the text field with voice input
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }


  ///
  /// get Google file content by id
  ///

  Future<String?> getFileContent(String fileId, String accessToken) async {
    final url = 'https://www.googleapis.com/drive/v3/files/$fileId?alt=media';
    print(url);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization':  'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        // Successfully retrieved the file content
        return response.body; // This will return the content of the file
      } else {
        print('Failed to retrieve file content. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error fetching file content: $error');
      return null;
    }
  }

  // Function to search files by name
  Future<String?> _searchFilesByName(String accessToken, String fileName) async {

    // Google Drive API search query to search for a file by name
    final query = "name contains '$fileName'";
    try
    {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files?q=$query&fields=files(id, name, mimeType)'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        //final Map<String, dynamic> data = jsonDecode(response.body);
        // Parse the JSON string
        /*
        "files": [
            {
              "mimeType": "text/plain",
              "id": "15bbpwJfWt6ezuxOqXP2TsW9xnuMSm9A3",
              "name": "memo.txt"
            }
          ]
        */
        Map<String, dynamic> jsonData = jsonDecode(response.body);

        // Access the "values" key, which is a list of lists
        List<dynamic> jsonValues = jsonData['files'];
        // only need the first element and get the id value
        final String fileId = jsonValues[0]['id'];
        final content = await getFileContent(fileId, accessToken);
        if (content != null) {
          print('File Content: $content');
        } else {
          print('Failed to fetch file content');
        }

        if (mounted) {
          setState(() {
            _fileContent = content;
            _isLoading = false;
          });
        }
        return content;
      }
    }
    catch (error) {
      // Stop further execution if an error occurs
      print("Error caught: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return null;
    }
    return null;
  }


  Future<void> sendToGPT(String message) async {
    if (!mounted) return; // Check if mounted before setting state
    setState(() {
      _isLoading = true;
      messages.add({'user': message});
    });

    final openAI = OpenAI.instance.build(
      token: dotenv.env['OPENAI_API_KEY'].toString(),
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true
    );
    
    final request_2 = ChatCompleteText(
      messages: [
        Map.of({"role": "system", "content": "You are a helpful assistant that responds in image analysis."}),
        Map.of({"role": "user", "content": [
              {"type": "text", "text": "Help me answer the following message question based on fileContent value."},
              {
                "type": "text", 
                "text": _fileContent
              },
              {
                "type": "text", 
                "text": message
              },
          ]})
      ], 
      maxToken: 200, 
      model: Gpt4OChatModel(),
      temperature: 0.0,
    );

    final response = await openAI.onChatCompletion(request: request_2);
    // Get the text response from GPT
    String answer = response?.choices[0].message?.content.trim() ?? 'No response';

    if (mounted) {
      setState(() {

        messages.add({'assistant': answer});
        inputLabelText='Enter your message';
        _isLoading = false;
      });
    }
  }

  // Function to clear the messages list
  void _clearMessages() {
    setState(() {
      messages.clear();
    });
  }

  // Function to remove the image
  void _removeImage() {
    setState(() {
      _image = null; // Reset the image to null
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyMemo'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                print(message);
                // Display either user or assistant message
                return ListTile(
                  title: Row(
                    children: [
                      if (message.containsKey('user')) 
                        const Icon(Icons.person),  // Replace "Assistant:" with an icon
                      
                      if (message.containsKey('assistant')) 
                        const Icon(Icons.smart_toy),
                      const SizedBox(width: 8), // Add some spacing between the icon and the text
                      
                      Expanded(
                        child: Text(
                          message.containsKey('user')
                              ? message['user'] ?? ''  // Handle null user messages
                              : message['assistant'] ?? '',       // Handle null assistant messages
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          /*if (_fileContent != null) Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('File Content: $_fileContent'),
          ),*/
          // Clear Messages Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _clearMessages,  // Call the clear function
              child: const Text('Clear Messages'),
            ),
          ),
          // Display selected image with a delete button (if any)
          if (_image != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  // Image display
                  Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border.all(),
                    ),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
                  // Delete button
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: _removeImage, // Call the function to remove the image
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,  // Attach the controller to the TextField
              decoration: InputDecoration(
                labelText: "Enter your message here",
                border: const OutlineInputBorder(),
                suffixIcon: Row( 
                  mainAxisSize: MainAxisSize.min, // Adjusts the Row's width
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt),
                      onPressed: _pickImage, // Trigger image picker
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),  // Microphone icon
                      onPressed: _isListening ? _stopListening : _startListening,  // Toggle listening
                    ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  sendToGPT(value);
                  _controller.clear();
                }
              },
            ),
          ),
          /*
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: pickFile,
              child: const Text('Upload File'),
            ),
          ),*/
          if (_isLoading) const CircularProgressIndicator(),

          //const Speaker(),
          //const SizedBox(height: 10),
        ],
      ),
    );
  }
}